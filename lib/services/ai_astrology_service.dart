import 'dart:async';
import 'dart:convert';

import 'package:avara_astrology_trial/services/astrology_intent_classifier.dart';
import 'package:avara_astrology_trial/services/avara_geocoder.dart';
import 'package:avara_astrology_trial/services/birth_details_parser.dart';
import 'package:avara_astrology_trial/services/birth_profile_manager.dart';
import 'package:avara_astrology_trial/services/language_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Callback typedef
// ---------------------------------------------------------------------------

/// Platform-provided callback that runs the Swiss Ephemeris math engine.
///
/// [year], [month], [day] are the **UTC** date components (already adjusted
/// from the local IST birth time).  [hourUtc] is the decimal UTC hour
/// (e.g. 8.5 = 08:30 UTC).  [lat] / [lon] are WGS-84 geocoded coordinates.
///
/// Returns the full kundali [Map] produced by [TeluguKundaliCalculator].
typedef ChartGeneratorCallback = Future<Map<String, dynamic>> Function({
  required int year,
  required int month,
  required int day,
  required double hourUtc,
  required double lat,
  required double lon,
});

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// AVARA's Groq-powered Vedic Astrology conversational engine (GPT-OSS 20B).
///
/// Strictly adheres to:
/// 1. Traditional Indian Vedic Astrology (Sidereal Nirayana, Lahiri Ayanamsa).
/// 2. Three accepted language modes (English, Telugu script, and Tanglish / Telugu transliteration).
/// 3. Rejection of unsupported languages (Hindi, Tamil, Kannada, Malayalam, etc.).
/// 4. Personalized astrology using calculated birth chart data (no generic 12-sign dumps).
/// 5. Persistent storage and reuse of birth details.
/// 6. Full conversation history and context awareness across multiple turns.
class AIAstrologyService {
  // -------------------------------------------------------------------------
  // Per-POST timeout
  // -------------------------------------------------------------------------

  static const Duration _kTimeout = Duration(seconds: 15);

  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  final String _apiKey;
  final ChartGeneratorCallback? _chartGenerator;

  /// Expose the callback if provided.
  ChartGeneratorCallback? get chartGenerator => _chartGenerator;

  /// The most recently computed kundali, populated after [preloadChart] or
  /// calculated from user birth details.
  Map<String, dynamic>? _chartJson;

  /// Expose the current chart so the UI can react.
  Map<String, dynamic>? get chartJson => _chartJson;

  /// Multi-turn conversation history sent to Groq completions API.
  final List<Map<String, String>> _conversationHistory = [];

  /// Tracks the most recent personal question if user had to be prompted for DOB.
  String? _lastPendingPersonalQuestion;

  /// Whether the currently loaded chart includes an exact birth time.
  bool _hasBirthTime = true;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  AIAstrologyService({
    required String apiKey,
    this._chartGenerator,
  }) : _apiKey = apiKey.trim().replaceAll('"', '').replaceAll("'", '') {
    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('DEBUG API KEY: is EMPTY — dotenv did not load GROQ_API_KEY.');
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Pre-loads an already-computed kundali into the service.
  void preloadChart(Map<String, dynamic> chartJson, {bool hasExactTime = true}) {
    _chartJson = chartJson;
    _hasBirthTime = hasExactTime;
    BirthProfileManager.instance.setChart(chartJson);
  }

  /// Sends [userPrompt] to AVARA and returns the text response.
  Future<String> sendMessage(String userPrompt) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      return '';
    }

