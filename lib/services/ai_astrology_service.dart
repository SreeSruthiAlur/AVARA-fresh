import 'dart:async';
import 'dart:convert';

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

/// AVARA's Gemini-powered Vedic Astrology conversational engine.
///
/// Talks to the Gemini 3.8 Flash REST API directly over HTTP (no SDK) to keep
/// latency low and avoid the upstream package's role-handling bug. The public
/// API ([sendMessage], [preloadChart], [clearHistory], [chartJson]) is
/// unchanged so callers need no edits.
///
/// ### Two usage modes
/// | Mode | How to start | When to use |
/// |------|-------------|-------------|
/// | **Chat-first** | Just call [sendMessage] | Standalone launch; AVARA asks for birth details when needed and fires the `calculate_birth_chart` tool automatically |
/// | **Chart-first** | Call [preloadChart] then [sendMessage] | After the Birth Profile screen; the pre-computed kundali is injected into the first turn silently |
class AIAstrologyService {
  // -------------------------------------------------------------------------
  // System instruction & tool declaration (compile-time constants)
  // -------------------------------------------------------------------------

  static const String _kSystemInstruction =
      'You are AVARA, an expert Vedic Astrology AI. Answer general astrology '
      'questions conversationally using your pre-trained knowledge. If a user '
      'asks a personal question requiring their specific chart, you MUST '
      'politely ask for their Date (YYYY-MM-DD), Time (HH:MM), and City of '
      'birth. Once provided, call the calculate_birth_chart function to get '
      'their exact planetary coordinates, and use that JSON data to provide a '
      'personalized astrological reading.';

  static const String _kToolName = 'calculate_birth_chart';

  /// OpenAPI-style schema for the `calculate_birth_chart` function, sent to
  /// the v1beta REST `tools[].function_declarations` array. The v1beta REST
  /// API expects uppercase `Schema` type enums (`OBJECT`, `STRING`).
  static const Map<String, Object?> _kToolDeclaration = {
    'name': _kToolName,
    'description': 'Calculates the Vedic Janma Kundali (birth chart) from date, '
        'time, and city of birth. Call this as soon as the user provides their '
        'birth details — do NOT ask for additional confirmation.',
    'parameters': {
      'type': 'OBJECT',
      'properties': {
        'date': {
          'type': 'STRING',
          'description': 'Birth date in YYYY-MM-DD format.',
        },
        'time': {
          'type': 'STRING',
          'description': 'Birth time in HH:MM 24-hour local time. IST '
              '(UTC+5:30) is assumed unless the user specifies otherwise.',
        },
        'city': {
          'type': 'STRING',
          'description': 'City of birth, used for geocoding latitude/longitude.',
        },
      },
      'required': ['date', 'time', 'city'],
    },
  };

  /// Per-POST network budget. On expiry the call surfaces a friendly retry
  /// message to the UI instead of throwing.
  static const Duration _kTimeout = Duration(seconds: 15);

  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  final String _apiKey;
  final ChartGeneratorCallback? _chartGenerator;

  /// The running chat history sent to Gemini on every turn: a list of
  /// `{role, parts}` maps where role is `user`, `model`, or `function`.
  final List<Map<String, dynamic>> _contents = [];

  /// The most recently computed kundali, populated after [preloadChart] or
  /// after the model fires the [_kToolName] function call.
  Map<String, dynamic>? _chartJson;

  /// Prevents the pre-loaded chart from being injected more than once.
  bool _chartInjected = false;

