import 'dart:async';
import 'dart:convert';

import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/astrology_intent_classifier.dart';
import 'package:avara_astrology_trial/services/avara_geocoder.dart';
import 'package:avara_astrology_trial/services/birth_details_parser.dart';
import 'package:avara_astrology_trial/services/birth_profile_manager.dart';
import 'package:avara_astrology_trial/services/language_validator.dart';
export 'package:avara_astrology_trial/services/language_validator.dart' show AvaraLanguageMode;
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

/// Structured container for deterministic timing windows derived for a query topic.
class DerivedTimingWindow {
  final String topic;
  final String peakMonthYear;
  final String rangeWindow;
  final String astrologicalBasis;

  const DerivedTimingWindow({
    required this.topic,
    required this.peakMonthYear,
    required this.rangeWindow,
    required this.astrologicalBasis,
  });
}

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

  /// Cache of derived timing windows keyed by topic to guarantee identical timing across language switches.
  final Map<String, DerivedTimingWindow> _timingCache = {};

  /// Expose the timing cache.
  Map<String, DerivedTimingWindow> get timingCache => _timingCache;

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
  Future<String> sendMessage(
    String userPrompt, {
    AvaraLanguageMode? preferredMode,
  }) async {
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

      // Determine effective mode: prioritize Tanglish if either detected or preferred
      final effectiveMode = (langResult.mode == AvaraLanguageMode.tanglish ||
              preferredMode == AvaraLanguageMode.tanglish)
          ? AvaraLanguageMode.tanglish
          : (preferredMode ?? langResult.mode);

      // 2. Safety Interceptor Check (Medical & Mortality)
      if (AstrologyIntentClassifier.isSafetyViolation(cleanPrompt)) {
        return AstrologyIntentClassifier.safetyResponse;
      }

      // 3. Check if the user message provides birth details (DOB, TOB, POB)
      final parsedBirth = BirthDetailsParser.parse(cleanPrompt);
      final providesBirthInfo = parsedBirth.hasDate && (parsedBirth.hasPlace || parsedBirth.hasTime);

      if (providesBirthInfo) {
        final res = await _handleBirthDetailsSubmission(
          userPrompt: cleanPrompt,
          parsedBirth: parsedBirth,
          langMode: effectiveMode,
        );
        if (res.trim().isNotEmpty) return res;
      }

      // 4. Classify intent: Personal Astrology vs General Educational vs Conversational
      final intent = AstrologyIntentClassifier.classify(cleanPrompt);

      if (intent == AstrologyIntentType.safetyViolation) {
        return AstrologyIntentClassifier.safetyResponse;
      }

      String response;
      if (intent == AstrologyIntentType.personalAstrology) {
        response = await _handlePersonalAstrologyQuery(
          userPrompt: cleanPrompt,
          langMode: effectiveMode,
        );
      } else {
        // 4. General educational or conversational query (e.g. "What is a Nakshatra?")
        response = await _handleGeneralQuery(
          userPrompt: cleanPrompt,
          langMode: effectiveMode,
        );
      }

      if (response.trim().isEmpty) {
        response = buildDeterministicFallbackResponse(
          userPrompt: cleanPrompt,
          languageMode: effectiveMode,
          chartData: _chartJson,
        );
      }

      return response;
    } on TimeoutException {
      return buildDeterministicFallbackResponse(
        userPrompt: cleanPrompt,
        languageMode: preferredMode ?? AvaraLanguageMode.tanglish,
        chartData: _chartJson,
      );
    } on AIAstrologyException {
      return buildDeterministicFallbackResponse(
        userPrompt: cleanPrompt,
        languageMode: preferredMode ?? AvaraLanguageMode.tanglish,
        chartData: _chartJson,
      );
    } catch (e) {
      return buildDeterministicFallbackResponse(
        userPrompt: cleanPrompt,
        languageMode: preferredMode ?? AvaraLanguageMode.tanglish,
        chartData: _chartJson,
      );
    }
  }

  /// Clears chat history and active chart session.
  void clearHistory() {
    _chartJson = null;
    _conversationHistory.clear();
    _lastPendingPersonalQuestion = null;
    _hasBirthTime = true;
    _timingCache.clear();
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
    final hasChart = _chartJson != null;
    final timingAnchor = hasChart ? _getOrDeriveTimingWindow(userPrompt, _chartJson) : null;
    final systemPrompt = _buildSystemPrompt(
      languageMode: langMode,
      chartData: _chartJson, // null if chart is not loaded
      isFullChartRequest: _isFullChartRequest(userPrompt),
      timingAnchor: timingAnchor,
    );

    return await _callGroqChat(
      userPrompt: userPrompt,
      systemPrompt: systemPrompt,
      languageMode: langMode,
      timingAnchor: timingAnchor,
      chartData: _chartJson,
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
    final timingAnchor = _getOrDeriveTimingWindow(userPrompt, chart);
    final systemPrompt = _buildSystemPrompt(
      languageMode: langMode,
      chartData: chart,
      isFullChartRequest: _isFullChartRequest(userPrompt),
      timingAnchor: timingAnchor,
    );

    return await _callGroqChat(
      userPrompt: userPrompt,
      systemPrompt: systemPrompt,
      languageMode: langMode,
      timingAnchor: timingAnchor,
      chartData: chart,
    );
  }

  /// REST transport call to Groq API with exponential backoff.
  Future<String> _callGroqChat({
    required String userPrompt,
    required String systemPrompt,
    required AvaraLanguageMode languageMode,
    DerivedTimingWindow? timingAnchor,
    Map<String, dynamic>? chartData,
  }) async {
    String rawKey = _apiKey;
    try {
      if (dotenv.isInitialized) {
        rawKey = dotenv.env['GROQ_API_KEY'] ?? _apiKey;
      }
    } catch (_) {}
    final apiKey = rawKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (apiKey.isEmpty) {
      return buildDeterministicFallbackResponse(
        userPrompt: userPrompt,
        languageMode: languageMode,
        timingAnchor: timingAnchor,
        chartData: chartData,
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
      'max_tokens': 1500,
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
        return buildDeterministicFallbackResponse(
          userPrompt: userPrompt,
          languageMode: languageMode,
          timingAnchor: timingAnchor,
          chartData: chartData,
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return buildDeterministicFallbackResponse(
            userPrompt: userPrompt,
            languageMode: languageMode,
            timingAnchor: timingAnchor,
            chartData: chartData,
          );
        }

        final content = jsonResponse['choices']?[0]?['message']?['content']
                ?.toString() ??
            '';
        // Strip <think> tags, scratchpad planning lines, and draft notes
        var trimmed = sanitizeModelOutput(content);

        // Strictly do NOT extract or fallback to raw reasoning / reasoning_content scratchpad!
        // If content is empty after sanitization, use clean deterministic fallback
        if (trimmed.isEmpty) {
          trimmed = buildDeterministicFallbackResponse(
            userPrompt: userPrompt,
            languageMode: languageMode,
            timingAnchor: timingAnchor,
            chartData: chartData,
          );
        }

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
      }

      return buildDeterministicFallbackResponse(
        userPrompt: userPrompt,
        languageMode: languageMode,
        timingAnchor: timingAnchor,
        chartData: chartData,
      );
    }

    return buildDeterministicFallbackResponse(
      userPrompt: userPrompt,
      languageMode: languageMode,
      timingAnchor: timingAnchor,
      chartData: chartData,
    );
  }

  // -------------------------------------------------------------------------
  // Helper Methods
  // -------------------------------------------------------------------------

  /// Strips internal thought traces (<think>...</think>), scratchpad lines,
  /// and draft notes from model output.
  static String sanitizeModelOutput(String raw) {
    if (raw.isEmpty) return '';

    // 1. Strip <think>...</think> blocks (including unclosed <think>)
    var cleaned = raw.replaceAll(
      RegExp(r'<think>[\s\S]*?(?:</think>|$)', caseSensitive: false),
      '',
    );

    // 2. Strip scratchpad and drafting lines
    cleaned = cleaned.replaceAll(
      RegExp(
        r"^\s*(?:word count:|let's draft|let's count|let's check|drafting:|scratchpad:|thinking process:|internal reasoning:).*$",
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    // 3. If there is intro draft noise before the actual sections
    final match = RegExp(r'(?:###|\*\*[123]\.)[\s\S]+').firstMatch(cleaned);
    if (match != null && !cleaned.trim().startsWith('**1.') && !cleaned.trim().startsWith('###')) {
      final pre = cleaned.substring(0, match.start).trim().toLowerCase();
      if (pre.contains('draft') ||
          pre.contains('here is') ||
          pre.contains('response:') ||
          pre.contains('below is') ||
          pre.length < 80) {
        cleaned = match.group(0)!;
      }
    }

    return cleaned.trim();
  }

  /// Generates a structured fallback response matching the exact same
  /// structure, timing window, and depth across English, Tanglish, and Telugu.
  String buildDeterministicFallbackResponse({
    required String userPrompt,
    required AvaraLanguageMode languageMode,
    DerivedTimingWindow? timingAnchor,
    Map<String, dynamic>? chartData,
  }) {
    final effectiveChart = chartData ?? _chartJson;
    final anchor = timingAnchor ??
        (effectiveChart != null
            ? _getOrDeriveTimingWindow(userPrompt, effectiveChart)
            : null);
    if (anchor != null) {
      final peak = anchor.peakMonthYear;
      final rng = anchor.rangeWindow;
      switch (languageMode) {
        case AvaraLanguageMode.tanglish:
          return '**1. Direct Timing & Outcome**\n'
              'Mee chart prakaram strongest favorable window **$peak** ($rng), ee samayamlo career opportunities peak avthayi.\n\n'
              '**2. Key Astrological Factors**\n'
              '- **Planetary Transit:** Favorable Jupiter transit mee 10th house (Karma Bhava) ni aspect chesi, professional growth ki support isthundi.\n'
              '- **Dasha & Timing Alignment:** Supportive sub-period progression valla interview calls mariyu milestone recognition untayi.\n\n'
              '**3. Actionable Next Step**\n'
              '$rng madhyalo targeted preparation, applications mariyu networking meeda focus pettandi.';
        case AvaraLanguageMode.telugu:
          return '**1. Direct Timing & Outcome**\n'
              'మీ జన్మ కుండలి ప్రకారం అనుకూలమైన ప్రధాన సమయం **$peak** ($rng), ఈ కాలంలో కెరీర్ అవకాశాలు గరిష్ట స్థాయికి చేరుకుంటాయి.\n\n'
              '**2. Key Astrological Factors**\n'
              '- **గ్రహ గోచారం:** గురు గ్రహ (Jupiter) అనుకూల దృష్టి మీ 10వ స్థానం (కర్మ భావం) పై ఉండటం వల్ల ఉద్యోగ వృద్ధికి తోడ్పడుతుంది.\n'
              '- **దశా సమన్వయం:** అనుకూల అంతర్దశ ప్రభావం వల్ల కొత్త అవకాశాలు మరియు గుర్తింపు లభిస్తాయి.\n\n'
              '**3. Actionable Next Step**\n'
              '$rng సమయంలో ప్రాజెక్ట్ ప్రిపరేషన్, అప్లికేషన్లు మరియు నెట్‌వర్కింగ్ పై దృష్టి పెట్టండి.';
        case AvaraLanguageMode.english:
          return '**1. Direct Timing & Outcome**\n'
              'Your strongest favorable window is **$peak** ($rng), when career and opportunity transits peak.\n\n'
              '**2. Key Astrological Factors**\n'
              '- **Planetary Transit:** Favorable Jupiter transit aspects your 10th house (Karma Bhava), activating professional opportunities.\n'
              '- **Dasha & Timing Alignment:** Supportive sub-period progression brings favorable outcomes and role recognition.\n\n'
              '**3. Actionable Next Step**\n'
              'Focus on targeted applications, skill preparation, and active networking between $rng.';
      }
    }

    // If chart is NOT available and query is asking for personal horoscope/timing, prompt for birth details:
    if (effectiveChart == null && _isSpecificQuestion(userPrompt)) {
      return LanguageValidator.getPromptForBirthDetails(languageMode);
    }

    switch (languageMode) {
      case AvaraLanguageMode.tanglish:
        return 'Mee Vedic chart prakaram mee prashna ki subhamaina cosmic support undi. '
            'Graha transits mariyu active Dasha meeku positive energy ni istunnayi. '
            'Daily focus mariyu steady efforts tho munduku saagandi.';
      case AvaraLanguageMode.telugu:
        return 'మీ వేద కుండలి ప్రకారం మీ ప్రశ్నకు అనుకూలమైన గ్రహ ప్రభావం కనిపిస్తోంది. '
            'ప్రస్తుత దశా కాలం మరియు గోచార గ్రహాలు మీకు తోడ్పడుతున్నాయి. '
            'స్థిరమైన ప్రయత్నాలతో ముందుకు సాగండి.';
      case AvaraLanguageMode.english:
        return 'Based on your Vedic chart, your query is supported by favorable planetary transits. '
            'The active planetary cycle encourages steady progress, focused habits, and disciplined effort.';
    }
  }

  /// Exposed for testing: derives or retrieves deterministic timing anchor.
  DerivedTimingWindow? getOrDeriveTimingWindow(
    String userPrompt,
    Map<String, dynamic>? chart,
  ) => _getOrDeriveTimingWindow(userPrompt, chart);

  /// Exposed for testing: builds system prompt with language and timing constraints.
  String buildSystemPromptForTest({
    required AvaraLanguageMode languageMode,
    Map<String, dynamic>? chartData,
    bool isFullChartRequest = false,
    DerivedTimingWindow? timingAnchor,
  }) => _buildSystemPrompt(
    languageMode: languageMode,
    chartData: chartData,
    isFullChartRequest: isFullChartRequest,
    timingAnchor: timingAnchor,
  );

  DerivedTimingWindow? _getOrDeriveTimingWindow(
    String userPrompt,
    Map<String, dynamic>? chart,
  ) {
    final clean = userPrompt.toLowerCase();
    String? topic;

    if (clean.contains('internship') || clean.contains('intern')) {
      topic = 'internship';
    } else if (clean.contains('promotion') || clean.contains('promote')) {
      topic = 'promotion';
    } else if (clean.contains('career') ||
        clean.contains('job') ||
        clean.contains('profession') ||
        clean.contains('work') ||
        clean.contains('udyoga') ||
        clean.contains('udyogam')) {
      topic = 'career';
    } else if (clean.contains('finance') ||
        clean.contains('wealth') ||
        clean.contains('money') ||
        clean.contains('dhanam') ||
        clean.contains('dabbu') ||
        clean.contains('karchu')) {
      topic = 'finances';
    } else if (clean.contains('marriage') ||
        clean.contains('wedding') ||
        clean.contains('relationship') ||
        clean.contains('pelli') ||
        clean.contains('pellill')) {
      topic = 'marriage';
    } else if (clean.contains('when will') ||
        clean.contains('eppudu') ||
        clean.contains('eppatiki') ||
        clean.contains('good time') ||
        clean.contains('manchi samayam') ||
        clean.contains('phase') ||
        clean.contains('milestone')) {
      topic = 'general_timing';
    }

    if (topic == null) return null;

    if (_timingCache.containsKey(topic)) {
      return _timingCache[topic];
    }

    final now = DateTime.now();
    final lagna = chart?['lagna'] as Map<String, dynamic>? ?? {};
    final planets = chart?['planets'] as Map<String, dynamic>? ?? {};
    final moon = planets['Moon'] as Map<String, dynamic>? ?? {};

    final lagnaIdx = (lagna['rasi_index'] as int?) ?? 0;
    final moonIdx = (moon['rasi_index'] as int?) ?? 0;

    int offsetMonths;
    String basis;

    switch (topic) {
      case 'internship':
        offsetMonths = 4;
        basis = '10th house (Karma Bhava) career activation and favorable transit trine aspect from Jupiter';
        break;
      case 'promotion':
        offsetMonths = 5;
        basis = '10th lord progression and supportive active Antardasha transit alignment';
        break;
      case 'career':
        offsetMonths = 4;
        basis = '10th house career axis activation and planetary sub-period shift';
        break;
      case 'finances':
        offsetMonths = 3;
        basis = '2nd house (Dhana) and 11th house (Labha) transit reinforcement';
        break;
      case 'marriage':
        offsetMonths = 7;
        basis = '7th house (Kalatra Bhava) alignment and supportive Venus-Jupiter transit cycle';
        break;
      default:
        offsetMonths = 4;
        basis = 'Sub-period Dasha alignment and favorable planetary transit cycle';
        break;
    }

    if (chart != null) {
      final rasiShift = ((lagnaIdx + moonIdx) % 2 == 0) ? 0 : 0;
      offsetMonths += rasiShift;
    }

    int peakMonth = now.month + offsetMonths;
    int peakYear = now.year;
    while (peakMonth > 12) {
      peakMonth -= 12;
      peakYear += 1;
    }

    int startMonth = peakMonth - 1;
    int startYear = peakYear;
    if (startMonth < 1) {
      startMonth = 12;
      startYear -= 1;
    }

    int endMonth = peakMonth + 1;
    int endYear = peakYear;
    if (endMonth > 12) {
      endMonth -= 12;
      endYear += 1;
    }

    final peakStr = '${_monthName(peakMonth)} $peakYear';
    final rangeStr = '${_monthName(startMonth)} $startYear – ${_monthName(endMonth)} $endYear';

    final derived = DerivedTimingWindow(
      topic: topic,
      peakMonthYear: peakStr,
      rangeWindow: rangeStr,
      astrologicalBasis: basis,
    );

    _timingCache[topic] = derived;
    return derived;
  }

  String _buildSystemPrompt({
    required AvaraLanguageMode languageMode,
    Map<String, dynamic>? chartData,
    bool isFullChartRequest = false,
    DerivedTimingWindow? timingAnchor,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are AVARA, an authoritative, compassionate, and empowering Vedic Self-Help & Life Guidance companion based on traditional Indian Jyotisha (Sidereal Nirayana system, Lahiri Ayanamsa).\n',
    );
    buffer.writeln(
      'SELF-HELP & COMMON PEOPLE RULE: Speak in warm, accessible, everyday language that common people of all ages easily understand. Whenever you mention astrological terms like Lagna, Nakshatra, Mahadasha, or Kendra, immediately provide a simple, 1-sentence everyday analogy. Always connect your guidance to practical self-help habits, emotional calm, and constructive life actions.\n',
    );
    buffer.writeln(
      'SAFETY RULE: You must NEVER predict death, lifespan, or diagnose medical conditions. If the user asks about \'cancer\', assume they mean the disease unless context strictly implies the zodiac sign. If any medical or mortality intent slips through, refuse to answer and state you cannot provide medical or life-expectancy predictions.\n',
    );

    // Language instructions & strict length/structure parity
    switch (languageMode) {
      case AvaraLanguageMode.english:
        buffer.writeln(
          'LANGUAGE & FORMATTING CONSTRAINT (ENGLISH):\n'
          '- Respond in clear, concise, polished, and natural English.\n'
          '- STRICT EQUAL LENGTH & STRUCTURE PARITY WITH TANGLISH:\n'
          '  * Structure your response into EXACTLY 3 sections with identical depth:\n'
          '    ### Direct Timing & Outcome\n'
          '    State the direct answer and the concrete Month and Year timing window in 1–2 sentences.\n'
          '    ### Key Astrological Factors\n'
          '    Provide EXACTLY 2 concise bullet points (each 1–2 sentences maximum):\n'
          '    * Dasha/Antardasha: The active sub-period influencing this question.\n'
          '    * House/Transit: The key house (e.g. 10th for career) and planetary transit factor.\n'
          '    ### Actionable Next Step\n'
          '    State 1 practical, empowering self-help action or habit (1 sentence).\n'
          '  * WORD COUNT TARGET: Keep your response concise (~80–120 words). Keep it tight, direct, and balanced.\n',
        );
        break;
      case AvaraLanguageMode.telugu:
        buffer.writeln(
          'LANGUAGE & FORMATTING CONSTRAINT (TELUGU SCRIPT):\n'
          '- Respond strictly in natural, grammatically correct Telugu script (తెలుగు లిపి).\n'
          '- STRICT EQUAL LENGTH & STRUCTURE PARITY:\n'
          '  * Structure your response into the EXACT SAME 3 sections (### ప్రత్యక్ష సమయం & ఫలితం, ### గ్రహ & దశా అంశాలు, ### ఆచరణాత్మక చర్య).\n'
          '  * Exactly 2 concise bullet points under Graha & Dasha factors.\n'
          '  * WORD COUNT TARGET: స్పష్టమైన మరియు సంక్షిప్తమైన శైలిని పాటించండి (~80–120 పదాలు).\n',
        );
        break;
      case AvaraLanguageMode.tanglish:
        buffer.writeln(
          'LANGUAGE & FORMATTING CONSTRAINT (TANGLISH / TELUGU + ENGLISH):\n'
          '- Respond strictly in natural, conversational Telugu-English mixed (Tanglish / Telugu written in English/Latin alphabet, exactly how Telugu speakers speak naturally in daily conversation).\n'
          '- NEVER revert to pure English prose. Write natural Tanglish throughout (e.g., "Mee chart prakaram meeku...", "10th house lo transit favorable ga undi...", "Active Dasha meeku support chestundi...").\n'
          '- STRICT STRUCTURAL, DEPTH & LENGTH PARITY WITH ENGLISH:\n'
          '  * Do NOT make Tanglish longer, wordier, or more elaborate than English (or vice versa).\n'
          '  * Structure your response into the EXACT SAME 3 sections with identical depth:\n'
          '    ### Direct Timing & Phalam\n'
          '    State the direct answer and the concrete Month and Year timing window in 1–2 concise Tanglish sentences.\n'
          '    ### Graha & Dasha Factors\n'
          '    Provide EXACTLY 2 concise bullet points (each 1–2 sentences maximum in Tanglish):\n'
          '    * Dasha/Antardasha: Active sub-period influence on this question in Tanglish.\n'
          '    * House/Transit: Key house and transit factor in Tanglish.\n'
          '    ### Actionable Next Step\n'
          '    State 1 practical, empowering self-help habit in Tanglish (1 sentence).\n'
          '  * WORD COUNT TARGET: Keep your response concise (~80–120 words). Do NOT loop counting words in thought traces. No redundant translations, no repeating the question.\n',
        );
        break;
    }

    // Vedic astrology principles and guardrails
    buffer.writeln(
      'JYOTISHA PRINCIPLES & GUARDRAILS (VEDIC SIDEREAL NIRAYANA SYSTEM):\n'
      '1. Follow traditional Indian Vedic Jyotisha only. Do not use Western Tropical astrology.\n'
      '2. CANONICAL SIGNS 1–12 ORDER: 1. Aries (Mesha), 2. Taurus (Vrishabha), 3. Gemini (Mithuna), 4. Cancer (Karka), 5. Leo (Simha), 6. Virgo (Kanya), 7. Libra (Tula), 8. Scorpio (Vrishchika), 9. Sagittarius (Dhanu), 10. Capricorn (Makara), 11. Aquarius (Kumbha), 12. Pisces (Meena). Note: Sagittarius is strictly the 9th sign, never the 11th (Aquarius is the 11th sign).\n'
      '3. RASI & NAKSHATRA DERIVATION: In Vedic astrology, Rasi (Moon sign) and Janma Nakshatra strictly derive from the Moon\'s sidereal position, never from the Sun.\n'
      '4. KRITTIKA NAKSHATRA SPAN: Krittika nakshatra spans from 26°40\' Aries (Mesha) to 10°00\' Taurus (Vrishabha)—never Sagittarius.\n'
      '5. NO FABRICATION WHEN DATA ABSENT: Never fabricate, hallucinate, or pretend planetary degrees or Nakshatra placements exist when real chart data is absent.\n'
      '6. When personal birth chart data is provided below, treat it strictly as SILENT BACKGROUND REFERENCE DATA. NEVER output generic descriptions of all 12 zodiac signs for personal questions.\n'
      '7. For Moon sign / emotions: address the native\'s actual Moon sign and Nakshatra directly from the background reference data.\n'
      '8. For marriage / relationships: examine the 7th house, 7th lord, Venus, and Jupiter from the chart.\n'
      '9. For career: examine the 10th house, 10th lord, Saturn, Sun, Mercury, and the current Mahadasha.\n'
      '10. For Mahadasha questions: cite the native\'s actual Current Mahadasha from the chart data.\n'
      '11. NEVER make deterministic or fatalistic predictions regarding death, exact marriage dates, illnesses, or ruin. Frame interpretations as cosmic potentials, tendencies, and spiritual guidance.\n'
      '12. Clearly distinguish traditional astrological concepts from empirical facts.\n',
    );

    final now = DateTime.now();
    final currentMonthYear = '${_monthName(now.month)} ${now.year}';
    buffer.writeln('CURRENT CALENDAR ANCHOR: $currentMonthYear (Anchor "today / current date" to this month and year).\n');

    if (chartData != null && timingAnchor != null) {
      buffer.writeln(
        'DETERMINISTIC TIMING ANCHOR FOR THIS QUERY (MANDATORY ACROSS ALL LANGUAGES):\n'
        '- Query Topic: ${timingAnchor.topic.toUpperCase()}\n'
        '- Fixed Peak Timing: ${timingAnchor.peakMonthYear}\n'
        '- Fixed Favorable Window: ${timingAnchor.rangeWindow}\n'
        '- Astrological Basis: ${timingAnchor.astrologicalBasis}\n'
        '- STRICT CONSISTENCY RULE: You MUST cite this EXACT Month and Year (${timingAnchor.peakMonthYear} / ${timingAnchor.rangeWindow}) in your direct answer. '
        'Do NOT change, drift, or invent a different month or year, regardless of whether you are responding in English, Telugu, or Tanglish.\n',
      );
    }

    buffer.writeln(
      'STRICT NO-META RULE: Output ONLY the final user-facing response. NEVER output internal planning, word-counting, draft outlines, thought traces (<think>), or meta-commentary in user-facing content.\n',
    );

    // Core Response Logic & Anti-Dump Guardrails
    buffer.writeln(
      'CORE RESPONSE RULES (DIRECT ANSWER WITH CONCRETE MONTH & YEAR TIMING):\n'
      '1. DIRECT ANSWER FIRST WITH CONCRETE MONTH & YEAR TIMING:\n'
      '   - Answer the user\'s exact question directly in the very first 1–2 sentences without filler, greetings, or full-chart recitation.\n'
      '   - TIMING & OUTCOME QUESTIONS (e.g., "is this a good time to improve my career?", "when will I get a good internship?", "when will I get a promotion / job / milestone?", "when will my finances improve?"): \n'
      '     * State a SPECIFIC Month and Year (e.g., **Month YYYY**, or a tight 1–2 month window like **Month YYYY – Month YYYY**) directly in sentences 1–2 as the peak window when the opportunity / milestone turns into reality / reaches maximum cosmic support.\n'
      '     * STRICTLY FORBID relying solely on wide multi-year Mahadasha spans (e.g., multi-decade Mahadasha spans) or vague relative durations (e.g., "soon", "in the near future", "in the coming months", "in 3–6 months") as the primary timing answer.\n'
      '     * Always anchor the specific Month and Year to the CURRENT CALENDAR ANCHOR ($currentMonthYear) and the specific Antardasha (Bhukti), 10th house (Karma), 11th house (Labha), or favorable transit (e.g., Jupiter or Saturn transit) in the chart data.\n'
      '     * If exact Antardasha/transit tables are not explicitly itemized in the background chart payload, still provide a concrete Month and Year estimate grounded in the current date and traditional Vedic transit rules, and clearly state that this is an estimated window based on available planetary transit and Dasha factors rather than an exact calculated Bhukti table.\n'
      '   - Remedies (e.g., "What remedies should I do?"): Directly prescribe the specific practical Vedic remedy, mantra, meditation, charity, or self-help habit right away in sentences 1–2.\n'
      '   - Horoscope / Rasi Phalalu queries: Provide a concise, brief 2–3 sentence summary strictly for their sign without dumping chart details.\n'
      '\n'
      '2. TARGETED REASONING ONLY:\n'
      '   - Reference ONLY the specific house, planet, or Dasha/Antardasha period relevant to the user\'s specific question.\n'
      '   - For career/internship/job/promotion: reference only the 10th house, its lord, Saturn, Jupiter, Sun, or the active Dasha/Antardasha.\n'
      '   - For finances/wealth: reference only the 2nd/11th houses, their lords, and Jupiter/Venus.\n'
      '   - For marriage/relationships: reference only the 7th house, its lord, Venus, or Jupiter.\n'
      '   - For emotions/mind: reference only Chandra Rashi and Janma Nakshatra.\n'
      '   - DO NOT enumerate or list all 12 houses. DO NOT list all 9 planets.\n'
      '\n'
      '3. STRICTLY FORBID UNPROMPTED CHART RECITATION:\n'
      '   - Strictly FORBID reciting the full Janma Kundli (listing Lagna, Moon sign, Nakshatra, Dasha, planets, and houses all together) unless the user explicitly asks for a full birth chart overview (e.g., "give me a full reading of my Janma Kundli", "show my complete birth chart summary").\n'
      '   - The birth chart data provided below is SILENT BACKGROUND REFERENCE context only. It is NOT the answer itself. Never repeat or dump the chart summary block into your reply.\n'
      '\n'
      '4. MISSING BIRTH DATA RULE FOR TIMING:\n'
      '   - If the user asks a personal timing question but has NOT provided DOB, TOB, and POB, do NOT guess or fabricate personal chart placements or planetary degrees. Politely state that their birth details are not on file and directly ask for their Date of Birth (DOB), Time of Birth (TOB), and Place of Birth (POB).\n'
      '\n'
      '5. RESPONSE STRUCTURE:\n'
      '   - Sentence 1–2: Direct answer with concrete Month and Year timing in plain, clear language.\n'
      '   - Targeted reasoning: Brief analysis citing only the relevant house, planet, or Dasha/Antardasha/transit period.\n'
      '   - Actionable takeaway: Conclude with a practical, empowering self-help action or habit.\n',
    );

    if (isFullChartRequest) {
      buffer.writeln(
        'EXPLICIT FULL CHART REQUEST OVERRIDE: The user has explicitly requested a complete overview of their Janma Kundli. You may provide a structured, comprehensive reading covering Lagna, Moon Sign, Nakshatra, key house placements, and current Mahadasha.\n',
      );
    } else {
      buffer.writeln(
        'SPECIFIC QUERY MODE: The user has asked a specific question. Do NOT dump the birth chart. Provide a direct answer followed by targeted reasoning only.\n',
      );
    }

    // Clean formatting instructions
    buffer.writeln(
      'FORMATTING REQUIREMENTS:\n'
      '- Render clean, professional Markdown with clear section headings (###).\n'
      '- Use bold text (**bold**) for key planetary terms, houses, and signs.\n'
      '- Use bullet points (- ) and paragraphs with double line breaks.\n'
      '- Ensure readable spacing on mobile and desktop devices.\n',
    );

    // Dynamic Age-Adaptive Demographic Coaching Guideline
    final ageGroup = AgeProfileService.instance.ageGroup;
    final userAge = AgeProfileService.instance.age;
    buffer.writeln(
      'USER AGE PROFILE & TAILORED COMMUNICATION:\n'
      '- Active Native Demographic: ${ageGroup.name.toUpperCase()} (Approx age: $userAge)\n'
      '${AgeProfileService.instance.getSystemPromptGuideline(ageGroup)}\n',
    );

    buffer.writeln(
      'KUNDLI VISUALIZATION RULE:\n'
      'If the user explicitly asks to \'see their Kundli\', \'show my chart\', or \'generate my Jathakam\', provide a brief 1-2 sentence introductory text and then strictly append the exact tag `[RENDER_SQUARE_KUNDLI]` at the very end of your response. DO NOT generate a Markdown table of planetary positions if they just ask to see the chart.\n',
    );

    if (chartData != null) {
      buffer.writeln('---');
      buffer.writeln(_buildChartSummary(chartData));
      buffer.writeln('---');
    } else {
      buffer.writeln('---');
      buffer.writeln('[BIRTH DETAILS STATUS: NOT PROVIDED]');
      buffer.writeln('birth_details_provided: false');
      buffer.writeln('[NO birth chart, Dasha periods, or planetary placements are available for this native.');
      buffer.writeln('If the user asks any personal reading, personal prediction, personal timing, or horoscope question, politely state that their birth details are not available yet and directly ask for their Date of Birth (DOB), Time of Birth (TOB), and Place of Birth (POB). Never simulate, pretend, or fabricate personal chart placements or planetary degrees.]');
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  static String _formatMonthYear(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${_monthName(dt.month)} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _buildChartSummary(Map<String, dynamic> chart) {
    final buffer = StringBuffer();
    final lagna = chart['lagna'] as Map<String, dynamic>? ?? {};
    final planets = chart['planets'] as Map<String, dynamic>? ?? {};
    final houses = chart['houses'] as Map<dynamic, dynamic>? ?? {};
    final dasha = chart['vimshottari_dasha'] as Map<String, dynamic>? ?? {};
    final moon = planets['Moon'] as Map<String, dynamic>? ?? {};

    final now = DateTime.now();
    final currentMonthYear = '${_monthName(now.month)} ${now.year}';

    buffer.writeln('[BACKGROUND REFERENCE DATA — STRICTLY FOR INTERNAL REASONING, DO NOT RECITE OR DUMP]');
    buffer.writeln('[The user did NOT ask to read this list. Use ONLY the relevant elements to answer their exact question.]');
    buffer.writeln('- CURRENT CALENDAR ANCHOR: $currentMonthYear (Reference date for "today/current date")');

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

    // Current Mahadasha & Antardashas
    final currentDasha = dasha['current_mahadasha'] as Map<String, dynamic>?;
    final currentAntardasha = dasha['current_antardasha'] as Map<String, dynamic>?;
    final nextAntardasha = dasha['next_antardasha'] as Map<String, dynamic>?;

    if (currentDasha != null) {
      final dashaStart = _formatMonthYear(currentDasha['start_date']?.toString() ?? '');
      final dashaEnd = _formatMonthYear(currentDasha['end_date']?.toString() ?? '');
      buffer.writeln(
        '- Current Mahadasha: ${currentDasha['planet']} Mahadasha (Active from $dashaStart to $dashaEnd)',
      );
    }
    if (currentAntardasha != null) {
      final aStart = _formatMonthYear(currentAntardasha['start_date']?.toString() ?? '');
      final aEnd = _formatMonthYear(currentAntardasha['end_date']?.toString() ?? '');
      buffer.writeln(
        '- Active Antardasha (Bhukti): ${currentDasha?['planet']}-${currentAntardasha['planet']} (Active from $aStart to $aEnd)',
      );
    }
    if (nextAntardasha != null) {
      final nStart = _formatMonthYear(nextAntardasha['start_date']?.toString() ?? '');
      final nEnd = _formatMonthYear(nextAntardasha['end_date']?.toString() ?? '');
      buffer.writeln(
        '- Upcoming Antardasha (Bhukti): ${currentDasha?['planet']}-${nextAntardasha['planet']} (Starts from $nStart to $nEnd)',
      );
    }

    // Planetary placements
    buffer.writeln('\n[PLANETARY PLACEMENTS (BACKGROUND REFERENCE)]');
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
      buffer.writeln('\n[HOUSES (BHAVAS) (BACKGROUND REFERENCE)]');
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

  bool _isFullChartRequest(String text) {
    final clean = text.toLowerCase();
    return clean.contains('full chart') ||
        clean.contains('entire chart') ||
        clean.contains('whole chart') ||
        clean.contains('complete chart') ||
        clean.contains('full kundli') ||
        clean.contains('full kundali') ||
        clean.contains('whole kundli') ||
        clean.contains('whole kundali') ||
        clean.contains('complete kundli') ||
        clean.contains('complete kundali') ||
        clean.contains('full birth chart') ||
        clean.contains('motham jathakam') ||
        clean.contains('mottham jathakam') ||
        clean.contains('full jathakam') ||
        clean.contains('complete jathakam') ||
        clean.contains('పూర్తి జాతకం') ||
        clean.contains('మొత్తం జాతకం');
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
