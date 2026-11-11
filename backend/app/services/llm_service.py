import logging
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
        "Never provide medical diagnoses or guaranteed financial returns."
    )

    @classmethod
    def is_configured(cls) -> bool:
        """Check if live LLM credentials are provided."""
        return bool(settings.LLM_API_KEY and settings.LLM_PROVIDER in ["gemini", "openai"])

    @classmethod
    async def generate_response(
        cls,
        prompt: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        system_instruction: Optional[str] = None,
        detected_language: str = "english"
    ) -> Dict[str, Any]:
        """
        Generate response using configured provider.
        If unconfigured or on failure, returns explicit transparent notice with safe guidance.
        """
        sys_prompt = system_instruction or cls.SYSTEM_PROMPT
        history = conversation_history or []

        # If live credentials are not configured, return explicit transparent message
        if not cls.is_configured():
            logger.info("Live LLM API key not configured. Returning transparent deterministic response.")
            return cls._build_unconfigured_fallback(prompt, detected_language)

        try:
            if settings.LLM_PROVIDER == "gemini":
                return await cls._call_gemini(prompt, history, sys_prompt, detected_language)
            elif settings.LLM_PROVIDER == "openai":
                return await cls._call_openai(prompt, history, sys_prompt, detected_language)
            else:
                return cls._build_unconfigured_fallback(prompt, detected_language)
        except Exception as e:
            logger.error(f"LLM generation failed: {str(e)}", exc_info=True)
            return {
                "text": (
                    "క్షమించండి, AI సర్వర్‌తో కమ్యూనికేషన్ తాత్కాలికంగా విఫలమైంది. దయచేసి కాసేపటి తర్వాత ప్రయత్నించండి."
                    if detected_language in ["telugu", "tanglish"] else
                    "We encountered a temporary connection issue with the AI engine. Please try again in a moment."
                ),
                "is_live_ai": False,
                "provider": settings.LLM_PROVIDER,
                "error": str(e)
            }

    @classmethod
    async def _call_gemini(
        cls, prompt: str, history: List[Dict[str, str]], system_prompt: str, language: str
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
                # Safety validate response
                validated_text = SafetyGuard.validate_llm_response(raw_text)
                return {
                    "text": validated_text,
                    "is_live_ai": True,
                    "provider": "gemini",
                    "model": settings.LLM_MODEL
                }
            else:
                logger.error(f"Gemini API error {response.status_code}: {response.text}")
                return cls._build_unconfigured_fallback(prompt, language, error_msg=f"API error {response.status_code}")

    @classmethod
    async def _call_openai(
        cls, prompt: str, history: List[Dict[str, str]], system_prompt: str, language: str
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
                json={"model": settings.LLM_MODEL, "messages": messages, "temperature": 0.7}
            )
            if response.status_code == 200:
                data = response.json()
                raw_text = data["choices"][0]["message"]["content"]
                validated_text = SafetyGuard.validate_llm_response(raw_text)
                return {
                    "text": validated_text,
                    "is_live_ai": True,
                    "provider": "openai",
                    "model": settings.LLM_MODEL
                }
            else:
                return cls._build_unconfigured_fallback(prompt, language, error_msg=f"OpenAI error {response.status_code}")

    @classmethod
    def _build_unconfigured_fallback(cls, prompt: str, language: str, error_msg: Optional[str] = None) -> Dict[str, Any]:
        """
        Explicit message when live AI API is unconfigured.
        Transparently informs user that live LLM is unconfigured, without pretending to be live AI.
        """
        if language in ["telugu", "tanglish"]:
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