    try {
      // 1. Strict Language Restriction Check
      final langResult = LanguageValidator.validate(cleanPrompt);
      if (!langResult.isSupported) {
        return langResult.rejectionMessage ?? LanguageValidator.rejectionMessage;
      }

      // 2. Safety Interceptor Check (Medical & Mortality)
      if (AstrologyIntentClassifier.isSafetyViolation(cleanPrompt)) {
        return AstrologyIntentClassifier.safetyResponse;
      }

      // 3. Check if the user message provides birth details (DOB, TOB, POB)
      final parsedBirth = BirthDetailsParser.parse(cleanPrompt);
      final providesBirthInfo = parsedBirth.hasDate && (parsedBirth.hasPlace || parsedBirth.hasTime);

      if (providesBirthInfo) {
        return await _handleBirthDetailsSubmission(
          userPrompt: cleanPrompt,
          parsedBirth: parsedBirth,
          langMode: langResult.mode,
        );
      }

      // 4. Classify intent: Personal Astrology vs General Educational vs Conversational
      final intent = AstrologyIntentClassifier.classify(cleanPrompt);

      if (intent == AstrologyIntentType.safetyViolation) {
        return AstrologyIntentClassifier.safetyResponse;
      }

      if (intent == AstrologyIntentType.personalAstrology) {
        return await _handlePersonalAstrologyQuery(
          userPrompt: cleanPrompt,
          langMode: langResult.mode,
        );
      }

      // 4. General educational or conversational query (e.g. "What is a Nakshatra?")
      return await _handleGeneralQuery(
        userPrompt: cleanPrompt,
        langMode: langResult.mode,
      );
    } on TimeoutException {
      return 'Network timeout. Please check your connection and try your question again.';
    } on AIAstrologyException {
      rethrow;
    } catch (e) {
      throw AIAstrologyException('Unexpected error while contacting AVARA: $e');
    }
  }

  /// Clears chat history and active chart session.
  void clearHistory() {
    _chartJson = null;
    _conversationHistory.clear();
    _lastPendingPersonalQuestion = null;
    _hasBirthTime = true;
  }

  // -------------------------------------------------------------------------
  // Core Handlers
  // -------------------------------------------------------------------------

  /// Handles incoming birth details, calculates Vedic chart, persists it,
  /// and responds to any pending question.
  Future<String> _handleBirthDetailsSubmission({
    required String userPrompt,
    required ParsedBirthDetails parsedBirth,
    required AvaraLanguageMode langMode,
  }) async {
    // Check if birth time is missing and the user was asking for Lagna or house placement
    final isLagnaQuery = _isLagnaOrHouseQuery(userPrompt) ||
        _isLagnaOrHouseQuery(_lastPendingPersonalQuestion ?? '');

    if (!parsedBirth.hasTime && isLagnaQuery) {
      return LanguageValidator.getPromptForBirthDetails(
        langMode,
        timeMissing: true,
        isLagnaOrHouse: true,
      );
    }

    if (_chartGenerator == null || !parsedBirth.hasDate || !parsedBirth.hasPlace) {
      // Incomplete birth details
      return LanguageValidator.getPromptForBirthDetails(langMode);
    }

    // Geocode birth place
    final placeName = parsedBirth.place!;
    final geo = await AvaraGeocoder.geocode(placeName);

    // Convert local time (default IST 5.5) to UTC decimal hour
    final hour = parsedBirth.hasTime ? parsedBirth.hour! : 12; // 12 noon fallback
    final minute = parsedBirth.hasTime ? parsedBirth.minute! : 0;

    final localMinutes = hour * 60 + minute;
    const offsetMinutes = 330; // 5.5 hours IST
    int utcMinutes = localMinutes - offsetMinutes;
    int dayDelta = 0;
    while (utcMinutes < 0) {
      utcMinutes += 24 * 60;
      dayDelta -= 1;
    }
    while (utcMinutes >= 24 * 60) {
      utcMinutes -= 24 * 60;
      dayDelta += 1;
    }
    final hourDecimal = (utcMinutes ~/ 60) + (utcMinutes % 60) / 60.0;

    var year = parsedBirth.year!;
    var month = parsedBirth.month!;
    var day = parsedBirth.day!;
    if (dayDelta != 0) {
      final adjusted =
          DateTime.utc(year, month, day).add(Duration(days: dayDelta));
      year = adjusted.year;
      month = adjusted.month;
      day = adjusted.day;
    }

    // Calculate Vedic chart using Swiss Ephemeris
    final chart = await _chartGenerator(
      year: year,
      month: month,
      day: day,
      hourUtc: hourDecimal,
      lat: geo.latitude,
      lon: geo.longitude,
    );

    _chartJson = chart;
    _hasBirthTime = parsedBirth.hasTime;

    // Persist details to SharedPreferences and backend
    await BirthProfileManager.instance.saveBirthDetails(
      birthDate: parsedBirth.isoDate!,
      birthTime: parsedBirth.hasTime ? parsedBirth.formattedTime! : '',
      birthPlace: geo.displayName,
      chartJson: chart,
    );

    // Determine the question to answer: pending question or current prompt
    final pending = _lastPendingPersonalQuestion;
    _lastPendingPersonalQuestion = null;

    final queryToAnswer = (pending != null && pending.isNotEmpty)
        ? pending
        : (_isSpecificQuestion(userPrompt) ? userPrompt : null);

    if (queryToAnswer != null) {
      return await _generatePersonalizedResponse(
        userPrompt: queryToAnswer,
        langMode: langMode,
        chart: chart,
      );
    }

    // If user provided birth details without asking a specific question,
    // provide an introductory chart summary.
    return _buildChartIntroResponse(chart, langMode);
  }

  /// Handles personal astrology questions (Moon sign, Lagna, Nakshatra, Houses, Mahadasha, etc.)
  Future<String> _handlePersonalAstrologyQuery({
    required String userPrompt,
    required AvaraLanguageMode langMode,
  }) async {
    // 1. Check if chart is already in memory
    if (_chartJson == null) {
      // 2. Check if stored in BirthProfileManager / SharedPreferences
      final stored = await BirthProfileManager.instance.loadBirthDetails();
      if (stored != null) {
        if (BirthProfileManager.instance.cachedChart != null) {
          _chartJson = BirthProfileManager.instance.cachedChart;
          _hasBirthTime = (stored['birth_time'] ?? '').isNotEmpty;
        } else if (_chartGenerator != null) {
          await _recalculateFromStored(stored);
        }
      }
    }

    // 3. If chart is STILL not available, prompt user for DOB, TOB, POB
    if (_chartJson == null) {
      _lastPendingPersonalQuestion = userPrompt;
      return LanguageValidator.getPromptForBirthDetails(langMode);
    }

    // 4. If user is asking for Lagna and birth time was missing, explain requirement
    if (_isLagnaOrHouseQuery(userPrompt) && !_hasBirthTime) {
      return LanguageValidator.getPromptForBirthDetails(
        langMode,
        timeMissing: true,
        isLagnaOrHouse: true,
      );
    }

    // 5. Generate personalized response using calculated chart data
    return await _generatePersonalizedResponse(
      userPrompt: userPrompt,
      langMode: langMode,
      chart: _chartJson!,
    );
  }

  /// Handles general educational questions without requesting birth details.
  Future<String> _handleGeneralQuery({
    required String userPrompt,
    required AvaraLanguageMode langMode,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      languageMode: langMode,
      chartData: _chartJson, // optional context if chart is already loaded
    );

    return await _callGroqChat(
      userPrompt: userPrompt,
      systemPrompt: systemPrompt,
    );
  }

  // -------------------------------------------------------------------------
  // AI Response Generation & Prompting
  // -------------------------------------------------------------------------

  Future<String> _generatePersonalizedResponse({
    required String userPrompt,
    required AvaraLanguageMode langMode,
    required Map<String, dynamic> chart,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      languageMode: langMode,
      chartData: chart,
    );

    return await _callGroqChat(
      userPrompt: userPrompt,
      systemPrompt: systemPrompt,
    );
  }

  /// REST transport call to Groq API with exponential backoff.
  Future<String> _callGroqChat({
    required String userPrompt,
    required String systemPrompt,
  }) async {
    String rawKey = _apiKey;
    try {
      if (dotenv.isInitialized) {
        rawKey = dotenv.env['GROQ_API_KEY'] ?? _apiKey;
      }
    } catch (_) {}
    final apiKey = rawKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (apiKey.isEmpty) {
      throw const AIAstrologyException(
        'Groq API key is not configured. Please ensure GROQ_API_KEY is set in .env.',
      );
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    // Build messages payload preserving conversation history
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ..._conversationHistory,
      {
        'role': 'user',
        'content': userPrompt,
      },
    ];

    final body = jsonEncode({
      'model': 'openai/gpt-oss-20b',
      'messages': messages,
      'temperature': 0.7,
    });

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: body,
            )
            .timeout(_kTimeout);
      } on TimeoutException {
        if (attempt < maxAttempts) {
          final backoffSeconds = attempt == 1 ? 2 : 4;
          await Future<void>.delayed(Duration(seconds: backoffSeconds));
          continue;
        }
        rethrow;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          throw AIAstrologyException(
            'Groq API error (HTTP 200 invalid JSON): ${response.body}',
          );
        }

        final content = jsonResponse['choices']?[0]?['message']?['content']
                ?.toString() ??
            '';
        final trimmed = content.trim();

        // Update multi-turn history
        _conversationHistory.add({'role': 'user', 'content': userPrompt});
        _conversationHistory.add({'role': 'assistant', 'content': trimmed});

        // Retain last 10 messages (5 turns)
        if (_conversationHistory.length > 10) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 10);
        }

        return trimmed;
      }

      final statusCode = response.statusCode;
      final isTransient =
          statusCode == 429 || (statusCode >= 500 && statusCode < 600);

      if (isTransient) {
        if (attempt < maxAttempts) {
          final backoffSeconds = attempt == 1 ? 2 : 4;
          await Future<void>.delayed(Duration(seconds: backoffSeconds));
          continue;
        }
        return 'The stars are currently clouded. Please ask again in a moment.';
      }

      Map<String, dynamic>? errorJson;
      try {
        errorJson = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      final err = errorJson?['error'];
      final errMsg = err is Map ? err['message']?.toString() : response.body;
      throw AIAstrologyException('Groq API error (HTTP $statusCode): $errMsg');
    }

    return 'The stars are currently clouded. Please ask again in a moment.';
  }

  // -------------------------------------------------------------------------
  // Helper Methods
  // -------------------------------------------------------------------------

  String _buildSystemPrompt({
    required AvaraLanguageMode languageMode,
    Map<String, dynamic>? chartData,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are AVARA, an authoritative and compassionate Vedic Astrology guide based on traditional Indian Jyotisha (Sidereal Nirayana system, Lahiri Ayanamsa).\n',
    );
    buffer.writeln(
      'SAFETY RULE: You must NEVER predict death, lifespan, or diagnose medical conditions. If the user asks about \'cancer\', assume they mean the disease unless context strictly implies the zodiac sign. If any medical or mortality intent slips through, refuse to answer and state you cannot provide medical or life-expectancy predictions.\n',
    );

    // Language instructions
    switch (languageMode) {
      case AvaraLanguageMode.english:
        buffer.writeln(
          'LANGUAGE CONSTRAINT:\n'
          'Respond strictly in clear, polished, and natural English.\n',
        );
        break;
      case AvaraLanguageMode.telugu:
        buffer.writeln(
          'LANGUAGE CONSTRAINT:\n'
          'Respond strictly in natural, grammatically correct Telugu script (తెలుగు లిపి).\n',
        );
        break;
      case AvaraLanguageMode.tanglish:
        buffer.writeln(
          'LANGUAGE CONSTRAINT:\n'
          'Respond strictly in natural, conversational Telugu-English mixed (Tanglish / Telugu transliteration in English characters), matching how Telugu speakers naturally speak (e.g., "Mee Janma Kundali prakaram...", "Mee Chandra Rashi ... untundi").\n',
        );
        break;
    }

    // Vedic astrology principles and guardrails
    buffer.writeln(
      'JYOTISHA PRINCIPLES & GUARDRAILS:\n'
      '1. Follow traditional Indian Vedic Jyotisha only. Do not use Western Tropical astrology.\n'
      '2. When personal birth chart data is provided below, interpret the native\'s ACTUAL placements (Chandra Rashi, Janma Nakshatra, Lagna, Bhavas, and Mahadasha). NEVER output generic descriptions of all 12 zodiac signs for personal questions.\n'
      '3. For Moon sign / emotions: address the native\'s actual Moon sign and Nakshatra directly.\n'
      '4. For marriage / relationships: examine the 7th house, 7th lord, Venus, and Jupiter from the chart.\n'
      '5. For career: examine the 10th house, 10th lord, Saturn, Sun, Mercury, and the current Mahadasha.\n'
      '6. For Mahadasha questions: cite the native\'s actual Current Mahadasha from the chart data.\n'
      '7. NEVER make deterministic or fatalistic predictions regarding death, exact marriage dates, illnesses, or ruin. Frame interpretations as cosmic potentials, tendencies, and spiritual guidance.\n'
      '8. Clearly distinguish traditional astrological concepts from empirical facts.\n',
    );

    // Clean formatting instructions
    buffer.writeln(
      'FORMATTING REQUIREMENTS:\n'
      '- Render clean, professional Markdown with clear section headings (###).\n'
      '- Use bold text (**bold**) for key planetary terms, houses, and signs.\n'
      '- Use bullet points (- ) and paragraphs with double line breaks.\n'
      '- Ensure readable spacing on mobile and desktop devices.\n',
    );

    buffer.writeln(
      'RESPONSE STRUCTURE RULE: Whenever answering a chart-based question, you must ALWAYS start with a simple, direct 1-2 sentence summary of the situation in plain, non-astrological language. ONLY AFTER providing this simple summary should you list the astrological evidence (houses, planets, dashas) from the user\'s Kundli that supports your conclusion.\n',
    );

    buffer.writeln(
      'KUNDLI VISUALIZATION RULE:\n'
      'If the user explicitly asks to \'see their Kundli\', \'show my chart\', or \'generate my Jathakam\', provide a brief 1-2 sentence introductory text and then strictly append the exact tag `[RENDER_SQUARE_KUNDLI]` at the very end of your response. DO NOT generate a Markdown table of planetary positions if they just ask to see the chart.\n',
    );

    if (chartData != null) {
      buffer.writeln('---');
      buffer.writeln(_buildChartSummary(chartData));
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  String _buildChartSummary(Map<String, dynamic> chart) {
    final buffer = StringBuffer();
    final lagna = chart['lagna'] as Map<String, dynamic>? ?? {};
    final planets = chart['planets'] as Map<String, dynamic>? ?? {};
    final houses = chart['houses'] as Map<dynamic, dynamic>? ?? {};
    final dasha = chart['vimshottari_dasha'] as Map<String, dynamic>? ?? {};
    final moon = planets['Moon'] as Map<String, dynamic>? ?? {};

    buffer.writeln('[ACTIVE NATIVE VEDIC BIRTH CHART (NIRAYANA LAHIRI)]');

    // Lagna & Moon
    final lagnaEng = lagna['rasi_name_english'] ?? lagna['rasi_name_sanskrit'];
    final lagnaTel = lagna['rasi_name_telugu'] ?? '';
    final lagnaDeg = (lagna['degrees_in_rasi'] as num?)?.toStringAsFixed(2);
    final lagnaNak = lagna['nakshatra_name_sanskrit'] ?? '';
    final lagnaPada = lagna['pada'] ?? '';
    buffer.writeln('- Lagna (Ascendant): $lagnaEng ($lagnaTel) at $lagnaDeg°, Nakshatra: $lagnaNak Pada $lagnaPada');

    final moonEng = moon['rasi_name_english'] ?? moon['rasi_name_sanskrit'];
    final moonTel = moon['rasi_name_telugu'] ?? '';
    final moonDeg = (moon['degrees_in_rasi'] as num?)?.toStringAsFixed(2);
    final moonNak = moon['nakshatra_name_sanskrit'] ?? '';
    final moonPada = moon['pada'] ?? '';
    final moonLord = moon['nakshatra_lord'] ?? '';
    buffer.writeln('- Chandra Rashi (Moon Sign): $moonEng ($moonTel) at $moonDeg°');
    buffer.writeln('- Janma Nakshatra: $moonNak ($moonTel) Pada $moonPada (Lord: $moonLord)');

    // Current Mahadasha
    final currentDasha = dasha['current_mahadasha'] as Map<String, dynamic>?;
    if (currentDasha != null) {
      buffer.writeln(
        '- Current Mahadasha: ${currentDasha['planet']} Mahadasha (Active from ${currentDasha['start_date']} to ${currentDasha['end_date']})',
      );
    }

    // Planetary placements
    buffer.writeln('\n[PLANETARY PLACEMENTS]');
    for (final entry in planets.entries) {
      final p = entry.value as Map<String, dynamic>;
      final pEng = p['rasi_name_english'] ?? p['rasi_name_sanskrit'];
      final pTel = p['rasi_name_telugu'] ?? '';
      final pDeg = (p['degrees_in_rasi'] as num?)?.toStringAsFixed(2);
      final pNak = p['nakshatra_name_sanskrit'] ?? '';
      final pPada = p['pada'] ?? '';
      final pHouse = p['house'] ?? '';
      final retro = (p['is_retrograde'] == true) ? ' (Retrograde)' : '';
      buffer.writeln('* ${entry.key}: in House $pHouse ($pEng / $pTel) at $pDeg°, $pNak Pada $pPada$retro');
    }

    // Key Houses
    if (houses.isNotEmpty) {
      buffer.writeln('\n[HOUSES (BHAVAS)]');
      for (int h = 1; h <= 12; h++) {
        final house = houses[h] as Map<String, dynamic>?;
        if (house != null) {
          final occ = (house['occupants'] as List?)?.join(', ') ?? 'None';
          buffer.writeln('House $h (${house['rasi_name_english']}, Lord: ${house['lord']}): Occupants: $occ — ${house['significance']}');
        }
      }
    }

    return buffer.toString();
  }

  String _buildChartIntroResponse(
    Map<String, dynamic> chart,
    AvaraLanguageMode mode,
  ) {
    final lagna = chart['lagna'] as Map<String, dynamic>? ?? {};
    final planets = chart['planets'] as Map<String, dynamic>? ?? {};
    final moon = planets['Moon'] as Map<String, dynamic>? ?? {};
    final dasha = chart['vimshottari_dasha'] as Map<String, dynamic>? ?? {};
    final currentDasha = dasha['current_mahadasha'] as Map<String, dynamic>?;

    final lagnaName = lagna['rasi_name_english'] ?? lagna['rasi_name_sanskrit'];
    final moonSign = moon['rasi_name_english'] ?? moon['rasi_name_sanskrit'];
    final nakshatra = moon['nakshatra_name_sanskrit'] ?? '';
    final dashaName = currentDasha?['planet'] ?? '';

    switch (mode) {
      case AvaraLanguageMode.telugu:
        return 'మీ జన్మ వివరాల ఆధారంగా వేద జన్మ కుండలి లెక్కించబడింది 🙏\n\n'
            '### మీ కుండలి ముఖ్య వివరాలు:\n'
            '- **లగ్నం (Lagna)**: ${lagna['rasi_name_telugu']} ($lagnaName)\n'
            '- **చంద్ర రాశి (Moon Sign)**: ${moon['rasi_name_telugu']} ($moonSign)\n'
            '- **జన్మ నక్షత్రం (Nakshatra)**: $nakshatra (${moon['pada']}వ పాదం)\n'
            '- **ప్రస్తుత మహర్దశ (Mahadasha)**: $dashaName మహర్దశ\n\n'
            'మీ కెరీర్, వివాహం, భావోద్వేగాలు లేదా ఇతర జీవిత విషయాల గురించి మీరు ఏ ప్రశ్నైనా అడగవచ్చు!';
      case AvaraLanguageMode.tanglish:
        return 'Mee birth details calculate chesi Janma Kundali generate chesaanu 🙏\n\n'
            '### Mee Kundali Highlights:\n'
            '- **Lagna (Ascendant)**: $lagnaName (${lagna['rasi_name_telugu']})\n'
            '- **Chandra Rashi (Moon Sign)**: $moonSign (${moon['rasi_name_telugu']})\n'
            '- **Janma Nakshatra**: $nakshatra (Pada ${moon['pada']})\n'
            '- **Current Mahadasha**: $dashaName Mahadasha\n\n'
            'Mee career, marriage, relationships, leda future gurinchi emaina questions adagavachhu!';
      case AvaraLanguageMode.english:
        return 'Your Vedic birth chart (Janma Kundali) has been calculated using the Nirayana Lahiri system 🙏\n\n'
            '### Key Placements:\n'
            '- **Lagna (Ascendant)**: $lagnaName\n'
            '- **Chandra Rashi (Moon Sign)**: $moonSign\n'
            '- **Janma Nakshatra**: $nakshatra (Pada ${moon['pada']})\n'
            '- **Current Mahadasha**: $dashaName Mahadasha\n\n'
            'What would you like to explore? You can ask about your career, marriage, emotional nature, or planetary periods.';
    }
  }

  Future<void> _recalculateFromStored(Map<String, String> stored) async {
    final dateStr = stored['birth_date'];
    final timeStr = stored['birth_time'] ?? '';
    final placeStr = stored['birth_place'];
    if (dateStr == null || placeStr == null || _chartGenerator == null) return;

    try {
      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return;
      var y = int.parse(dateParts[0]);
      var m = int.parse(dateParts[1]);
      var d = int.parse(dateParts[2]);

      int hour = 12;
      int minute = 0;
      if (timeStr.isNotEmpty) {
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.tryParse(timeParts[0]) ?? 12;
          minute = int.tryParse(timeParts[1]) ?? 0;
        }
      }

      final geo = await AvaraGeocoder.geocode(placeStr);
      final localMinutes = hour * 60 + minute;
      const offsetMinutes = 330;
      int utcMinutes = localMinutes - offsetMinutes;
      int dayDelta = 0;
      while (utcMinutes < 0) {
        utcMinutes += 24 * 60;
        dayDelta -= 1;
      }
      while (utcMinutes >= 24 * 60) {
        utcMinutes -= 24 * 60;
        dayDelta += 1;
      }
      final hourUtc = (utcMinutes ~/ 60) + (utcMinutes % 60) / 60.0;
      if (dayDelta != 0) {
        final adj = DateTime.utc(y, m, d).add(Duration(days: dayDelta));
        y = adj.year;
        m = adj.month;
        d = adj.day;
      }

      final chart = await _chartGenerator(
        year: y,
        month: m,
        day: d,
        hourUtc: hourUtc,
        lat: geo.latitude,
        lon: geo.longitude,
      );

      _chartJson = chart;
      _hasBirthTime = timeStr.isNotEmpty;
      BirthProfileManager.instance.setChart(chart);
    } catch (_) {}
  }

  bool _isLagnaOrHouseQuery(String text) {
    final clean = text.toLowerCase();
    return clean.contains('lagna') ||
        clean.contains('ascendant') ||
        clean.contains('7th house') ||
        clean.contains('10th house') ||
        clean.contains('house') ||
        clean.contains('bhava') ||
        clean.contains('లగ్నం') ||
        clean.contains('lagnam');
  }

  bool _isSpecificQuestion(String text) {
    final clean = text.toLowerCase().trim();
    return clean.contains('?') ||
        clean.contains('what') ||
        clean.contains('how') ||
        clean.contains('tell') ||
        clean.contains('show') ||
        clean.contains('see') ||
        clean.contains('generate') ||
        clean.contains('kundli') ||
        clean.contains('kundali') ||
        clean.contains('chart') ||
        clean.contains('jathakam') ||
        clean.contains('cheppu') ||
        clean.contains('cheppandi') ||
        clean.contains('enti') ||
        clean.contains('ela');
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class AIAstrologyException implements Exception {
  final String message;
  final Object? cause;

  const AIAstrologyException(this.message, {this.cause});

  @override
  String toString() => cause != null
      ? 'AIAstrologyException: $message\n  Caused by: $cause'
      : 'AIAstrologyException: $message';
}
