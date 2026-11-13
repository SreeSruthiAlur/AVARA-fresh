import 'package:avara_astrology_trial/services/birth_details_parser.dart';

/// The category of query detected by [AstrologyIntentClassifier].
enum AstrologyIntentType {
  /// Safety violation (medical condition, mortality, disease, lifespan).
  safetyViolation,

  /// Question about the user's specific birth chart, requiring birth details.
  personalAstrology,

  /// General educational or conceptual question, answered directly.
  generalEducational,

  /// Message contains birth details (DOB, TOB, POB).
  birthDetailsSubmission,

  /// Conversational greeting or non-astrology statement.
  conversational,
}

/// Classifies user messages into personal astrology, general educational,
/// or safety violations (medical & mortality).
class AstrologyIntentClassifier {
  AstrologyIntentClassifier._();

  /// Strict response required when a medical or mortality safety violation is detected.
  static const String safetyResponse =
      'I am an astrology guide, not a medical professional. I cannot predict health conditions, diseases, lifespan, or mortality. Please consult a qualified doctor for any medical concerns.';

  // ---------------------------------------------------------------------------
  // Safety Interceptor Patterns: Medical & Mortality
  // ---------------------------------------------------------------------------

  /// Scans for English medical/mortality terms: die, death, disease, health, cancer, etc.
  static final RegExp _englishMedicalMortalityPattern = RegExp(
    r'\b(?:die|dying|death|dead|dies|lifespan|life\s*span|life\s*expectancy|longevity|mortality|suicide|kill|illness|illnesses|sick|sickness|disease|diseases|health|health\s+issues?|health\s+problems?|health\s+conditions?|medical|medicine|medicines|hospital|doctor|surgery|treatment|tumor|heart\s*attack|infection|cure)\b',
    caseSensitive: false,
  );

  /// Scans for Tanglish medical/mortality terms: chachipothana, chavu, vyadhi, rogan, etc.
  static final RegExp _tanglishMedicalMortalityPattern = RegExp(
    r'\b(?:chachipothana|chachipotana|chachipotha|chachipothanu|chastana|chasta|chastanu|chavutana|chavu|chaavu|chanipothana|chanipotana|chanipotha|chanipothanu|maranam|marana|aayushu|ayushu|aayush|ayush|vyadhi|vyadhulu|roga|rogam|rogan|rogamu|rogalu|anarogyam|mandulu|chikitsa|treatment|doctor|operation)\b',
    caseSensitive: false,
  );

