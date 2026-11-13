import 'dart:core';

/// Supported language modes for the AVARA Vedic Astrology assistant.
enum AvaraLanguageMode {
  english,
  telugu,
  tanglish,
}

/// Result returned by [LanguageValidator.validate].
class LanguageValidationResult {
  const LanguageValidationResult({
    required this.isSupported,
    required this.mode,
    required this.originalText,
    this.rejectionMessage,
    this.detectedLanguageName,
  });

  /// `true` if the input is in English, Telugu script, or Tanglish.
  final bool isSupported;

  /// The determined mode: English, Telugu script, or Tanglish.
  final AvaraLanguageMode mode;

  /// The raw input text.
  final String originalText;

  /// Human-friendly rejection message if [isSupported] is false.
  final String? rejectionMessage;

  /// Name of detected unsupported language if identified (e.g. "Hindi", "Tamil").
  final String? detectedLanguageName;

  @override
  String toString() =>
      'LanguageValidationResult(supported: $isSupported, mode: $mode, lang: $detectedLanguageName)';
}

/// Strict 3-language validator and detector for AVARA.
///
/// Accepted languages:
/// 1. English
/// 2. Telugu (native Telugu script `\u0C00-\u0C7F`)
/// 3. Telugu + English mixed (Tanglish / Telugu transliteration in Latin script)
///
/// Any other language (Hindi, Tamil, Kannada, Malayalam, etc.) is rejected with:
/// *"Sorry! AVARA currently supports only English, Telugu, and Telugu-English mixed conversations. Please ask your question in one of these languages."*
class LanguageValidator {
  LanguageValidator._();

  /// The canonical rejection message required by AVARA.
  static const String rejectionMessage =
      'Sorry! AVARA currently supports only English, Telugu, and Telugu-English mixed conversations. Please ask your question in one of these languages.';

  // ---------------------------------------------------------------------------
  // Unsupported Unicode Script Ranges
  // ---------------------------------------------------------------------------
  // Devanagari (Hindi, Marathi, Sanskrit, Nepali): U+0900 - U+097F
  // Bengali / Assamese:                           U+0980 - U+09FF
  // Gurmukhi (Punjabi):                           U+0A00 - U+0A7F
  // Gujarati:                                     U+0A80 - U+0AFF
  // Oriya (Odia):                                 U+0B00 - U+0B7F
  // Tamil:                                        U+0B80 - U+0BFF
  // Kannada:                                      U+0C80 - U+0CFF
  // Malayalam:                                    U+0D00 - U+0D7F
  // Sinhala:                                      U+0D80 - U+0DFF
  // Arabic / Urdu / Persian:                      U+0600 - U+06FF, U+0750 - U+077F, U+08A0 - U+08FF
  // Cyrillic (Russian, etc.):                     U+0400 - U+04FF
  // CJK (Chinese, Japanese, Korean):              U+4E00 - U+9FFF, U+3040 - U+30FF, U+AC00 - U+D7AF

