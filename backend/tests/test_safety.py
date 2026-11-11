import pytest
from app.services.nlp.safety_guard import SafetyGuard
from app.services.nlp.intent_classifier import IntentClassifier

def test_safety_mental_health_crisis_english():
    text = "I feel hopeless and I want to kill myself"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="english")
    assert res["is_safe"] is False
    assert res["status"] == "crisis"
    assert "Tele-MANAS" in res["helpline"] or "14416" in res["helpline"]

def test_safety_mental_health_crisis_telugu():
    text = "నాకు బ్రతకాలని లేదు ఆత్మహత్య చేసుకోవాలని ఉంది"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="telugu")
    assert res["is_safe"] is False
    assert res["status"] == "crisis"
    assert "14416" in res["response_guidance"]

def test_safety_mental_health_crisis_tanglish():
    text = "nenu chanipovalani anukuntunna life lo emi ledu"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="tanglish")
    assert res["is_safe"] is False
    assert res["status"] == "crisis"

def test_safety_medical_emergency_english():
    text = "I am having severe chest pain and cannot breathe prescribe medicine"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="english")
    assert res["is_safe"] is False
    assert res["status"] == "advisory"
    assert "108" in res["helpline"]

def test_safety_abuse_report():
    text = "Someone is threatening to kill me and violently hitting me at home"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="english")
    assert res["is_safe"] is False
    assert res["status"] == "crisis"
    assert "112" in res["helpline"]

def test_safety_financial_fraud_guarantee():
    text = "Is there guaranteed 100% returns scheme to double money in 2 days?"
    res = SafetyGuard.evaluate_input_safety(text, detected_language="english")
    assert res["is_safe"] is False
    assert res["status"] == "advisory"

def test_safety_intercepts_before_intent_routing():
    # Even if astrology or horoscope words are present, self-harm must be intercepted!
    text = "My horoscope is bad and I want to end my life"
    routed = IntentClassifier.classify_and_route(text)
    assert routed["intent"] == "safety_sensitive"
    assert routed["target_module"] == "safety"
    assert routed["safety_evaluation"]["is_safe"] is False

def test_llm_response_validation():
    dangerous_resp = "I guarantee this will cure your cancer without seeing a doctor."
    validated = SafetyGuard.validate_llm_response(dangerous_resp)
    assert "consult a licensed medical professional" in validated