  /// Helper to check if "cancer" in [text] refers to the medical disease vs zodiac sign.
  /// Rule: "If the user asks about 'cancer', assume they mean the disease unless context strictly implies the zodiac sign."
  static bool _isCancerDisease(String text) {
    final lower = text.toLowerCase();
    if (!RegExp(r'\bcancer\b').hasMatch(lower)) return false;

    // If explicit medical or illness context accompanies cancer:
    if (RegExp(
      r'\b(?:have|has|had|got|cure|treat|treatment|patient|stage|breast|lung|blood|colon|skin|terminal|suffer|suffering|diagnos\w*|disease|illness|pain|chemo|kill|die|death)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    // Strict astrological context patterns where "cancer" refers strictly to the zodiac sign:
    final strictZodiacPattern = RegExp(
      r'(?:cancer\s+(?:sign|zodiac|rashi|raasi|lagna|ascendant)|(?:zodiac|sign|rashi|raasi|lagna|ascendant)\s+(?:of\s+)?cancer|(?:sun|moon|mars|mercury|jupiter|venus|saturn|rahu|ketu)\s+in\s+cancer)',
      caseSensitive: false,
    );

    // If context strictly implies the zodiac sign:
    if (strictZodiacPattern.hasMatch(lower)) {
      return false;
    }

    // Default: Assume "cancer" refers to the disease
    return true;
  }

  /// Scans for Tanglish multi-word medical/mortality phrases.
  static bool _hasTanglishHealthIssue(String text) {
    final lower = text.toLowerCase();
    return lower.contains('health issue') ||
        lower.contains('health problem') ||
        lower.contains('aarogyam baledu') ||
        lower.contains('arogyam baledu') ||
        lower.contains('chavu eppudu') ||
        lower.contains('chaavu eppudu');
  }

  /// Scans for Telugu script medical and mortality terms.
  static bool _hasTeluguMedicalMortality(String text) {
    return text.contains('క్యాన్సర్') ||
        text.contains('చనిపోతానా') ||
        text.contains('చనిపోతా') ||
        text.contains('చస్తానా') ||
        text.contains('చస్తాను') ||
        text.contains('చావు') ||
        text.contains('మరణం') ||
        text.contains('మరణిస్తానా') ||
        text.contains('ఆయుష్షు') ||
        text.contains('ఆయుషు') ||
        text.contains('వ్యాధి') ||
        text.contains('వ్యాధులు') ||
        text.contains('రోగం') ||
        text.contains('రోగాలు') ||
        text.contains('రోగాన్') ||
        text.contains('అనారోగ్యం') ||
        text.contains('ఆరోగ్య సమస్య') ||
        text.contains('ఆరోగ్యం బాగాలేదు') ||
        text.contains('వైద్యం') ||
        text.contains('డాక్టర్') ||
        text.contains('చికిత్స') ||
        text.contains('మందులు');
  }

  /// Evaluates whether [message] violates safety guidelines by asking about
  /// medical conditions, diseases, lifespan, or mortality in English, Telugu, or Tanglish.
  static bool isSafetyViolation(String message) {
    final clean = message.trim();
    if (clean.isEmpty) return false;

    // 1. Cancer check (disease vs zodiac sign)
    if (_isCancerDisease(clean)) {
      return true;
    }

    // 2. English medical & mortality check
    if (_englishMedicalMortalityPattern.hasMatch(clean)) {
      return true;
    }

    // 3. Tanglish medical & mortality check
    if (_tanglishMedicalMortalityPattern.hasMatch(clean) ||
        _hasTanglishHealthIssue(clean)) {
      return true;
    }

    // 4. Telugu script medical & mortality check
    if (_hasTeluguMedicalMortality(clean)) {
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Patterns for General Educational Queries
  // ---------------------------------------------------------------------------
  // Must NOT contain personal pronouns ("my", "naa", "naaku", "నా", etc.)
  static final RegExp _generalPattern = RegExp(
    r'^\s*(?:what\s+is\s+(?:a|an|the)\b|what\s+are\s+(?:the\b)?|explain\b|difference\s+between\b|meaning\s+of\b|define\b|how\s+does\b|who\s+is\s+the\s+lord\s+of\b|tell\s+me\s+about\s+(?:the\b)?(?!(?:my|our)\b))',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Patterns for Personal Pronouns & Self-References
  // ---------------------------------------------------------------------------
  static final RegExp _personalPronounPattern = RegExp(
    r'\b(?:my|mine|me|myself|i|am\s+i|will\s+i|can\s+i|should\s+i|naa|naaku|naku|nenu|naadi|maaku)\b',
    caseSensitive: false,
  );

  static bool _hasTeluguPersonalPronoun(String text) {
    return text.contains('నా') ||
        text.contains('నాకు') ||
        text.contains('నన్ను') ||
        text.contains('నేను') ||
        text.contains('నాది') ||
        text.contains('మాకు');
  }

  static bool _hasTeluguAstrologyDomain(String text) {
    return text.contains('జాతకం') ||
        text.contains('కుండలి') ||
        text.contains('రాశి') ||
        text.contains('నక్షత్రం') ||
        text.contains('లగ్నం') ||
        text.contains('గ్రహాలు') ||
        text.contains('దశ') ||
        text.contains('మహర్దశ') ||
        text.contains('వివాహం') ||
        text.contains('కెరీర్') ||
        text.contains('భవిష్యత్తు');
  }

  // ---------------------------------------------------------------------------
  // Personal Query Keywords (Lagna, Nakshatra, Houses, Career, Marriage, etc.)
  // ---------------------------------------------------------------------------
  static final RegExp _personalDomainPattern = RegExp(
    r'(?:moon\s*sign|janma\s*nakshatra|nakshatra|lagna|ascendant|rashi|raasi|kundali|kundli|horoscope|(?:birth\s*)?chart|jathakam|jathakamu|mahadasha|dasha|dasa|7th\s*house|10th\s*house|house|bhavas?|marriage|career|future|emotions|personality|relationships?|strengths?|weaknesses?)',
    caseSensitive: false,
  );

  /// Classifies [text] into an [AstrologyIntentType].
  ///
  /// Short-circuits immediately with [AstrologyIntentType.safetyViolation] if
  /// [isSafetyViolation] returns `true`.
  static AstrologyIntentType classify(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return AstrologyIntentType.conversational;

    // 0. Safety Interceptor: Medical & Mortality short-circuit
    if (isSafetyViolation(clean)) {
      return AstrologyIntentType.safetyViolation;
    }

    // 1. Check if the message provides birth details (has at least a date and place or time)
    final parsed = BirthDetailsParser.parse(clean);
    if (parsed.hasDate && (parsed.hasTime || parsed.hasPlace)) {
      return AstrologyIntentType.birthDetailsSubmission;
    }

    final hasPersonalPronoun = _personalPronounPattern.hasMatch(clean);

    // 2. Check if it's an explicit general educational question without personal pronoun
    // e.g. "What is a Nakshatra?", "What is the difference between Rashi and Lagna?"
    if (_generalPattern.hasMatch(clean) && !hasPersonalPronoun) {
      return AstrologyIntentType.generalEducational;
    }

    // 3. Check for personal queries
    // e.g. "What does my Moon sign say...", "What is my Lagna?", "What is my Nakshatra?"
    // "Naaku naa marriage gurinchi cheppu", "నా జాతకం గురించి చెప్పండి", "Naa Rashi enti?"
    // "What about my relationships?", "Tell me about my 7th house", "What is my current Mahadasha?"
    if (hasPersonalPronoun && _personalDomainPattern.hasMatch(clean)) {
      return AstrologyIntentType.personalAstrology;
    }

    // Telugu script personal astrology checks
    if (_hasTeluguAstrologyDomain(clean)) {
      if (_hasTeluguPersonalPronoun(clean) ||
          clean.contains('చెప్పండి') ||
          clean.contains('చెప్పు') ||
          clean.contains('చూడండి') ||
          clean.contains('గురించి') ||
          clean.contains('ఎలా')) {
        return AstrologyIntentType.personalAstrology;
      }
    }

    // Follow-ups without explicit "my", e.g. "What about relationships?", "Tell me about 7th house"
    final isFollowupPersonal = RegExp(
      r'^\s*(?:what\s+about\s+(?:my\s+)?relationships|tell\s+me\s+about\s+(?:my\s+)?(?:the\s+)?\d+(?:st|nd|rd|th)?\s+house|what\s+is\s+my\s+current\s+mahadasha)\b',
      caseSensitive: false,
    ).hasMatch(clean);

    if (isFollowupPersonal) {
      return AstrologyIntentType.personalAstrology;
    }

    // Chart visualization requests (e.g. "show my chart", "see my kundli", "generate my jathakam")
    final isChartRequest = RegExp(
      r'\b(?:show|see|view|generate|display|draw)\b.*\b(?:kundli|kundali|chart|jathakam|jathakamu)\b',
      caseSensitive: false,
    ).hasMatch(clean);

    if (isChartRequest) {
      return AstrologyIntentType.personalAstrology;
    }

    // Telugu/Tanglish phrases without explicit pronoun like "jathakam cheppandi", "kundali chudandi"
    if (RegExp(r'\b(?:jathakam|kundali|raasi|rashi|nakshatram)\b', caseSensitive: false).hasMatch(clean) &&
        (clean.contains('నా') || clean.contains('naa') || clean.contains('naaku') || clean.contains('cheppu') || clean.contains('cheppandi'))) {
      return AstrologyIntentType.personalAstrology;
    }

    // If it has general markers without personal references:
    if (clean.toLowerCase().startsWith('what is') ||
        clean.toLowerCase().startsWith('what are') ||
        clean.toLowerCase().startsWith('explain') ||
        clean.toLowerCase().startsWith('describe how')) {
      return AstrologyIntentType.generalEducational;
    }

    return AstrologyIntentType.conversational;
  }
}
