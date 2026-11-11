from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class SendMessageRequest(BaseModel):
    conversation_id: Optional[int] = None
    message: str = Field(..., min_length=1)

class SafetyCheckResult(BaseModel):
    is_safe: bool
    status: str  # "safe", "advisory", "crisis"
    reason: Optional[str] = None
    suggested_action: Optional[str] = None
    helpline: Optional[str] = None

class IntentRouteResult(BaseModel):
    intent: str
    confidence: float
    target_module: str  # "finance", "health", "astrologers", "teammate1_astrology", "teammate1_habits", "teammate1_insights", "general", "safety"
    needs_clarification: bool = False
    clarifying_question: Optional[str] = None

class ChatMessageResponse(BaseModel):
    id: int
    conversation_id: int
    sender: str
    text: str
    detected_language: Optional[str] = None
    language_confidence: Optional[float] = None
    intent: Optional[str] = None
    route_target: Optional[str] = None
    safety_status: str
    clarification_needed: bool = False
    created_at: datetime

    class Config:
        from_attributes = True

class ConversationResponse(BaseModel):
    id: int
    title: str
    created_at: datetime
    updated_at: datetime
    messages: List[ChatMessageResponse] = []

    class Config:
        from_attributes = True

class ConversationSummary(BaseModel):
    id: int
    title: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