  static bool _hasUnsupportedScript(String text) {
    for (final rune in text.runes) {
      // Devanagari (Hindi, etc.)
      if (rune >= 0x0900 && rune <= 0x097F) return true;
      // Bengali
      if (rune >= 0x0980 && rune <= 0x09FF) return true;
      // Gurmukhi
      if (rune >= 0x0A00 && rune <= 0x0A7F) return true;
      // Gujarati
      if (rune >= 0x0A80 && rune <= 0x0AFF) return true;
      // Oriya
      if (rune >= 0x0B00 && rune <= 0x0B7F) return true;
      // Tamil
      if (rune >= 0x0B80 && rune <= 0x0BFF) return true;
      // Kannada
      if (rune >= 0x0C80 && rune <= 0x0CFF) return true;
      // Malayalam
      if (rune >= 0x0D00 && rune <= 0x0D7F) return true;
      // Sinhala
      if (rune >= 0x0D80 && rune <= 0x0DFF) return true;
      // Arabic / Urdu
      if ((rune >= 0x0600 && rune <= 0x06FF) ||
          (rune >= 0x0750 && rune <= 0x077F) ||
          (rune >= 0x08A0 && rune <= 0x08FF)) {
        return true;
      }
      // Cyrillic
      if (rune >= 0x0400 && rune <= 0x04FF) return true;
      // CJK
      if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
          (rune >= 0x3040 && rune <= 0x30FF) ||
          (rune >= 0xAC00 && rune <= 0xD7AF)) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Explicit Requests for Unsupported Languages
  // ---------------------------------------------------------------------------
  static final RegExp _unsupportedLangRequest = RegExp(
    r'\b(?:in\s+)?(tamil|hindi|kannada|malayalam|bengali|marathi|gujarati|punjabi|urdu|french|spanish|german|russian|chinese|japanese|korean)(?:\s+(?:language|bhasha|la|lo|me))?\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Romanized Unsupported Language Tokens
  // ---------------------------------------------------------------------------
  // Tokens that clearly identify romanized Hindi, Tamil, Kannada, or Malayalam
  // and are NOT part of Telugu/Tanglish vocabulary.
  static final RegExp _romanizedUnsupported = RegExp(
    r'\b(?:mera|meri|mere|bhavishya|batao|bataiye|kaisa|kaisi|hoga|hogi|apna|apni|mujhko|kripya|karega|karegi|kyu|kyun|sollunga|theriyuma|epadi|irukum|enakku|ungala|solla|helu|hege|beku|gothu|parayumo|enthanu)\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Telugu Script Check (U+0C00 to U+0C7F)
  // ---------------------------------------------------------------------------
  static bool hasTeluguScript(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0C00 && rune <= 0x0C7F) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Tanglish Vocabulary & Phonetic Markers
  // ---------------------------------------------------------------------------
  static const Set<String> _tanglishTokens = {
    // Pronouns & self-references
    'naa', 'naaku', 'naku', 'nenu', 'meeru', 'miru', 'manaki', 'vaallu',
    'vallu', 'atanu', 'aame', 'idi', 'adi', 'naadi', 'meedi', 'maaku',
    // Question words
    'enti', 'emti', 'ela', 'elaaga', 'elaga', 'enduku', 'eppudu', 'epudu',
    'ekkada', 'evaru', 'entha', 'yenti', 'yemiti', 'yela',
    // Verbs & states
    'cheppandi', 'cheppu', 'kavali', 'vaddu', 'ledu', 'undhi', 'undha',
    'untundi', 'untundhi', 'unnadi', 'avuthundi', 'avtundi', 'avthundhi',
    'ayindi', 'ayyindi', 'chudandi', 'chudu', 'chusi', 'bagundi', 'bagundha',
    'telusukovali', 'unnanu', 'unnamu', 'unnaru', 'ravali', 'chesukovali',
    // Astrology & life domain markers
    'jathakam', 'jathakamu', 'raasi', 'rashi', 'nakshatram', 'nakshatramu',
    'grahalu', 'graham', 'kundali', 'kundli', 'lagnam', 'bhava', 'bhavamu',
    'dasha', 'dasa', 'mahadasha', 'muhurtham', 'dosham', 'subham', 'shubham',
    // Postpositions & linkers
    'gurinchi', 'prakaram', 'batti', 'battie', 'kante', 'tho', 'kosam',
    'lo', 'ki', 'ku', 'ani', 'kuda', 'mariyu', 'inka', 'inkaa',
  };

  /// Tokenizes string into lowercase alphanumeric words.
  static List<String> _tokenize(String text) {
    return RegExp(r'[a-zA-Z]+')
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
  }

  /// Detects and validates the language of the incoming [text].
  static LanguageValidationResult validate(String text) {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const LanguageValidationResult(
        isSupported: true,
        mode: AvaraLanguageMode.english,
        originalText: '',
      );
    }

    // 1. Check for non-Telugu unsupported scripts (Devanagari, Tamil, etc.)
    if (_hasUnsupportedScript(clean)) {
      return LanguageValidationResult(
        isSupported: false,
        mode: AvaraLanguageMode.english,
        originalText: text,
        rejectionMessage: rejectionMessage,
        detectedLanguageName: 'Unsupported Script',
      );
    }

    // 2. Check for explicit unsupported language requests ("Explain in Tamil", etc.)
    final requestMatch = _unsupportedLangRequest.firstMatch(clean);
    if (requestMatch != null) {
      final lang = requestMatch.group(1);
      return LanguageValidationResult(
        isSupported: false,
        mode: AvaraLanguageMode.english,
        originalText: text,
        rejectionMessage: rejectionMessage,
        detectedLanguageName: lang,
      );
    }

    // 3. Check for romanized unsupported language tokens (e.g. "mera bhavishya batao")
    if (_romanizedUnsupported.hasMatch(clean)) {
      return LanguageValidationResult(
        isSupported: false,
        mode: AvaraLanguageMode.english,
        originalText: text,
        rejectionMessage: rejectionMessage,
        detectedLanguageName: 'Unsupported Romanized Language',
      );
    }

    // 4. Native Telugu script check
    final hasTelugu = hasTeluguScript(clean);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(clean);

    if (hasTelugu && !hasLatin) {
      // Pure Telugu script
      return LanguageValidationResult(
        isSupported: true,
        mode: AvaraLanguageMode.telugu,
        originalText: text,
      );
    }

    if (hasTelugu && hasLatin) {
      // Mixed Telugu script + English characters
      return LanguageValidationResult(
        isSupported: true,
        mode: AvaraLanguageMode.tanglish,
        originalText: text,
      );
    }

    // 5. Pure Latin script: determine if Tanglish or English
    final tokens = _tokenize(clean);
    int tanglishMatches = 0;
    for (final t in tokens) {
      if (_tanglishTokens.contains(t)) {
        tanglishMatches++;
      }
    }

    // If any distinct Tanglish marker is found, classify as Tanglish
    if (tanglishMatches > 0) {
      return LanguageValidationResult(
        isSupported: true,
        mode: AvaraLanguageMode.tanglish,
        originalText: text,
      );
    }

    // Default to English
    return LanguageValidationResult(
      isSupported: true,
      mode: AvaraLanguageMode.english,
      originalText: text,
    );
  }

  /// Returns a friendly prompt asking for birth details in the given language mode.
  static String getPromptForBirthDetails(
    AvaraLanguageMode mode, {
    bool timeMissing = false,
    bool isLagnaOrHouse = false,
  }) {
    if (timeMissing || isLagnaOrHouse) {
      switch (mode) {
        case AvaraLanguageMode.telugu:
          return 'వేద జ్యోతిష్యం ప్రకారం లగ్నం (Ascendant) మరియు భావాలు ప్రతి రెండు గంటలకు ఒక రాశి మారుతాయి. ఖచ్చితమైన లగ్నం గణించడానికి మీ పుట్టిన సమయం (TOB) తప్పనిసరి. దయచేసి మీ పుట్టిన సమయం తెలపండి. (గమనిక: ఖచ్చితమైన సమయం లేకుండా చంద్ర రాశి మరియు గ్రహ స్థితులను మాత్రమే గణించవచ్చు).';
        case AvaraLanguageMode.tanglish:
          return 'Vedic astrology prakaram Lagna (Ascendant) mariyu bhavas prathi 2 hours ki maaruthaayi. Accurate Lagna calculation kosam exact Time of Birth (TOB) avasaram. Please mee birth time telisthe share cheyandi. (Note: Birth time lekunda Chandra Rashi mariyu general planetary positions maatrame cheppavachhu).';
        case AvaraLanguageMode.english:
          return 'In Vedic astrology, your Lagna (Ascendant) and house placements change signs approximately every two hours. An exact Time of Birth (TOB) is required to calculate your Lagna accurately. Please provide your birth time if available. (Note: Your Moon sign and general planetary placements can still be calculated for the day).';
      }
    }

    switch (mode) {
      case AvaraLanguageMode.telugu:
        return 'మీ వేద జన్మ కుండలి ఆధారంగా దీనిని పరిశీలించడానికి, దయచేసి మీ పుట్టిన వివరాలు తెలియజేయండి:\n\n'
            '- పుట్టిన తేదీ (DOB - రోజు/నెల/సంవత్సరం)\n'
            '- ఖచ్చితమైన పుట్టిన సమయం (TOB)\n'
            '- పుట్టిన ప్రదేశం (POB - నగరం, దేశం)';
      case AvaraLanguageMode.tanglish:
        return "Mee Vedic birth chart ni chusi accurate ga cheppadaniki, please mee birth details share cheyandi:\n\n"
            "- Date of Birth (DOB)\n"
            "- Exact Time of Birth (TOB)\n"
            "- Place of Birth (POB - city and country)";
      case AvaraLanguageMode.english:
        return "I'd love to explore that through your Vedic birth chart. Please share your birth details:\n\n"
            "- Date of Birth (DOB)\n"
            "- Exact Time of Birth (TOB)\n"
            "- Place of Birth (POB – city and country)";
    }
  }
}