  /// Expose the current chart so the UI can react (e.g. show a chart-viewer).
  Map<String, dynamic>? get chartJson => _chartJson;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  /// Creates an [AIAstrologyService].
  ///
  /// - [apiKey]         : Google AI Studio API key (required).
  /// - [chartGenerator] : Platform callback that runs the sweph math engine.
  ///                      Must be provided for the `calculate_birth_chart` tool
  ///                      to actually compute a chart.
  AIAstrologyService({
    required String apiKey,
    this._chartGenerator,
  })  : // Strip surrounding whitespace and any stray quote characters that
        // can sneak in from .env files or copy-paste.
        _apiKey = apiKey.trim().replaceAll('"', '').replaceAll("'", '') {
    // ignore: avoid_print
    print('DEBUG API KEY: $_apiKey');
    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('DEBUG API KEY: is EMPTY — dotenv did not load the value. '
          'Ensure .env is in the Flutter project root and the app was '
          'fully rebuilt (not just hot-restarted) after editing the file.');
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Pre-loads an already-computed kundali into the service.
  ///
  /// The chart data is silently prepended to the **first** [sendMessage] call
  /// so AVARA can answer personal questions immediately without prompting the
  /// user for birth details again.  Typical use: navigate from the Birth
  /// Profile screen after a kundali has already been calculated.
  void preloadChart(Map<String, dynamic> chartJson) {
    _chartJson = chartJson;
    _chartInjected = false; // will be injected on the next send
  }

  /// Sends [userPrompt] to AVARA and returns the text response.
  ///
  /// Manages the full Gemini function-calling loop internally over the REST
  /// `generateContent` endpoint:
  /// 1. User message is appended to the `contents` history (with chart context
  ///    prepended on the first turn if [preloadChart] was called).
  /// 2. A POST is sent. If the model returns a `functionCall` for
  ///    `calculate_birth_chart`, [_executeCalculateChart] runs the geocoding +
  ///    sweph pipeline, the result is appended as a `functionResponse`, and a
  ///    second POST is fired to get the final reading.
  /// 3. This repeats until the model returns plain text (bounded by a small
  ///    hop cap to avoid runaway loops).
  ///
  /// Each HTTP POST is bounded by [_kTimeout]; on timeout this safely returns
  /// a retry message instead of throwing.
  ///
  /// Throws [AIAstrologyException] on non-timeout API errors, empty responses,
  /// or tool execution failures.
  Future<String> sendMessage(String userPrompt) async {
    try {
      // Inject pre-loaded chart context silently on the first turn.
      final String prompt;
      if (_chartJson != null && !_chartInjected) {
        final chartData = jsonEncode(_jsonSafe(_chartJson!));
        prompt = 'LOADED BIRTH CHART DATA (JSON):\n$chartData'
            '\n\n---\nUSER QUESTION:\n$userPrompt';
        _chartInjected = true;
      } else {
        prompt = userPrompt;
      }

      _contents.add({
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      });

      // Agentic tool-call loop — Gemini may chain calls (double-hop, etc.).
      const maxHops = 6;
      for (var hop = 0; hop < maxHops; hop++) {
        final data = await _generateContent();
        final parts = _extractParts(data);

        // Record the model's turn so the history stays in sync.
        _contents.add({
          'role': 'model',
          'parts': parts,
        });

        final functionCall = _findFunctionCall(parts);
        if (functionCall == null) {
          final text = _extractText(parts);
          if (text == null || text.isEmpty) {
            throw AIAstrologyException(
              'AVARA returned an empty response. Please try again.',
            );
          }
          return text;
        }

        final name = functionCall['name']?.toString();
        if (name != _kToolName) {
          throw AIAstrologyException('Model called an unknown function: $name');
        }

        // Intercept the tool call → run the local sweph math engine → feed
        // the result back as a functionResponse and POST again.
        final args = (functionCall['args'] as Map?)?.cast<String, Object?>() ??
            <String, Object?>{};
        final toolResult = await _executeCalculateChart(args);
        _contents.add({
          'role': 'function',
          'parts': [
            {
              'functionResponse': {
                'name': name,
                'response': {'result': toolResult},
              },
            },
          ],
        });
      }

      throw AIAstrologyException(
        'AVARA is taking too long to respond. Please try again.',
      );
    } on TimeoutException {
      return 'Network timeout. Please try your question again.';
    } on AIAstrologyException {
      rethrow;
    } catch (e) {
      throw AIAstrologyException('Unexpected error while contacting AVARA: $e');
    }
  }

  /// Clears the chat history and any stored chart state, starting a fresh
  /// conversation session.
  void clearHistory() {
    _contents.clear();
    _chartJson = null;
    _chartInjected = false;
  }

  // -------------------------------------------------------------------------
  // REST transport
  // -------------------------------------------------------------------------

  /// POSTs the current `_contents` (+ system instruction + tools) to the
  /// Gemini v1beta `generateContent` endpoint and returns the decoded JSON.
  ///
  /// Bounded by [_kTimeout]; throws [AIAstrologyException] on non-2xx.
  Future<Map<String, dynamic>> _generateContent() async {
    // Read and sanitize the key directly from .env at call time.
    // Only Content-Type is sent — no Authorization header, which would cause
    // a 400 "Multiple Credentials" error when the key is already in the URL.
    final rawKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final cleanKey = rawKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleanKey.isEmpty) {
      throw AIAstrologyException(
        'Gemini API key is not configured. '
        'Open .env and set GEMINI_API_KEY to your Google AI Studio key. '
        'Rebuild the app after saving.',
      );
    }

    // v1beta is required for this JSON payload structure.
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3.8-flash:generateContent?key=$cleanKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _kSystemInstruction},
        ],
      },
      'contents': _contents,
      'tools': [
        {
          'function_declarations': [_kToolDeclaration],
        },
      ],
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(_kTimeout);

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AIAstrologyException(
        'Gemini API error (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    if (response.statusCode != 200) {
      final err = data['error'];
      final errMsg = err is Map ? err['message']?.toString() : response.body;
      throw AIAstrologyException('Gemini API error: $errMsg');
    }
    return data;
  }

  /// Extracts the `candidates[0].content.parts` list from a response.
  List<dynamic> _extractParts(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw AIAstrologyException('AVARA returned no candidates.');
    }
    final content = candidates[0]['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw AIAstrologyException(
        'AVARA returned an empty response. Please try again.',
      );
    }
    return parts;
  }

  /// Returns the first `functionCall` part, if any.
  Map<String, dynamic>? _findFunctionCall(List<dynamic> parts) {
    for (final part in parts) {
      if (part is Map && part['functionCall'] is Map) {
        return (part['functionCall'] as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  /// Concatenates all `text` parts into a single string (null if none).
  String? _extractText(List<dynamic> parts) {
    final buf = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buf.write(part['text'] as String);
      }
    }
    final s = buf.toString();
    return s.isEmpty ? null : s;
  }

  // -------------------------------------------------------------------------
  // Tool execution
  // -------------------------------------------------------------------------

  /// Executes the `calculate_birth_chart` tool call end-to-end:
  /// 1. Parses [args] (`date`, `time`, `city`).
  /// 2. Converts local IST birth time → UTC.
  /// 3. Geocodes [city] via the Nominatim API.
  /// 4. Runs the sweph math engine through [_chartGenerator].
  /// 5. Stores the result in [_chartJson] and returns it as a JSON-safe map
  ///    for the model to read as the function response.
  Future<Map<String, Object?>> _executeCalculateChart(
    Map<String, Object?> args,
  ) async {
    final date = args['date']?.toString() ?? '';
    final time = args['time']?.toString() ?? '';
    final city = args['city']?.toString() ?? '';

    try {
      // 1. Parse date  (YYYY-MM-DD)
      final dateParts = date.split('-');
      if (dateParts.length != 3) {
        return {
          'error': 'Invalid date format — expected YYYY-MM-DD, got "$date".',
        };
      }
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // 2. Parse time (HH:MM) and convert local IST → UTC
      final timeParts = time.split(':');
      if (timeParts.length < 2) {
        return {
          'error': 'Invalid time format — expected HH:MM, got "$time".',
        };
      }
      final localH = int.parse(timeParts[0]);
      final localM = int.parse(timeParts[1]);
      const istOffsetMinutes = 330; // IST = UTC+05:30
      int utcMinutes = (localH * 60 + localM) - istOffsetMinutes;
      int dayDelta = 0;
      if (utcMinutes < 0) {
        utcMinutes += 1440;
        dayDelta = -1;
      } else if (utcMinutes >= 1440) {
        utcMinutes -= 1440;
        dayDelta = 1;
      }
      final utcDate =
          DateTime.utc(year, month, day).add(Duration(days: dayDelta));
      final hourDecimal = utcMinutes ~/ 60 + (utcMinutes % 60) / 60.0;

      // 3. Geocode the city via Nominatim (OpenStreetMap)
      final encoded = Uri.encodeComponent(city);
      final geoUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$encoded&format=json&limit=1',
      );
      final geoResponse = await http.get(geoUri, headers: {
        'User-Agent': 'AVARA-Astrology/1.0 (contact@avara.example)',
      });
      if (geoResponse.statusCode != 200) {
        return {
          'error': 'Geocoding service unavailable (HTTP '
              '${geoResponse.statusCode}). Please try again.',
        };
      }
      final geoResults = (jsonDecode(geoResponse.body) as List);
      if (geoResults.isEmpty) {
        return {
          'error': 'Could not find coordinates for "$city". '
              'Please try a more specific city name.',
        };
      }
      final lat = double.parse(geoResults[0]['lat'].toString());
      final lon = double.parse(geoResults[0]['lon'].toString());
      final resolvedCity = geoResults[0]['display_name']?.toString() ?? city;

      // 4. Run sweph via the injected platform callback
      if (_chartGenerator == null) {
        return {
          'error': 'The chart calculation engine is not available in this '
              'context.',
        };
      }
      final chart = await _chartGenerator(
        year: utcDate.year,
        month: utcDate.month,
        day: utcDate.day,
        hourUtc: hourDecimal,
        lat: lat,
        lon: lon,
      );
      _chartJson = chart;

      // 5. Return JSON-safe chart data to the model as the function response.
      return <String, Object?>{
        'status': 'success',
        'resolved_city': resolvedCity,
        'chart': _jsonSafe(chart) as Object,
      };
    } catch (e) {
      return {'error': 'Chart calculation failed unexpectedly: $e'};
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Recursively converts all [Map] keys to [String] so that [jsonEncode]
  /// never encounters a non-String key (e.g. `int` keys in `rasi_to_planets`
  /// from [TeluguKundaliCalculator]).
  dynamic _jsonSafe(dynamic value) {
    if (value is Map) {
      return value.map(
        (dynamic k, dynamic v) => MapEntry(k.toString(), _jsonSafe(v)),
      );
    }
    if (value is List) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value;
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Exception thrown by [AIAstrologyService] on inference or tool-call errors.
class AIAstrologyException implements Exception {
  /// Human-readable error description.
  final String message;

  /// The underlying exception that caused this, if any.
  final Object? cause;

  const AIAstrologyException(this.message, {this.cause});

  @override
  String toString() => cause != null
      ? 'AIAstrologyException: $message\n  Caused by: $cause'
      : 'AIAstrologyException: $message';
}
