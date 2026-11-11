import logging
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

    @classmethod
    async def process_user_message(
        cls, db: Session, user: User, message_text: str, conversation_id: Optional[int] = None
    ) -> Dict[str, Any]:
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
            req = AstrologyBirthChartRequest(
                user_id=user.id,
                birth_date=user.birth_date or "2000-01-01",
                birth_time=user.birth_time or "12:00",
                birth_place=user.birth_place or "Hyderabad, India",
                preferred_language=user.preferred_language
            )
            astro_resp = await astrology_adapter.get_chart_and_interpretation(req)
            msg_text = (
                f"[Astrology Module Integration]\n{astro_resp.interpretation_summary}\n\n"
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

        llm_resp = await LLMService.generate_response(
            prompt=message_text,
            conversation_history=history,
            detected_language=detected_lang
        )

        asst_msg = ChatMessage(
            conversation_id=conv.id,
            user_id=user.id,
            sender="assistant",
            text=llm_resp["text"],
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
