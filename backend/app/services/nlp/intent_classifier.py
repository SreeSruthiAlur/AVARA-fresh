import re
from typing import Dict, Any, List
from app.services.nlp.language_detector import detect_language
from app.services.nlp.normalizer import normalize_text
from app.services.nlp.safety_guard import SafetyGuard

class IntentClassifier:
    """
    Multilingual Intent Classifier & Router.
    Recognizes intents across Telugu, English, Tanglish, and Mixed inputs.
    Routes to Teammate 1 modules (Astrology, Habits, Insights) or
    Teammate 2 modules (Finance, Health, Astrologers, Profile) without datasets.
    """

    INTENT_PATTERNS = {
        # 1. Astrology (Teammate 1 responsibility)
        "astrology": [
            # English
            r"\b(astrology|horoscope|zodiac|birth\s*chart|kundali|natal\s*chart|sun\s*sign|moon\s*sign|planetary|graha|raasi|nakshatra|saturn|jupiter|mars|mercury)\b",
            # Telugu Script
            r"(జ్యోతిష్యం|జాతకం|రాశి|నక్షత్రం|గ్రహాలు|కుండలి|రాశిఫలాలు|గ్రహచారము|శని|గురు|కుజ)",
            # Tanglish
            r"\b(jathakam|jathakamu|raasi|rasi|nakshatram|grahalu|kundali|graha\s*shanti|subha\s*muhurtham|horoscope)\b"
        ],

        # 2. Habits (Teammate 1 responsibility)
        "habits": [
            # English
            r"\b(habit|habits|streak|routine|daily\s*task|habit\s*tracker|consistency|track\s*my\s*habit|completed\s*today|habit\s*streak)\b",
            # Telugu Script
            r"(అలవాటు|అలవాట్లు|రోజువారీ\s*పని|క్రమశిక్షణ|స్ట్రీక్)",
            # Tanglish
            r"\b(alavatu|alavatlu|daily\s*routine|prathi\s*roju\s*cheyali|habit\s*complete|streak)\b"
        ],

        # 3. Insights (Teammate 1 responsibility)
        "insights": [
            # English
            r"\b(insight|insights|pattern|patterns|reflection|growth\s*summary|progress\s*observation|how\s*am\s*i\s*progressing|weekly\s*reflection)\b",
            # Telugu Script
            r"(అంతర్దృష్టి|పురోగతి|పరిశీలనలు|గ్రోత్\s*సమ్మరీ|నా\s*ప్రోగ్రెస్|వీక్లీ\s*సమ్మరీ)",
            # Tanglish
            r"\b(progress\s*chudali|naa\s*growth|pattern\s*enti|insights\s*cheppandi|reflection)\b"
        ],

        # 4. Finance (Teammate 2 responsibility)
        "finance": [
            # English
            r"\b(finance|expense|expenses|spend|spent|spending|budget|money|cost|rupees|rs|cash|payment|upi|bill|bills|purchase|bought|saving|savings|transaction)\b",
            # Telugu Script
            r"(ఖర్చు|ఖర్చులు|బడ్జెట్|డబ్బులు|డబ్బు|రూపాయలు|పేమెంట్|యూపీఐ|ఎంత\s*ఖర్చయింది|సేవింగ్స్|బిల్లులు|కొన్నాను)",
            # Tanglish
            r"\b(kharchu|kharchulu|karchu|karchulu|dabbu|dabbulu|budget|rupailu|rupayalu|spent\s*ayindi|entha\s*karchu|migilindi)\b"
        ],

        # 5. Health & Wellness (Teammate 2 responsibility)
        "health": [
            # English
            r"\b(health|wellness|mood|energy|sleep|slept|workout|exercise|activity|walk|steps|tired|stressed|happy|sad|feeling\s*down|wellness\s*note)\b",
            # Telugu Script
            r"(ఆరోగ్యం|వెల్నెస్|మూడ్|నిద్ర|శక్తి|అలసట|వ్యాయామం|వాకింగ్|ఒత్తిడి|సంతోషం|బాధ|నీరసం)",
            # Tanglish
            r"\b(aarogyam|arogyam|nidra|alasata|shakthi|mood\s*ela\s*undi|stress\s*ga\s*undi|tired\s*ga\s*undi|exercise|walk)\b"
        ],

        # 6. Astrologer Discovery (Teammate 2 responsibility)
        "astrologer_discovery": [
            # English
            r"\b(find\s*astrologer|list\s*(of\s*)?.*astrologer|astrologer\s*directory|top\s*astrologers|best\s*pandit|astrology\s*expert|astrologers|astrologer|pandit)\b",
            # Telugu Script
            r"(జ్యోతిష్యులు|జ్యోతిష్కులు|పండితులు|మంచి\s*జ్యోతిష్యుడిని\s*చూపించు|లిస్ట్\s*చూపించు)",
            # Tanglish
            r"\b(astrologers\s*list|pandit\s*chudali|evaru\s*unnaru\s*astrologers|astrologer\s*directory)\b"
        ],

        # 7. Consultation Booking (Teammate 2 responsibility)
        "consultation_booking": [
            # English
            r"\b(book\s*consultation|book\s*appointment|schedule\s*consultation|booking|reserve\s*slot|book\s*astrologer|consultation)\b",
            # Telugu Script
            r"(బుకింగ్|అపాయింట్‌మెంట్\s*బుక్|స్లాట్\s*బుక్|సంప్రదింపు\s*బుక్)",
            # Tanglish
            r"\b(book\s*cheyali|booking\s*kavali|appointment\s*theesukovali|slot\s*book)\b"
        ],

        # 8. Profile & Settings Management (Teammate 2 responsibility)
        "profile_management": [
            # English
            r"\b(profile|my\s*account|settings|change\s*password|update\s*profile|preferred\s*language|edit\s*profile|privacy\s*settings)\b",
            # Telugu Script
            r"(ప్రొఫైల్|నా\s*ఖాతా|సెట్టింగ్స్|పాస్‌వర్డ్\s*మార్చు|భాష\s*మార్చు|ప్రైవసీ)",
            # Tanglish
            r"\b(naa\s*profile|settings\s*marchali|password\s*change|language\s*marchali|profile\s*update)\b"
        ],

        # 9. General Conversation
        "general_conversation": [
            # English
            r"\b(hello|hi|hey|good\s*morning|good\s*evening|how\s*are\s*you|who\s*are\s*you|what\s*can\s*you\s*do|thank\s*you|thanks|help|welcome)\b",
            # Telugu Script
            r"(నమస్కారం|నమస్తే|బాగున్నారా|ఎలా\s*ఉన్నారు|నువ్వు\s*ఎవరు|ఏం\s*చేయగలవు|ధన్యవాదాలు|సహాయం)",
            # Tanglish
            r"\b(namaskaram|namaste|ela\s*unnav|ela\s*unnaru|bagunnara|evaru\s*nuvvu|enti\s*sangathi|dhanyavadalu|thanks)\b"
        ]
    }

    # Module routing map
    ROUTE_TARGET_MAP = {
        "astrology": "teammate1_astrology",
        "habits": "teammate1_habits",
        "insights": "teammate1_insights",
        "finance": "finance",
        "health": "health",
        "astrologer_discovery": "astrologers",
        "consultation_booking": "astrologers",
        "profile_management": "profile",
        "general_conversation": "general",
        "safety_sensitive": "safety",
        "unknown_ambiguous": "clarification"
    }

    @classmethod
    def classify_and_route(cls, text: str) -> Dict[str, Any]:
        """
        Classifies the text intent and determines module routing target.
        Runs safety checks first.
        """
        # Step 1: Detect Language
        lang_info = detect_language(text)
        detected_lang = lang_info["detected_language"]

        # Step 2: Normalize
        normalized = normalize_text(text)

        # Step 3: Safety Guard (MANDATORY BEFORE INTENT ROUTING)
        safety_eval = SafetyGuard.evaluate_input_safety(normalized, detected_language=detected_lang)
        if not safety_eval["is_safe"]:
            return {
                "original_text": text,
                "normalized_text": normalized,
                "language_info": lang_info,
                "intent": "safety_sensitive",
                "confidence": 1.0,
                "target_module": cls.ROUTE_TARGET_MAP["safety_sensitive"],
                "safety_evaluation": safety_eval,
                "needs_clarification": False,
                "clarifying_question": None
            }

        # Step 4: Intent Pattern Matching
        scores: Dict[str, float] = {}
        for intent, patterns in cls.INTENT_PATTERNS.items():
            intent_score = 0
            for pat in patterns:
                matches = len(re.findall(pat, normalized, re.IGNORECASE))
                if matches > 0:
                    intent_score += matches
            if intent_score > 0:
                scores[intent] = intent_score

        # Determine winner
        if not scores:
            # Ambiguous or unknown intent -> ask clarifying question
            clarifying_question = cls._generate_clarifying_question(detected_lang)
            return {
                "original_text": text,
                "normalized_text": normalized,
                "language_info": lang_info,
                "intent": "unknown_ambiguous",
                "confidence": 0.4,
                "target_module": cls.ROUTE_TARGET_MAP["unknown_ambiguous"],
                "safety_evaluation": safety_eval,
                "needs_clarification": True,
                "clarifying_question": clarifying_question
            }

        best_intent = max(scores, key=scores.get)
        confidence = min(0.96, round(0.70 + (scores[best_intent] * 0.10), 2))

        return {
            "original_text": text,
            "normalized_text": normalized,
            "language_info": lang_info,
            "intent": best_intent,
            "confidence": confidence,
            "target_module": cls.ROUTE_TARGET_MAP.get(best_intent, "general"),
            "safety_evaluation": safety_eval,
            "needs_clarification": False,
            "clarifying_question": None
        }

    @staticmethod
    def _generate_clarifying_question(language: str) -> str:
        """Generate language-aware clarifying questions."""
        if language == "telugu":
            return (
                "క్షమించండి, మీ అభ్యర్థన స్పష్టంగా లేదు. మీరు ఖర్చులు (Finance), ఆరోగ్యం (Health), "
                "జ్యోతిష్యులు (Astrologers), లేదా ఇతర సేవల గురించి తెలుసుకోవాలనుకుంటున్నారా? దయచేసి వివరంగా చెప్పండి."
            )
        elif language == "tanglish":
            return (
                "Kshaminchandi, mee request clear ga ledu. Meeru Finance (kharchulu), Health (aarogyam), "
                "Astrologers, or vere vishayam gurinchi aduguthunnara? Koncham detail ga cheppandi."
            )
        else:
            return (
                "Could you please clarify your request? Are you looking for assistance with Finance & Expenses, "
                "Health & Wellness, Astrologer consultations, or general guidance?"
            )
