from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.errors import NotFoundError
from app.middleware.auth import get_current_user
from app.models.user import User
from app.models.chat import Conversation, ChatMessage
from app.schemas.chat import (
    SendMessageRequest,
    ChatMessageResponse,
    ConversationResponse,
    ConversationSummary
)
from app.services.chat_service import ChatService

router = APIRouter(prefix="/chat", tags=["Multilingual Chatbot"])

@router.post("/message")
async def send_message(
    req: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send message through the multilingual NLP pipeline:
    Language detection -> Normalization -> Safety checks -> Intent classification -> Module routing -> Response validation.
    """
    result = await ChatService.process_user_message(
        db=db,
        user=current_user,
        message_text=req.message,
        conversation_id=req.conversation_id
    )

    return {
        "success": True,
        "conversation_id": result["conversation_id"],
        "user_message": ChatMessageResponse.model_validate(result["user_message"]),
        "assistant_message": ChatMessageResponse.model_validate(result["assistant_message"]),
        "intent": result["classification"]["intent"],
        "detected_language": result["classification"]["language_info"]["detected_language"],
        "route_target": result["classification"]["target_module"],
        "safety_status": result["classification"]["safety_evaluation"].get("status", "safe"),
        "action_type": result.get("action_type")
    }

@router.get("/conversations", response_model=List[ConversationSummary])
def list_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List all conversations belonging to authenticated user."""
    return db.query(Conversation).filter(
        Conversation.user_id == current_user.id
    ).order_by(Conversation.updated_at.desc()).all()

@router.get("/conversations/{conversation_id}", response_model=ConversationResponse)
def get_conversation_history(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieve conversation messages history."""
    conv = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    if not conv:
        raise NotFoundError("Conversation not found")
    return conv

@router.delete("/conversations/{conversation_id}")
def delete_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a conversation."""
    conv = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    if not conv:
        raise NotFoundError("Conversation not found")
    db.delete(conv)
    db.commit()
    return {"success": True, "message": "Conversation deleted"}
