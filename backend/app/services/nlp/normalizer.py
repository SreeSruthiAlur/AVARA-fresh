import re

def normalize_text(text: str) -> str:
    """
    Lightweight, safe text normalization for multilingual Telugu/English/Tanglish.
    Preserves numbers, names, dates, amounts, and Telugu vowel diacritics.
    """
    if not text:
        return ""

    # 1. Strip edge whitespace
    s = text.strip()

    # 2. Normalize multiple spaces, tabs, and newlines
    s = re.sub(r'[ \t]+', ' ', s)
    s = re.sub(r'\n{3,}', '\n\n', s)

    # 3. Collapse repeated punctuation like '????' -> '?' and '!!!!' -> '!'
    s = re.sub(r'\?{2,}', '?', s)
    s = re.sub(r'!{2,}', '!', s)
    s = re.sub(r'\.{3,}', '...', s)

    # 4. Collapse elongated repeating English characters (e.g., 'hellooooo' -> 'helloo', 'chaaalaaa' -> 'chaalaa')
    # Does NOT alter numbers, digits, or Telugu Unicode combinations
    def collapse_char_repetition(match):
        ch = match.group(1)
        # Keep maximum 2 characters to preserve phonetic length in Tanglish (like 'aa' or 'ee')
        return ch * 2

    # Regex matches 3 or more of any ASCII alphabet character
    s = re.sub(r'([a-zA-Z])\1{2,}', collapse_char_repetition, s)

    # 5. Common informal contractions safe for normalization
    replacements = {
        r'\bpls\b': 'please',
        r'\bu\b': 'you',
        r'\br\b': 'are',
        r'\bthx\b': 'thanks',
        r'\btnx\b': 'thanks',
        r'\bk\b': 'ok',
        r'\bokk\b': 'ok',
    }
    for pattern, repl in replacements.items():
        s = re.sub(pattern, repl, s, flags=re.IGNORECASE)

    return s
