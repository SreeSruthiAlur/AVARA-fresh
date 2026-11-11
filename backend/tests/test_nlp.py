import pytest
from app.services.nlp.language_detector import detect_language
from app.services.nlp.normalizer import normalize_text
from app.services.nlp.intent_classifier import IntentClassifier

def test_language_detection_telugu_script():
    text = "నాకు ఈరోజు ఖర్చులు ఎంత అయ్యాయో చూపించు"
    res = detect_language(text)
    assert res["detected_language"] == "telugu"
    assert res["confidence"] > 0.7
    assert res["telugu_char_ratio"] > 0.5

def test_language_detection_english():
    text = "How much did I spend on groceries this month?"
    res = detect_language(text)
    assert res["detected_language"] == "english"
    assert res["confidence"] > 0.7

def test_language_detection_tanglish():
    text = "naaku eeroju kharchulu entha ayyindi cheppandi"
    res = detect_language(text)
    assert res["detected_language"] == "tanglish"
    assert res["tanglish_matches"] >= 2

def test_language_detection_mixed():
    text = "ఈరోజు నా expenses total ఎంత?"
    res = detect_language(text)
    assert res["detected_language"] == "mixed"

def test_normalizer_repeated_chars_and_whitespace():
    raw = "chaaaaalaaaaa   dabbulu    migilindii???   "
    norm = normalize_text(raw)
    assert "chaalaa" in norm
    assert "   " not in norm
    assert norm.endswith("?")

def test_intent_classification_finance():
    text = "How much money did I spend on food this month?"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "finance"
    assert res["target_module"] == "finance"
    assert not res["needs_clarification"]

def test_intent_classification_health():
    text = "eeroju naaku alasata ga undi mood baaledhu"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "health"
    assert res["target_module"] == "health"

def test_intent_classification_teammate1_astrology():
    text = "నా జాతకం మరియు రాశి ఫలాలు చూపించు"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "astrology"
    assert res["target_module"] == "teammate1_astrology"

def test_intent_classification_teammate1_habits():
    text = "track my daily routine habit streak"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "habits"
    assert res["target_module"] == "teammate1_habits"

def test_intent_classification_teammate1_insights():
    text = "show my weekly reflection insights and growth patterns"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "insights"
    assert res["target_module"] == "teammate1_insights"

def test_intent_classification_astrologers_discovery():
    text = "Show me the list of available astrologers for consultation"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] in ["astrologer_discovery", "consultation_booking"]
    assert res["target_module"] == "astrologers"

def test_intent_ambiguous_clarification():
    text = "xyz 12345 foo bar"
    res = IntentClassifier.classify_and_route(text)
    assert res["intent"] == "unknown_ambiguous"
    assert res["needs_clarification"] is True
    assert res["clarifying_question"] is not None
