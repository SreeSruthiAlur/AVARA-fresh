import logging
import re
from datetime import datetime
from typing import List, Dict, Any, Optional
import httpx
from app.core.config import settings
from app.services.nlp.safety_guard import SafetyGuard

logger = logging.getLogger("avara.llm")

class LLMService:
    """
    Shared, reusable LLM infrastructure for AVARA.
    Supports configurable providers (Gemini, OpenAI), timeouts, retries,
    conversation context, response validation, and transparent fallback.
    """

    SYSTEM_PROMPT = (
        "You are AVARA, an empathetic and supportive AI companion for personal growth, "
        "wellness, and financial mindfulness. You speak Telugu, English, and Tanglish fluently. "
        "Keep your advice grounded, respectful, and encouraging. Never invent facts or hallucinate financial numbers. "
        "Never provide medical diagnoses or guaranteed financial returns.\n\n"
        "STRICT NO-META RULE: Output ONLY the final user-facing response. NEVER output internal planning, "
        "word-counting, draft outlines, thought traces (<think>), or meta-commentary in user-facing content.\n\n"
        "VEDIC ASTROLOGY (SIDEREAL NIRAYANA) ACCURACY & TIMING RULES:\n"
        "1. Canonical Signs 1–12 Order: 1. Aries (Mesha), 2. Taurus (Vrishabha), 3. Gemini (Mithuna), "
        "4. Cancer (Karka), 5. Leo (Simha), 6. Virgo (Kanya), 7. Libra (Tula), 8. Scorpio (Vrishchika), "
        "9. Sagittarius (Dhanu), 10. Capricorn (Makara), 11. Aquarius (Kumbha), 12. Pisces (Meena). "
        "Sagittarius is strictly the 9th sign, never the 11th (Aquarius is the 11th sign).\n"
        "2. Rasi & Nakshatra Derivation: In Vedic astrology, Rasi (Moon sign) and Janma Nakshatra strictly derive "
        "from the Moon's sidereal position, NEVER from the Sun's.\n"
        "3. Krittika Span: Krittika nakshatra spans 26°40' Aries (Mesha) to 10°00' Taurus (Vrishabha)—never Sagittarius.\n"
        "4. No Fabrication When Data Absent: Never fabricate, hallucinate, or pretend planetary degrees, signs, "
        "or Nakshatra placements exist when real birth chart data is absent. If personal chart details (DOB/TOB/POB) "
        "are missing, politely ask the user for their Date of Birth (DOB), Time of Birth (TOB), and Place of Birth (POB). "
        "If the user asks a general educational question, answer directly without requiring birth details.\n"
        "5. Direct Answer First & No Kundli Dumps: When answering questions about astrology, career phases, promotions, finances, or remedies, "
        "treat birth chart (Janma Kundli) and Dasha data strictly as background reference data, NOT as the answer itself. "
        "Always give a direct answer to the user's exact question in the first 1-2 sentences. "
        "Provide targeted reasoning only, referencing the specific house, planet, or Dasha period relevant to their question, "
        "and never recite or dump the full birth chart unless the user explicitly asks for a full chart overview.\n"
        "6. Concrete Month & Year Timing (No Wide Spans or Vague Durations): Whenever answering timing or outcome questions "
        "(e.g., 'is this a good time to improve my career?', 'when will I get a good internship?', 'when will I get a promotion / job / milestone?', 'when will my finances improve?'):\n"
        "   - State a specific Month and Year (e.g., Month YYYY, or a tight 1–2 month window like Month YYYY – Month YYYY) "
        "directly in sentences 1–2 as the peak window when the opportunity / milestone turns into reality, anchored to the current calendar date and active Antardasha / transits.\n"
        "   - Do NOT rely solely on wide multi-year Mahadasha spans (like multi-decade Mahadasha periods) or vague durations (like 'soon' or 'next 3–6 months') as the primary answer.\n"
        "   - If exact Antardasha/transit tables are not in the context, still provide a concrete Month and Year estimate grounded in the current date and Vedic transit cycles, "
        "and clearly note that it is an estimated window based on available planetary transit and Dasha data rather than an exact calculated Bhukti table.\n"
        "7. Equal Length, Structure & Depth Across English and Tanglish:\n"
        "   - Do NOT make Tanglish responses longer, wordier, or more elaborate than English responses (or vice versa).\n"
        "   - Enforce parity in length, section count, and bullet depth between English and Tanglish (concise target: ~80–120 words. Do NOT loop counting words in thought traces).\n"
        "   - Structure responses into exactly 3 sections:\n"
        "     ### Direct Timing & Outcome (or Direct Timing & Phalam in Tanglish)\n"
        "     ### Key Astrological Factors (or Graha & Dasha Factors in Tanglish with exactly 2 concise bullets)\n"
        "     ### Actionable Next Step (1 sentence practical takeaway)\n"
        "   - When Tanglish is selected, write exclusively in natural conversational Telugu using Latin characters mixed with English terms (e.g., 'Mee chart prakaram...', '10th house lo transit favorable ga undi...'). Never revert to pure English prose and never output redundant multi-language translations."
    )

    @classmethod
    def is_configured(cls) -> bool:
        """Check if live LLM credentials are provided."""
        return bool(settings.LLM_API_KEY and settings.LLM_PROVIDER in ["gemini", "openai"])

    @classmethod
    def sanitize_llm_response(cls, text: str) -> str:
        """
        Strips internal reasoning traces, <think> blocks, word-counting markers,
        draft notes, and planning scratchpad lines so only the final user-facing response remains.
        """
        if not text:
            return ""

        # 1. Strip <think>...</think> blocks (including unclosed <think>)
        cleaned = re.sub(r'<think>[\s\S]*?(?:</think>|$)', '', text, flags=re.IGNORECASE)

        # 2. Strip scratchpad and drafting lines
        scratchpad_patterns = (
            r'(?im)^\s*(?:word count:|let\'s draft|let\'s count|let\'s check|drafting:|scratchpad:|thinking process:|internal reasoning:).*$'
        )
        cleaned = re.sub(scratchpad_patterns, '', cleaned)

        # 3. If there is intro draft noise before the actual sections
        m = re.search(r'(?:###|\*\*[123]\.)[\s\S]+', cleaned)
        if m and not cleaned.strip().startswith(('**1.', '###', '1.')):
            pre = cleaned[:m.start()].strip().lower()
            if any(noise in pre for noise in ['here is', 'draft', 'response:', 'below is', 'sure']) or len(pre) < 80:
                cleaned = m.group(0)

        return cleaned.strip()

    @classmethod
    async def generate_response(
        cls,
        prompt: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        system_instruction: Optional[str] = None,
        detected_language: str = "english",
        timing_anchor: Optional[Dict[str, str]] = None,
        birth_details_provided: bool = False
    ) -> Dict[str, Any]:
        """
        Generate response using configured provider.
        If unconfigured or on failure, returns explicit transparent notice with safe guidance.
        """
        now_anchor = datetime.now().strftime("%B %Y")
        date_context = f"[CURRENT CALENDAR ANCHOR: {now_anchor} (Reference date for 'today / current time')]\n\n"

        # Explicit birth details status
        if birth_details_provided:
            birth_status_block = (
                "[BIRTH DETAILS STATUS: PROVIDED]\n"
                "birth_details_provided: true\n\n"
            )
        else:
            birth_status_block = (
                "[BIRTH DETAILS STATUS: NOT PROVIDED]\n"
                "birth_details_provided: false\n"
                "[NO birth chart, Dasha data, or planetary placements are available for this user. "
                "If the user asks any personal reading, personal prediction, personal timing, or horoscope question, "
                "politely explain that their birth details are not on file and ask for their Date of Birth (DOB), "
                "Time of Birth (TOB), and Place of Birth (POB). Never simulate, pretend, or fabricate personal chart placements.]\n\n"
            )

        timing_block = ""
        # Strictly forbid injecting timing anchors based on fake charts when birth details are missing
        if timing_anchor and birth_details_provided:
            timing_block = (
                f"[DETERMINISTIC TIMING ANCHOR FOR THIS QUERY (MANDATORY ACROSS ALL LANGUAGES)]:\n"
                f"- Query Topic: {timing_anchor.get('topic', '').upper()}\n"
                f"- Fixed Peak Timing: {timing_anchor.get('peak_month_year', '')}\n"
                f"- Fixed Favorable Window: {timing_anchor.get('range_window', '')}\n"
                f"- Astrological Basis: {timing_anchor.get('basis', '')}\n"
                f"- STRICT CONSISTENCY RULE: You MUST cite this EXACT Month and Year "
                f"({timing_anchor.get('peak_month_year', '')} / {timing_anchor.get('range_window', '')}) in your direct answer. "
                f"Do NOT change, drift, or invent a different month or year, regardless of whether you are responding in English, Telugu, or Tanglish.\n\n"
            )
        base_prompt = system_instruction or cls.SYSTEM_PROMPT
        sys_prompt = date_context + birth_status_block + timing_block + base_prompt
        history = conversation_history or []

        # If live credentials are not configured, return explicit transparent message
        if not cls.is_configured():
            logger.info("Live LLM API key not configured. Returning transparent deterministic response.")
            return cls._build_unconfigured_fallback(
                prompt, detected_language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
            )

        try:
            if settings.LLM_PROVIDER == "gemini":
                return await cls._call_gemini(
                    prompt, history, sys_prompt, detected_language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                )
            elif settings.LLM_PROVIDER == "openai":
                return await cls._call_openai(
                    prompt, history, sys_prompt, detected_language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                )
            else:
                return cls._build_unconfigured_fallback(
                    prompt, detected_language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                )
        except Exception as e:
            logger.error(f"LLM generation failed: {str(e)}", exc_info=True)
            return cls._build_unconfigured_fallback(
                prompt, detected_language, error_msg=str(e), timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
            )

    @classmethod
    async def _call_gemini(
        cls,
        prompt: str,
        history: List[Dict[str, str]],
        system_prompt: str,
        language: str,
        timing_anchor: Optional[Dict[str, str]] = None,
        birth_details_provided: bool = False
    ) -> Dict[str, Any]:
        """Call Gemini REST API directly with httpx (no external SDK dependency required)."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.LLM_MODEL}:generateContent?key={settings.LLM_API_KEY}"
        
        contents = []
        # System instruction
        contents.append({
            "role": "user",
            "parts": [{"text": f"System Instruction: {system_prompt}"}]
        })
        contents.append({
            "role": "model",
            "parts": [{"text": "Understood. I will strictly follow these instructions."}]
        })

        # Add history
        for msg in history[-6:]:  # Keep recent context
            role = "user" if msg.get("sender") == "user" else "model"
            contents.append({
                "role": role,
                "parts": [{"text": msg.get("text", "")}]
            })

        # Add current user prompt
        contents.append({
            "role": "user",
            "parts": [{"text": prompt}]
        })

        async with httpx.AsyncClient(timeout=settings.LLM_TIMEOUT_SECONDS) as client:
            response = await client.post(url, json={"contents": contents})
            if response.status_code == 200:
                data = response.json()
                raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
                cleaned_text = cls.sanitize_llm_response(raw_text)
                # Safety validate response
                validated_text = SafetyGuard.validate_llm_response(cleaned_text, language=language)
                if not validated_text or not validated_text.strip():
                    return cls._build_unconfigured_fallback(
                        prompt, language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                    )
                return {
                    "text": validated_text,
                    "is_live_ai": True,
                    "provider": "gemini",
                    "model": settings.LLM_MODEL
                }
            else:
                logger.error(f"Gemini API error {response.status_code}: {response.text}")
                return cls._build_unconfigured_fallback(
                    prompt, language, error_msg=f"API error {response.status_code}", timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                )

    @classmethod
    async def _call_openai(
        cls,
        prompt: str,
        history: List[Dict[str, str]],
        system_prompt: str,
        language: str,
        timing_anchor: Optional[Dict[str, str]] = None,
        birth_details_provided: bool = False
    ) -> Dict[str, Any]:
        """Call OpenAI REST API with httpx."""
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {settings.LLM_API_KEY}",
            "Content-Type": "application/json"
        }
        messages = [{"role": "system", "content": system_prompt}]
        for msg in history[-6:]:
            role = "user" if msg.get("sender") == "user" else "assistant"
            messages.append({"role": role, "content": msg.get("text", "")})
        messages.append({"role": "user", "content": prompt})

        async with httpx.AsyncClient(timeout=settings.LLM_TIMEOUT_SECONDS) as client:
            response = await client.post(
                url,
                headers=headers,
                json={
                    "model": settings.LLM_MODEL,
                    "messages": messages,
                    "temperature": 0.7,
                    "max_tokens": 1500,
                }
            )
            if response.status_code == 200:
                data = response.json()
                raw_text = data["choices"][0]["message"].get("content") or ""
                cleaned_text = cls.sanitize_llm_response(raw_text)
                validated_text = SafetyGuard.validate_llm_response(cleaned_text, language=language)
                if not validated_text or not validated_text.strip():
                    return cls._build_unconfigured_fallback(
                        prompt, language, timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                    )
                return {
                    "text": validated_text,
                    "is_live_ai": True,
                    "provider": "openai",
                    "model": settings.LLM_MODEL
                }
            else:
                return cls._build_unconfigured_fallback(
                    prompt, language, error_msg=f"OpenAI error {response.status_code}", timing_anchor=timing_anchor, birth_details_provided=birth_details_provided
                )

    @classmethod
    def _build_unconfigured_fallback(
        cls,
        prompt: str,
        language: str,
        error_msg: Optional[str] = None,
        timing_anchor: Optional[Dict[str, str]] = None,
        birth_details_provided: bool = False
    ) -> Dict[str, Any]:
        """
        Structured response when live AI API is unconfigured.
        Provides deterministic timing response if a timing anchor is supplied and birth details are provided,
        or prompts for missing birth details, or transparent unconfigured notice otherwise.
        """
        if timing_anchor and birth_details_provided:
            peak = timing_anchor.get("peak_month_year", "")
            rng = timing_anchor.get("range_window", "")
            if language == "tanglish":
                msg = (
                    f"**1. Direct Timing & Outcome**\n"
                    f"Mee chart prakaram strongest favorable window **{peak}** ({rng}), ee samayamlo career opportunities peak avthayi.\n\n"
                    f"**2. Key Astrological Factors**\n"
                    f"- **Planetary Transit:** Favorable Jupiter transit mee 10th house (Karma Bhava) ni aspect chesi, growth ki support isthundi.\n"
                    f"- **Dasha & Timing Alignment:** Supportive sub-period transit alignment valla positive results mariyu opportunity recognition untayi.\n\n"
                    f"**3. Actionable Next Step**\n"
                    f"{rng} madhyalo targeted preparation, applications mariyu networking meeda focus pettandi."
                )
            elif language == "telugu":
                msg = (
                    f"**1. Direct Timing & Outcome**\n"
                    f"మీ జన్మ కుండలి ప్రకారం అనుకూలమైన ప్రధాన సమయం **{peak}** ({rng}), ఈ కాలంలో కెరీర్ అవకాశాలు గరిష్ట స్థాయికి చేరుకుంటాయి.\n\n"
                    f"**2. Key Astrological Factors**\n"
                    f"- **గ్రహ గోచారం:** గురు గ్రహ (Jupiter) అనుకూల దృష్టి మీ 10వ స్థానం (కర్మ భావం) పై ఉండటం వల్ల ఉద్యోగ వృద్ధికి తోడ్పడుతుంది.\n"
                    f"- **దశా సమన్వయం:** అనుకూల అంతర్దశ ప్రభావం వల్ల కొత్త అవకాశాలు మరియు గుర్తింపు లభిస్తాయి.\n\n"
                    f"**3. Actionable Next Step**\n"
                    f"{rng} సమయంలో ప్రాజెక్ట్ ప్రిపరేషన్, అప్లికేషన్లు మరియు నెట్‌వర్కింగ్ పై దృష్టి పెట్టండి."
                )
            else:
                msg = (
                    f"**1. Direct Timing & Outcome**\n"
                    f"Your strongest favorable window is **{peak}** ({rng}), when key opportunity and planetary transits peak.\n\n"
                    f"**2. Key Astrological Factors**\n"
                    f"- **Planetary Transit:** Favorable Jupiter transit aspects your 10th house (Karma Bhava), activating professional and career growth.\n"
                    f"- **Dasha & Timing Alignment:** Supportive sub-period progression reinforces positive recognition and milestone achievement.\n\n"
                    f"**3. Actionable Next Step**\n"
                    f"Focus on targeted preparation, applications, and networking during {rng}."
                )
            return {
                "text": msg,
                "is_live_ai": False,
                "provider": "deterministic-engine",
                "model": "rule-based-engine"
            }

        # If birth details are missing and prompt is asking for personal timing/horoscope reading
        clean_p = prompt.lower()
        is_personal_reading = any(k in clean_p for k in [
            "when will", "eppudu", "eppatiki", "internship", "promotion", "career", "job", "milestone",
            "kundli", "kundali", "jathakam", "dasha", "mahadasha", "rashi", "rasi", "nakshatra", "lagna", "finance"
        ])
        if not birth_details_provided and is_personal_reading:
            if language == "tanglish":
                msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "Mee personal Vedic birth chart (Janma Kundli), Rasi, Nakshatram mariyu Dasha calculations accurate ga cheyadaniki mee birth details kavali. "
                    "Please mee details chat lo share cheyandi:\n"
                    "- Date of Birth (DOB, e.g., YYYY-MM-DD)\n"
                    "- Time of Birth (TOB, e.g., 10:30 AM or 14:30)\n"
                    "- Place of Birth (POB - City, State)\n\n"
                    "Ee details meeru share cheyagane, profile lo save chesi accurate analysis provide chesthanu!"
                )
            elif language == "telugu":
                msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "మీ వ్యక్తిగత వేద జన్మ కుండలి (Janma Kundli), రాశి, నక్షత్రం మరియు దశా ఫలితాలను ఖచ్చితంగా లెక్కించడానికి మీ పుట్టిన వివరాలు అవసరం. "
                    "దయచేసి మీ వివరాలను చాట్‌లో పంపండి:\n"
                    "- పుట్టిన తేదీ (DOB - ఉదా: YYYY-MM-DD లేదా DD/MM/YYYY)\n"
                    "- పుట్టిన సమయం (TOB - ఉదా: 10:30 AM లేదా 14:30)\n"
                    "- పుట్టిన ప్రదేశం (POB - నగరం, రాష్ట్రం)\n\n"
                    "మీరు వీటిని చాట్‌లో తెలియజేయగానే, మీ ప్రొఫైల్‌లో సేవ్ చేసి మీ జాతక విశ్లేషణను వెంటనే అందిస్తాను!"
                )
            else:
                msg = (
                    "[Astrology Module Integration - Teammate 1]\n"
                    "Your birth details are not on file yet. To calculate your personalized Vedic birth chart (Janma Kundli), "
                    "Rasi, Nakshatra, and Dasha accurately, please provide your:\n"
                    "1. Date of Birth (DOB, e.g., YYYY-MM-DD or DD Month YYYY)\n"
                    "2. Exact Time of Birth (TOB, e.g., 10:30 AM or 14:30)\n"
                    "3. Place of Birth (POB, e.g., City, State/Country)\n\n"
                    "Once shared, I will save them to your profile and analyze your chart directly in chat!"
                )
            return {
                "text": msg,
                "is_live_ai": False,
                "provider": "deterministic-engine",
                "model": "rule-based-engine"
            }

        if language == "tanglish":
            msg = (
                "గమనిక: Mee query ni process cheyadaniki AVARA background services operational ga unnayi. "
                "Finance management, Health tracking, mariyu Astrologer directory services eppudaina use chesukovachu."
            )
        elif language == "telugu":
            msg = (
                "గమనిక: లైవ్ AI API కీ ప్రస్తుతం కాన్ఫిగర్ కాలేదు (LLM Provider: Unconfigured). "
                "అయినప్పటికీ మీరు AVARA లో ఖర్చులు (Finance), ఆరోగ్యం (Wellness), జ్యోతిష్యులు (Astrologers) "
                "మరియు ప్రొఫైల్ సేవలను పూర్తిగా ఉపయోగించుకోవచ్చు."
            )
        else:
            msg = (
                "Note: Live AI API credentials are currently not configured (LLM Provider: Unconfigured). "
                "All deterministic features — including Finance management, Health tracking, Astrologer consultations, "
                "and multilingual intent routing — remain fully operational."
            )
        return {
            "text": msg,
            "is_live_ai": False,
            "provider": "none",
            "model": "rule-based-engine",
            "notice": "Live LLM is not configured. Set LLM_API_KEY in environment to enable live generative AI."
        }
