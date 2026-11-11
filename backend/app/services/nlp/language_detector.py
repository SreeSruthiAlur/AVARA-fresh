import re
from typing import Dict, Any, Tuple

# Telugu Unicode Block: U+0C00 to U+0C7F
TELUGU_UNICODE_RANGE = (0x0C00, 0x0C7F)

# Common Tanglish phonetic tokens and grammatical markers
TANGLISH_VOCABULARY = {
    # Greetings & Common words
    "namaskaram", "namaste", "ela", "unnav", "unnaru", "enti", "emti", "cheppandi", "cheppu",
    "kavali", "vaddu", "ledu", "undhi", "undha", "unnadi", "avunu", "kaadu", "chudandi", "chudu",
    "bagunna", "bagundi", "manchidi", "dhanyavadalu", "please", "repu", "eeroju", "ninna",
    "ippudu", "appudu", "eppudu", "ekkada", "enduku", "elaaga", "entha", "evaru", "naaku",
    "nenu", "meeru", "manaki", "vaallu", "chala", "chaala", "koncham", "thondaraga",
    
    # Financial markers in Tanglish
    "kharchu", "kharchulu", "dabbu", "dabbulu", "karchu", "budget", "spend", "ayindi",
    "motham", "migilindi", "rupailu", "rupayalu", "billulu", "saving",
    
    # Health markers in Tanglish
    "aarogyam", "arogyam", "nidra", "thindi", "alasata", "shakthi", "badhaga", "talanoppi",
    "kadupunoppi", "manasika", "stress", "mood", "bhayapaddanu", "bhayam", "alupuga",
    
    # Astrology markers in Tanglish
    "jathakam", "raasi", "nakshatram", "grahalu", "kundali", "subham", "dosharn", "dosham",
    "astrologer", "pandit", "muhurtham", "horoscope",
    
    # Habit & Insights markers in Tanglish
    "alavatu", "alavatlu", "prathi", "roju", "daily", "routine", "anukoni", "anukoledhu"
}

def is_telugu_char(ch: str) -> bool:
    """Check if character is within Telugu Unicode block."""
    cp = ord(ch)
    return TELUGU_UNICODE_RANGE[0] <= cp <= TELUGU_UNICODE_RANGE[1]

def detect_language(text: str) -> Dict[str, Any]:
    """
    Detect language using Unicode character frequency, linguistic markers,
    and rule-based heuristics.
    
    Returns:
        {
            "original_text": str,
            "detected_language": "telugu" | "english" | "tanglish" | "mixed",
            "confidence": float,
            "telugu_char_ratio": float,
            "latin_char_ratio": float,
            "is_script_pure": bool
        }
    """
    if not text or not text.strip():
        return {
            "original_text": text,
            "detected_language": "english",
            "confidence": 0.5,
            "telugu_char_ratio": 0.0,
            "latin_char_ratio": 0.0,
            "is_script_pure": True,
            "notes": "Empty text defaulted to English"
        }

    clean_text = text.strip()
    total_chars = 0
    telugu_chars = 0
    latin_chars = 0

    for ch in clean_text:
        if ch.isalpha() or is_telugu_char(ch):
            total_chars += 1
            if is_telugu_char(ch):
                telugu_chars += 1
            elif 'a' <= ch.lower() <= 'z':
                latin_chars += 1

    if total_chars == 0:
        return {
            "original_text": text,
            "detected_language": "english",
            "confidence": 0.5,
            "telugu_char_ratio": 0.0,
            "latin_char_ratio": 0.0,
            "is_script_pure": True
        }

    telugu_ratio = telugu_chars / total_chars
    latin_ratio = latin_chars / total_chars

    # Tokenize Latin words to check for Tanglish vocabulary
    words = re.findall(r'[a-zA-Z]+', clean_text.lower())
    tanglish_matches = sum(1 for w in words if w in TANGLISH_VOCABULARY)
    tanglish_ratio = tanglish_matches / len(words) if words else 0.0

    # Classification logic
    if telugu_ratio >= 0.75:
        detected = "telugu"
        confidence = min(0.99, round(0.70 + (telugu_ratio * 0.28), 2))
        is_pure = latin_ratio < 0.05
    elif telugu_ratio > 0.15 and latin_ratio > 0.15:
        detected = "mixed"
        confidence = round(0.85, 2)
        is_pure = False
    elif latin_ratio >= 0.70:
        if tanglish_matches >= 1 and (tanglish_ratio >= 0.20 or tanglish_matches >= 2):
            detected = "tanglish"
            confidence = min(0.95, round(0.65 + (tanglish_ratio * 0.30), 2))
            is_pure = False
        else:
            detected = "english"
            confidence = min(0.98, round(0.70 + (latin_ratio * 0.25), 2))
            is_pure = True
    elif telugu_ratio > 0:
        detected = "mixed"
        confidence = 0.75
        is_pure = False
    else:
        detected = "english"
        confidence = 0.60
        is_pure = False

    return {
        "original_text": text,
        "detected_language": detected,
        "confidence": confidence,
        "telugu_char_ratio": round(telugu_ratio, 3),
        "latin_char_ratio": round(latin_ratio, 3),
        "is_script_pure": is_pure,
        "tanglish_matches": tanglish_matches
    }
