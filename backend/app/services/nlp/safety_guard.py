import re
from typing import Dict, Any, Optional

class SafetyGuard:
    """
    Multilingual safety classification and response validation layer.
    Handles Telugu script, English, and Tanglish.
    Ensures safety checks run BEFORE intent routing.
    """

    # Crisis & Self-Harm Indicators
    SELF_HARM_PATTERNS = [
        # English
        r"\b(suicide|kill\s+myself|end\s+my\s+life|want\s+to\s+die|hang\s+myself|self[\s-]harm|slit\s+my\s+wrist)\b",
        # Telugu Script
        r"(చనిపోవాలని|ఆత్మహత్య|ప్రాణం\s*తీసుకుంటా|బ్రతకాలని\s*లేదు|చావాలనిపించింది)",
        # Tanglish
        r"\b(chanipovalani|chachipovali|aathmahathya|pranam\s+theeskunta|bathakalani\s+ledu|chavali\s+anipisthundi|chavali)\b"
    ]

    # Medical Treatment & Clinical Diagnosis Indicators
    MEDICAL_CRITICAL_PATTERNS = [
        # English
        r"\b(chest\s+pain|heart\s+attack|stroke|unconscious|heavy\s+bleeding|overdose|difficulty\s+breathing|seizure)\b",
        r"\b(prescribe\s+medicine|diagnose\s+me|cure\s+my\s+cancer|what\s+pill\s+to\s+take)\b",
        # Telugu Script
        r"(గుండెనొప్పి|రక్తం\s*కారుతోంది|శ్వాస\s*తీసుకోలేకపోతున్నా|క్యాన్సర్\s*నయం|మందులు\s*రాయండి)",
        # Tanglish
        r"\b(gundenoppi|blood\s+karuthondi|swasa\s+aadatledu|mandulu\s+ivvandi|cure\s+cheyandi|tablets\s+cheppandi)\b"
    ]

    # Abuse & Violence Indicators
    ABUSE_PATTERNS = [
        # English
        r"\b(domestic\s+violence|violence|hitting\s+me|hit\s+me|abused|assaulted|threaten(ed|ing)?\s+(to\s+)?kill|raped|beating\s+me)\b",
        # Telugu Script
        r"(నన్ను\s*కొడుతున్నారు|వేధింపులు|చంపుతామని\s*బెదిరిస్తున్నారు|హింసిస్తున్నారు)",
        # Tanglish
        r"\b(kottaru|kottuthunnaru|vedhimpu|champesthanu|violence|himsa)\b"
    ]

    # High-Risk Financial & Fraud Indicators
    FINANCIAL_RISK_PATTERNS = [
        # English
        r"\b(guaranteed\s+100%\s+returns|double\s+money\s+in\s+days|insider\s+trading|crypto\s+pump\s+and\s+dump|guaranteed\s+lottery\s+jackpot)\b",
        # Telugu Script
        r"(డబ్బులు\s*డబుల్|గ్యారెంటీ\s*లాభం|లాటరీ\s*జాక్‌పాట్)",
        # Tanglish
        r"\b(dabbu\s+double|guarantee\s+profit|lottery\s+gelusthana)\b"
    ]

    # Emergency Contacts
    HELPLINES = {
        "crisis": "National Emergency: 112 | Tele-MANAS (Mental Health Helpline India): 14416 (24x7 toll-free) | Kiran: 1800-599-0019",
        "medical": "Emergency Ambulance: 108 | National Emergency: 112",
        "abuse": "Women Helpline: 1091 | National Emergency: 112 | Domestic Violence Helpline: 181"
    }

    @classmethod
    def evaluate_input_safety(cls, text: str, detected_language: str = "english") -> Dict[str, Any]:
        """
        Check incoming user query against safety rules before routing.
        """
        if not text:
            return {"is_safe": True, "status": "safe"}

        lower_text = text.lower()

        # 1. Self-Harm & Mental Health Crisis (Highest Priority)
        for pattern in cls.SELF_HARM_PATTERNS:
            if re.search(pattern, lower_text, re.IGNORECASE):
                telugu_guidance = (
                    "మీరు చాలా విలువైనవారు. దయచేసి ఒంటరిగా బాధపడకండి. సహాయం వెంటనే అందుబాటులో ఉంది. "
                    "ఉచిత Tele-MANAS హెల్ప్‌లైన్: 14416 లేదా 1800-599-0019 కి వెంటనే కాల్ చేయండి. మేము మీకు అండగా ఉన్నాము."
                )
                english_guidance = (
                    "You are not alone, and help is available right now. Please reach out to someone who can support you. "
                    "Contact the 24x7 Tele-MANAS Mental Health Helpline at 14416 or call 112 immediately."
                )
                guidance = telugu_guidance if detected_language in ["telugu", "tanglish"] else english_guidance
                return {
                    "is_safe": False,
                    "status": "crisis",
                    "category": "self_harm",
                    "reason": "Mental health crisis or self-harm expression detected.",
                    "response_guidance": guidance,
                    "helpline": cls.HELPLINES["crisis"],
                    "block_normal_routing": True
                }

        # 2. Critical Medical Emergency / Prescription Demands
        for pattern in cls.MEDICAL_CRITICAL_PATTERNS:
            if re.search(pattern, lower_text, re.IGNORECASE):
                telugu_med = (
                    "గమనిక: AVARA అనేది వైద్య నిర్ధారణ (clinical diagnosis) లేదా మందులు ఇచ్చే యాప్ కాదు. "
                    "తీవ్రమైన ఆరోగ్య సమస్యలు లేదా అత్యవసర పరిస్థితుల్లో వెంటనే 108 లేదా సమీప వైద్యులను (Doctor) సంప్రదించండి."
                )
                english_med = (
                    "Important: AVARA is a wellness companion and does NOT provide medical diagnosis or prescriptions. "
                    "In case of chest pain, severe symptoms, or emergencies, please call Ambulance 108 or visit an emergency room immediately."
                )
                guidance = telugu_med if detected_language in ["telugu", "tanglish"] else english_med
                return {
                    "is_safe": False,
                    "status": "advisory",
                    "category": "medical_emergency",
                    "reason": "Clinical medical query or emergency detected.",
                    "response_guidance": guidance,
                    "helpline": cls.HELPLINES["medical"],
                    "block_normal_routing": True
                }

        # 3. Abuse & Personal Violence
        for pattern in cls.ABUSE_PATTERNS:
            if re.search(pattern, lower_text, re.IGNORECASE):
                guidance = (
                    "మీ భద్రత చాలా ముఖ్యం. తక్షణ సహాయం కోసం నేషనల్ ఎమర్జెన్సీ 112 లేదా ఉమెన్ హెల్ప్‌లైన్ 181 / 1091 కి కాల్ చేయండి."
                    if detected_language in ["telugu", "tanglish"] else
                    "Your personal safety is paramount. For immediate help, contact National Emergency 112 or Women Helpline 181 / 1091."
                )
                return {
                    "is_safe": False,
                    "status": "crisis",
                    "category": "personal_safety",
                    "reason": "Abuse or personal safety threat detected.",
                    "response_guidance": guidance,
                    "helpline": cls.HELPLINES["abuse"],
                    "block_normal_routing": True
                }

        # 4. High-Risk Financial Speculation
        for pattern in cls.FINANCIAL_RISK_PATTERNS:
            if re.search(pattern, lower_text, re.IGNORECASE):
                guidance = (
                    "హెచ్చరిక: గ్యారెంటీ లాభాలు లేదా అనుమానాస్పద స్కీములను AVARA ప్రోత్సహించదు. "
                    "మీ ఆర్థిక నిర్ణయాల విషయంలో లైసెన్స్ పొందిన నిపుణులను సంప్రదించండి."
                    if detected_language in ["telugu", "tanglish"] else
                    "Advisory: AVARA does not endorse guaranteed return schemes or speculative financial risks. "
                    "Please consult a certified financial advisor before making high-risk decisions."
                )
                return {
                    "is_safe": False,
                    "status": "advisory",
                    "category": "financial_risk",
                    "reason": "High-risk or fraudulent financial query detected.",
                    "response_guidance": guidance,
                    "helpline": None,
                    "block_normal_routing": True
                }

        return {"is_safe": True, "status": "safe", "block_normal_routing": False}

    @classmethod
    def validate_llm_response(cls, response_text: str) -> str:
        """
        Validate generated assistant responses to ensure they do not produce
        unsupported medical cures, guaranteed financial gains, or dangerous advice.
        """
        if not response_text:
            return "I am here to assist with your personal growth, wellness, and finances."

        lower_resp = response_text.lower()

        # Disallow guaranteed medical cures
        if re.search(r"\b(i guarantee this will cure your|take this medicine to cure)\b", lower_resp):
            return (
                "Please note: For medical diagnosis and treatment, always consult a licensed medical professional. "
                "I can assist you with tracking your daily lifestyle and wellness habits."
            )

        # Disallow guaranteed financial returns
        if re.search(r"\b(100% guaranteed returns|guaranteed to double your money)\b", lower_resp):
            return (
                "Please note: Financial markets carry risk. Always verify your investments with a certified financial planner. "
                "I can help you monitor your personal budget and recorded expenses."
            )

        return response_text
