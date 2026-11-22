import io
import logging
import edge_tts
from fastapi import APIRouter, Query, HTTPException
from fastapi.responses import Response

logger = logging.getLogger("avara.tts")

router = APIRouter(prefix="/tts", tags=["Text to Speech"])

VOICE_MAP = {
    "ml": "ml-IN-SobhanaNeural",
    "manglish": "ml-IN-SobhanaNeural",
    "te": "te-IN-ShrutiNeural",
    "tanglish": "te-IN-ShrutiNeural",
    "en": "en-IN-NeerjaNeural",
}

@router.get("/synthesize")
async def synthesize_speech(
    text: str = Query(..., min_length=1, max_length=3000, description="Text to speak aloud"),
    lang: str = Query("ml", description="Target language code: ml, manglish, te, tanglish, en")
):
    """
    High-fidelity neural text-to-speech for AVARA.
    Synthesizes authentic native Indian voices (Malayalam, Telugu, English).
    """
    voice = VOICE_MAP.get(lang.lower().strip(), "ml-IN-SobhanaNeural")
    clean_text = text.strip()
    if not clean_text:
        raise HTTPException(status_code=400, detail="Text cannot be empty.")

    try:
        logger.info(f"Synthesizing neural speech with voice '{voice}' ({len(clean_text)} chars)")
        communicate = edge_tts.Communicate(clean_text, voice)
        mp3_bytes = bytearray()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                mp3_bytes.extend(chunk["data"])

        return Response(
            content=bytes(mp3_bytes),
            media_type="audio/mpeg",
            headers={
                "Cache-Control": "public, max-age=86400",
                "Content-Disposition": 'inline; filename="speech.mp3"',
            }
        )
    except Exception as e:
        logger.error(f"TTS Synthesis error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"TTS error: {str(e)}")
