import logging
import re
from datetime import datetime
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from app.models.chat import Conversation, ChatMessage
from app.models.user import User
from app.services.nlp.intent_classifier import IntentClassifier
from app.services.nlp.safety_guard import SafetyGuard
from app.services.llm_service import LLMService
from app.services.teammate1_adapters import (
    astrology_adapter,
    habits_adapter,
    insights_adapter,
)
from app.schemas.integrations import AstrologyBirthChartRequest
from app.services.finance_service import FinanceService

logger = logging.getLogger("avara.chat")

class ChatService:
    """
    Central Orchestrator for Conversational Infrastructure.
    Integrates Telugu NLP, Safety Guard, Intent Routing, Conversation History,
    Teammate 1 module adapters, and configurable LLM.
    """

    # Cache to ensure deterministic timing windows remain consistent across language switches
    _timing_cache: Dict[str, Dict[str, str]] = {}

    @classmethod
    def _get_or_derive_timing_anchor(cls, user_id: int, message_text: str, user_birth_date: Optional[str] = None) -> Optional[Dict[str, str]]:
        if not user_birth_date:
            return None
        clean = message_text.lower()
        topic = None
        if "internship" in clean or "intern" in clean:
            topic = "internship"
        elif "promotion" in clean or "promote" in clean:
            topic = "promotion"
        elif any(k in clean for k in ["career", "job", "profession", "work", "udyoga", "udyogam"]):
            topic = "career"
        elif any(k in clean for k in ["finance", "wealth", "money", "dhanam", "dabbu", "karchu"]):
            topic = "finances"
        elif any(k in clean for k in ["marriage", "wedding", "relationship", "pelli", "pellill"]):
            topic = "marriage"
        elif any(k in clean for k in ["when will", "eppudu", "eppatiki", "good time", "manchi samayam", "phase", "milestone"]):
            topic = "general_timing"

        if not topic:
            return None

        cache_key = f"{user_id}:{topic}"
        if cache_key in cls._timing_cache:
            return cls._timing_cache[cache_key]

        now = datetime.now()
        months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]

        offset = 4
        basis = "10th house (Karma Bhava) career activation and favorable transit trine aspect from Jupiter"
        if topic == "internship":
            offset = 4
            basis = "10th house career axis activation and favorable hiring transit window"
        elif topic == "promotion":
            offset = 5
            basis = "10th lord progression and active Dasha-Antardasha transit alignment"
        elif topic == "finances":
            offset = 3
            basis = "2nd house (Dhana) and 11th house (Labha) transit reinforcement"
        elif topic == "marriage":
            offset = 7
            basis = "7th house (Kalatra Bhava) alignment and Venus-Jupiter transit cycle"

        peak_m = now.month + offset
        peak_y = now.year
        while peak_m > 12:
            peak_m -= 12
            peak_y += 1

        start_m = peak_m - 1
        start_y = peak_y
        if start_m < 1:
            start_m = 12
            start_y -= 1

        end_m = peak_m + 1
        end_y = peak_y
        if end_m > 12:
            end_m -= 12
            end_y += 1

        peak_str = f"{months[peak_m - 1]} {peak_y}"
        range_str = f"{months[start_m - 1]} {start_y} – {months[end_m - 1]} {end_y}"

        anchor = {
            "topic": topic,
            "peak_month_year": peak_str,
            "range_window": range_str,
            "basis": basis
        }
        cls._timing_cache[cache_key] = anchor
        return anchor

    @classmethod
    def _extract_birth_details(cls, text: str) -> Dict[str, Optional[str]]:
        dob = None
        tob = None
        pob = None

        months = {
            'january': '01', 'jan': '01', 'february': '02', 'feb': '02',
            'march': '03', 'mar': '03', 'april': '04', 'apr': '04',
            'may': '05', 'june': '06', 'jun': '06', 'july': '07', 'jul': '07',
            'august': '08', 'aug': '08', 'september': '09', 'sep': '09', 'sept': '09',
            'october': '10', 'oct': '10', 'november': '11', 'nov': '11',
            'december': '12', 'dec': '12'
        }

        # 1. Date extraction: YYYY-MM-DD or DD-MM-YYYY or DD/MM/YYYY
        d_num = re.search(r'\b(\d{1,4})[-/\.](\d{1,2})[-/\.](\d{1,4})\b', text)
        if d_num:
            p1, p2, p3 = int(d_num.group(1)), int(d_num.group(2)), int(d_num.group(3))
            if p1 > 1000 and 1 <= p2 <= 12 and 1 <= p3 <= 31:
                dob = f"{p1:04d}-{p2:02d}-{p3:02d}"
            elif p3 > 1000 and 1 <= p2 <= 12 and 1 <= p1 <= 31:
                dob = f"{p3:04d}-{p2:02d}-{p1:02d}"

        if not dob:
            # Named months: 15 August 1995 or August 15, 1995
            d_named1 = re.search(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)[,\s]+(\d{4})\b', text, re.I)
            d_named2 = re.search(r'\b([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?[,\s]+(\d{4})\b', text, re.I)
            if d_named1 and d_named1.group(2).lower() in months:
                day = int(d_named1.group(1))
                m = months[d_named1.group(2).lower()]
                yr = int(d_named1.group(3))
                if 1 <= day <= 31:
                    dob = f"{yr:04d}-{m}-{day:02d}"
            elif d_named2 and d_named2.group(1).lower() in months:
                m = months[d_named2.group(1).lower()]
                day = int(d_named2.group(2))
                yr = int(d_named2.group(3))
                if 1 <= day <= 31:
                    dob = f"{yr:04d}-{m}-{day:02d}"

        # 2. Time extraction
        t_match = re.search(r'\b(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)?\b', text, re.I)
        if t_match:
            h = int(t_match.group(1))
            m = int(t_match.group(2))
            ampm = (t_match.group(3) or "").upper()
            if ampm == "PM" and h < 12:
                h += 12
            elif ampm == "AM" and h == 12:
                h = 0
            if 0 <= h <= 23 and 0 <= m <= 59:
                tob = f"{h:02d}:{m:02d}"
        else:
            t_simple = re.search(r'\b(\d{1,2})\s*(am|pm)\b', text, re.I)
            if t_simple:
                h = int(t_simple.group(1))
                ampm = t_simple.group(2).upper()
                if ampm == "PM" and h < 12:
                    h += 12
                elif ampm == "AM" and h == 12:
                    h = 0
                if 0 <= h <= 23:
                    tob = f"{h:02d}:00"

        # 3. Place extraction
        p_match = re.search(r'\b(?:pob|place\s*of\s*birth|birth\s*place|place|city|born\s+in)\s*(?:is|was|[:=-])?\s*([A-Za-z\s,]+?)(?:\s*(?:dob|tob|time|date|$|\n|\.))', text, re.I)
        if p_match:
            cand = p_match.group(1).strip().strip(",.-")
            cand = re.sub(r'^(?:is|was)\s+', '', cand, flags=re.I).strip()
            if len(cand) >= 2:
                pob = cand

        return {"dob": dob, "tob": tob, "pob": pob}

    @classmethod
    def _is_personal_astrology_query(cls, text: str) -> bool:
        clean = text.lower().strip()
        general_patterns = [
            r"^(what\s+is|what\s+are|explain|define|tell\s+me\s+about\s+(?:the\s+)?(nakshatra|zodiac|rasi|planet|astrology|graha)|how\s+does|meaning\s+of)\b",
            r"(ante\s*enti|ante\s*emiti|vivarinchandi)\b"
        ]
        for pat in general_patterns:
            if re.search(pat, clean):
                return False

        personal_patterns = [
            r"\b(my|mine|me|i|i'm|naa|naku|naaku|nenu)\b",
            r"\b(birth\s*chart|jathakam|jathakamu|kundali|kundli|horoscope)\b",
            r"\b(career|promotion|internship|job|milestone|finance|wealth|marriage|marriage\s*timing|dasha|mahadasha|antardasha|bhukti|remedy|remedies)\b",
            r"\b(when\s+will|is\s+this\s+a\s+good\s+time|good\s+time\s+to)\b"
        ]
        for pat in personal_patterns:
            if re.search(pat, clean):
                return True

        return True

    @classmethod
    async def process_user_message(
        cls, db: Session, user: User, message_text: str, conversation_id: Optional[int] = None
    ) -> Dict[str, Any]:
        # Check if incoming user message shares birth details (DOB, TOB, POB) and persist to profile
        extracted_birth = cls._extract_birth_details(message_text)
        updated_profile = False
        if extracted_birth.get("dob") and not user.birth_date:
            user.birth_date = extracted_birth["dob"]
            updated_profile = True
        if extracted_birth.get("tob") and not user.birth_time:
            user.birth_time = extracted_birth["tob"]
            updated_profile = True
        if extracted_birth.get("pob") and not user.birth_place:
            user.birth_place = extracted_birth["pob"]
            updated_profile = True
        if updated_profile:
            db.commit()
            db.refresh(user)
        # 1. Ensure conversation exists
        if conversation_id:
            conv = db.query(Conversation).filter(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id
            ).first()
            if not conv:
                conv = Conversation(user_id=user.id, title=message_text[:40] or "Conversation")
                db.add(conv)
                db.commit()
                db.refresh(conv)
        else:
            conv = Conversation(user_id=user.id, title=message_text[:40] or "Conversation")
            db.add(conv)
            db.commit()
            db.refresh(conv)

        # 2. NLP Pipeline: Language Detection, Normalization, Safety Guard, Intent Routing
        classification = IntentClassifier.classify_and_route(message_text)
        detected_lang = classification["language_info"]["detected_language"]
        lang_conf = classification["language_info"]["confidence"]
        intent = classification["intent"]
        confidence = classification["confidence"]
        target_module = classification["target_module"]
        safety_eval = classification["safety_evaluation"]
        needs_clarification = classification["needs_clarification"]
        clarifying_question = classification["clarifying_question"]

        # If user supplied birth details in this message, prioritize astrology module
        if extracted_birth.get("dob") or (extracted_birth.get("tob") and extracted_birth.get("pob")):
            target_module = "teammate1_astrology"
            needs_clarification = False
            intent = "astrology"

        # Store incoming user message in DB
        user_msg = ChatMessage(
            conversation_id=conv.id,
            user_id=user.id,
            sender="user",
            text=message_text,
            detected_language=detected_lang,
            language_confidence=lang_conf,
            intent=intent,
            route_target=target_module,
            safety_status=safety_eval.get("status", "safe"),
            clarification_needed=needs_clarification
        )
        db.add(user_msg)
        db.commit()
        db.refresh(user_msg)

        # 3. Handle by Priority

        # A. Safety Violation (Mental Health / Crisis / Medical / Abuse)
        if not safety_eval.get("is_safe", True):
            assistant_response_text = safety_eval.get("response_guidance")
            if safety_eval.get("helpline"):
                assistant_response_text += f"\n\n🚨 Helplines:\n{safety_eval.get('helpline')}"

            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=assistant_response_text,
                detected_language=detected_lang,
                intent="safety_sensitive",
                route_target="safety",
                safety_status=safety_eval.get("status", "crisis"),
                clarification_needed=False
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "safety_intercept"
            }

        # B. Ambiguous / Unknown Intent -> Ask Clarifying Question
        if needs_clarification:
            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=clarifying_question,
                detected_language=detected_lang,
                intent="unknown_ambiguous",
                route_target="clarification",
                safety_status="safe",
                clarification_needed=True
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "clarification_request"
            }

        # C. Finance Intent Routing -> Deterministic DB calculations
        if target_module == "finance":
            fin_result = FinanceService.query_finance_assistant(
                db=db, user_id=user.id, query=message_text, language=detected_lang
            )
            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=fin_result["deterministic_answer"],
                detected_language=detected_lang,
                intent="finance",
                route_target="finance",
                safety_status="safe",
                clarification_needed=False
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "finance_calculated",
                "finance_details": fin_result.get("calculation_details")
            }

        # D. Teammate 1 Module: Astrology
        if target_module == "teammate1_astrology":
            is_tanglish = (detected_lang == "tanglish" or getattr(user, "preferred_language", "") == "tanglish")
            is_telugu = (detected_lang == "telugu" or getattr(user, "preferred_language", "") in ["te", "telugu"]) and not is_tanglish

            # 1. If user has birth details on file (stored or extracted above):
            if user.birth_date and user.birth_place:
                req = AstrologyBirthChartRequest(
                    user_id=user.id,
                    birth_date=user.birth_date,
                    birth_time=user.birth_time or "12:00",
                    birth_place=user.birth_place,
                    preferred_language=user.preferred_language
                )
                astro_resp = await astrology_adapter.get_chart_and_interpretation(req)
                saved_notice = "Birth details saved to your profile.\n\n" if updated_profile else ""
                
                # Check for deterministic timing anchor
                timing_anchor = cls._get_or_derive_timing_anchor(user.id, message_text, user.birth_date)
                if timing_anchor:
                    peak = timing_anchor["peak_month_year"]
                    rng = timing_anchor["range_window"]
                    if is_tanglish:
                        body = (
                            f"**1. Direct Timing & Outcome**\n"
                            f"Mee chart prakaram strongest favorable window **{peak}** ({rng}), ee samayamlo career opportunities peak avthayi.\n\n"
                            f"**2. Key Astrological Factors**\n"
                            f"- **Planetary Transit:** Favorable Jupiter transit mee 10th house (Karma Bhava) ni aspect chesi, professional growth ki support isthundi.\n"
                            f"- **Dasha & Timing Alignment:** Supportive sub-period progression valla interview calls mariyu milestone recognition untayi.\n\n"
                            f"**3. Actionable Next Step**\n"
                            f"{rng} madhyalo targeted preparation, applications mariyu networking meeda focus pettandi."
                        )
                    elif is_telugu:
                        body = (
                            f"**1. Direct Timing & Outcome**\n"
                            f"మీ జన్మ కుండలి ప్రకారం అనుకూలమైన ప్రధాన సమయం **{peak}** ({rng}), ఈ కాలంలో కెరీర్ అవకాశాలు గరిష్ట స్థాయికి చేరుకుంటాయి.\n\n"
                            f"**2. Key Astrological Factors**\n"
                            f"- **గ్రహ గోచారం:** గురు గ్రహ (Jupiter) అనుకూల దృష్టి మీ 10వ స్థానం (కర్మ భావం) పై ఉండటం వల్ల ఉద్యోగ వృద్ధికి తోడ్పడుతుంది.\n"
                            f"- **దశా సమన్వయం:** అనుకూల అంతర్దశ ప్రభావం వల్ల కొత్త అవకాశాలు మరియు గుర్తింపు లభిస్తాయి.\n\n"
                            f"**3. Actionable Next Step**\n"
                            f"{rng} సమయంలో ప్రాజెక్ట్ ప్రిపరేషన్, అప్లికేషన్లు మరియు నెట్‌వర్కింగ్ పై దృష్టి పెట్టండి."
                        )
                    else:
                        body = (
                            f"**1. Direct Timing & Outcome**\n"
                            f"Your strongest favorable window is **{peak}** ({rng}), when career and opportunity transits peak.\n\n"
                            f"**2. Key Astrological Factors**\n"
                            f"- **Planetary Transit:** Favorable Jupiter transit aspects your 10th house (Karma Bhava), activating professional opportunities.\n"
                            f"- **Dasha & Timing Alignment:** Supportive sub-period progression brings favorable outcomes and role recognition.\n\n"
                            f"**3. Actionable Next Step**\n"
                            f"Focus on targeted applications, skill preparation, and active networking between {rng}."
                        )
                    msg_text = (
                        f"[Astrology Module Integration - Teammate 1]\n{saved_notice}"
                        f"{body}\n\n"
                        f"ℹ️ Note: {astro_resp.disclaimer}"
                    )
                else:
                    msg_text = (
                        f"[Astrology Module Integration - Teammate 1]\n{saved_notice}"
                        f"{astro_resp.interpretation_summary}\n\n"
                        f"ℹ️ Note: {astro_resp.disclaimer}"
                    )
                asst_msg = ChatMessage(
                    conversation_id=conv.id,
                    user_id=user.id,
                    sender="assistant",
                    text=msg_text,
                    detected_language=detected_lang,
                    intent="astrology",
                    route_target="teammate1_astrology",
                    safety_status="safe",
                    clarification_needed=False
                )
                db.add(asst_msg)
                db.commit()
                db.refresh(asst_msg)

                return {
                    "conversation_id": conv.id,
                    "user_message": user_msg,
                    "assistant_message": asst_msg,
                    "classification": classification,
                    "action_type": "teammate1_routed"
                }

            # 2. If birth details are NOT present:
            # Check if this is a general conceptual question vs personal reading request
            if not cls._is_personal_astrology_query(message_text):
                # General educational question (e.g. "What is a Nakshatra?", "Explain Saturn transit")
                past_msgs = db.query(ChatMessage).filter(
                    ChatMessage.conversation_id == conv.id
                ).order_by(ChatMessage.created_at.desc()).limit(6).all()
                history = [{"sender": m.sender, "text": m.text} for m in reversed(past_msgs)]

                has_birth = bool(user.birth_date and user.birth_place)
                timing_anchor = cls._get_or_derive_timing_anchor(user.id, message_text, user.birth_date) if has_birth else None
                eff_lang = "tanglish" if is_tanglish else ("telugu" if is_telugu else detected_lang)
                llm_resp = await LLMService.generate_response(
                    prompt=message_text,
                    conversation_history=history,
                    detected_language=eff_lang,
                    timing_anchor=timing_anchor,
                    birth_details_provided=has_birth
                )
                resp_text = llm_resp.get("text", "")
                if not resp_text or not resp_text.strip():
                    fallback_data = LLMService._build_unconfigured_fallback(
                        message_text, eff_lang, timing_anchor=timing_anchor, birth_details_provided=has_birth
                    )
                    resp_text = fallback_data["text"]

                asst_msg = ChatMessage(
                    conversation_id=conv.id,
                    user_id=user.id,
                    sender="assistant",
                    text=resp_text,
                    detected_language=detected_lang,
                    intent=intent,
                    route_target="teammate1_astrology",
                    safety_status="safe",
                    clarification_needed=False
                )
                db.add(asst_msg)
                db.commit()
                db.refresh(asst_msg)

                return {
                    "conversation_id": conv.id,
                    "user_message": user_msg,
                    "assistant_message": asst_msg,
                    "classification": classification,
                    "action_type": "general_response",
                    "is_live_ai": llm_resp.get("is_live_ai", False)
                }

            # Personal reading request with missing birth details -> Politely ask for DOB, TOB, POB
            if is_telugu:
                prompt_msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "మీ వ్యక్తిగత వేద జన్మ కుండలి (Janma Kundli), రాశి, నక్షత్రం మరియు దశా ఫలితాలను ఖచ్చితంగా లెక్కించడానికి మీ పుట్టిన వివరాలు అవసరం. "
                    "దయచేసి మీ వివరాలను చాట్‌లో పంపండి:\n"
                    "- పుట్టిన తేదీ (DOB - ఉదా: YYYY-MM-DD లేదా DD/MM/YYYY)\n"
                    "- పుట్టిన సమయం (TOB - ఉదా: 10:30 AM లేదా 14:30)\n"
                    "- పుట్టిన ప్రదేశం (POB - నగరం, రాష్ట్రం)\n\n"
                    "మీరు వీటిని చాట్‌లో తెలియజేయగానే, మీ ప్రొఫైల్‌లో సేవ్ చేసి మీ జాతక విశ్లేషణను వెంటనే అందిస్తాను!"
                )
            elif is_tanglish:
                prompt_msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "Mee personal Vedic birth chart (Janma Kundli), Rasi, Nakshatram mariyu Dasha calculations accurate ga cheyadaniki mee birth details kavali. "
                    "Please mee details chat lo share cheyandi:\n"
                    "- Date of Birth (DOB, e.g., YYYY-MM-DD)\n"
                    "- Time of Birth (TOB, e.g., 10:30 AM or 14:30)\n"
                    "- Place of Birth (POB - City, State)\n\n"
                    "Ee details meeru share cheyagane, profile lo save chesi accurate analysis provide chesthanu!"
                )
            else:
                prompt_msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "Your birth details are not on file yet. To calculate your personalized Vedic birth chart (Janma Kundli), "
                    "Rasi, Nakshatra, and Dasha accurately, please provide your:\n"
                    "1. Date of Birth (DOB, e.g., YYYY-MM-DD or DD Month YYYY)\n"
                    "2. Exact Time of Birth (TOB, e.g., 10:30 AM or 14:30)\n"
                    "3. Place of Birth (POB - City, State/Country)\n\n"
                    "Once shared in chat, I will save these details to your profile so you will not have to repeat them!"
                )

            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=prompt_msg,
                detected_language=detected_lang,
                intent="astrology",
                route_target="teammate1_astrology",
                safety_status="safe",
                clarification_needed=False
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "birth_details_requested"
            }

        # E. Teammate 1 Module: Habits
        if target_module == "teammate1_habits":
            habits_resp = await habits_adapter.get_user_habits_summary(user.id)
            msg_text = (
                f"[Habits Module Integration]\n{habits_resp.message}\n"
                f"Active Habits: {habits_resp.total_active_habits} | Completion Rate: {habits_resp.completion_rate_pct}%"
            )
            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=msg_text,
                detected_language=detected_lang,
                intent="habits",
                route_target="teammate1_habits",
                safety_status="safe",
                clarification_needed=False
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "teammate1_routed"
            }

        # F. Teammate 1 Module: Insights
        if target_module == "teammate1_insights":
            insights_resp = await insights_adapter.get_user_insights(user.id)
            msg_text = (
                f"[Insights Module Integration]\n{insights_resp.reflection_summary}\n"
                f"Suggestions: {', '.join(insights_resp.practical_suggestions)}"
            )
            asst_msg = ChatMessage(
                conversation_id=conv.id,
                user_id=user.id,
                sender="assistant",
                text=msg_text,
                detected_language=detected_lang,
                intent="insights",
                route_target="teammate1_insights",
                safety_status="safe",
                clarification_needed=False
            )
            db.add(asst_msg)
            db.commit()
            db.refresh(asst_msg)

            return {
                "conversation_id": conv.id,
                "user_message": user_msg,
                "assistant_message": asst_msg,
                "classification": classification,
                "action_type": "teammate1_routed"
            }

        # G. General Conversation / LLM fallback
        # Fetch recent conversation history
        past_msgs = db.query(ChatMessage).filter(
            ChatMessage.conversation_id == conv.id
        ).order_by(ChatMessage.created_at.desc()).limit(6).all()
        history = [
            {"sender": m.sender, "text": m.text} for m in reversed(past_msgs)
        ]

        has_birth = bool(user.birth_date and user.birth_place)
        timing_anchor = cls._get_or_derive_timing_anchor(user.id, message_text, user.birth_date) if has_birth else None
        is_tanglish = (detected_lang == "tanglish" or getattr(user, "preferred_language", "") == "tanglish")
        is_telugu = (detected_lang == "telugu" or getattr(user, "preferred_language", "") in ["te", "telugu"]) and not is_tanglish
        eff_lang = "tanglish" if is_tanglish else ("telugu" if is_telugu else detected_lang)

        llm_resp = await LLMService.generate_response(
            prompt=message_text,
            conversation_history=history,
            detected_language=eff_lang,
            timing_anchor=timing_anchor,
            birth_details_provided=has_birth
        )

        resp_text = llm_resp.get("text", "")
        if not resp_text or not resp_text.strip():
            fallback_data = LLMService._build_unconfigured_fallback(
                message_text, eff_lang, timing_anchor=timing_anchor, birth_details_provided=has_birth
            )
            resp_text = fallback_data["text"]

        asst_msg = ChatMessage(
            conversation_id=conv.id,
            user_id=user.id,
            sender="assistant",
            text=resp_text,
            detected_language=detected_lang,
            intent=intent,
            route_target=target_module,
            safety_status="safe",
            clarification_needed=False
        )
        db.add(asst_msg)
        db.commit()
        db.refresh(asst_msg)

        return {
            "conversation_id": conv.id,
            "user_message": user_msg,
            "assistant_message": asst_msg,
            "classification": classification,
            "action_type": "general_response",
            "is_live_ai": llm_resp.get("is_live_ai", False)
        }
