import 'dart:convert';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistence, retrieval, and caching of the user's birth details
/// and calculated Vedic birth chart (Janma Kundali).
class BirthProfileManager {
  BirthProfileManager._();

  static final BirthProfileManager instance = BirthProfileManager._();

  static const String _kBirthDate = 'avara_birth_date';
  static const String _kBirthTime = 'avara_birth_time';
  static const String _kBirthPlace = 'avara_birth_place';
  static const String _kChartJson = 'avara_kundali_chart_json';

  /// In-memory cache for speed during active session.
  Map<String, dynamic>? _cachedChart;
  String? _cachedDate;
  String? _cachedTime;
  String? _cachedPlace;

  Map<String, dynamic>? get cachedChart => _cachedChart;
  String? get cachedDate => _cachedDate;
  String? get cachedTime => _cachedTime;
  String? get cachedPlace => _cachedPlace;

  /// True if birth details are available in memory or local storage.
  bool get hasBirthDetails =>
      (_cachedDate != null && _cachedDate!.isNotEmpty) &&
      (_cachedPlace != null && _cachedPlace!.isNotEmpty);

  /// Loads stored birth details and cached chart from local storage or backend.
  Future<Map<String, String>?> loadBirthDetails() async {
    String? date = _cachedDate;
    String? time = _cachedTime;
    String? place = _cachedPlace;

    try {
      final prefs = await SharedPreferences.getInstance();

      date = prefs.getString(_kBirthDate) ?? date;
      time = prefs.getString(_kBirthTime) ?? time;
      place = prefs.getString(_kBirthPlace) ?? place;

      // If local preferences don't have it, check backend /profile/me if authenticated
      if (date == null || date.isEmpty || place == null || place.isEmpty) {
        try {
          if (await AvaraApiClient.instance.isAuthenticated) {
            final res = await AvaraApiClient.instance.get('/profile/me');
            if (res is Map<String, dynamic>) {
              final bDate = res['birth_date']?.toString();
              final bTime = res['birth_time']?.toString();
              final bPlace = res['birth_place']?.toString();

              if (bDate != null && bDate.isNotEmpty) {
                date = bDate;
                await prefs.setString(_kBirthDate, bDate);
              }
              if (bTime != null && bTime.isNotEmpty) {
                time = bTime;
                await prefs.setString(_kBirthTime, bTime);
              }
              if (bPlace != null && bPlace.isNotEmpty) {
                place = bPlace;
                await prefs.setString(_kBirthPlace, bPlace);
              }
            }
          }
        } catch (_) {}
      }

      _cachedDate = date;
      _cachedTime = time;
      _cachedPlace = place;

      // Load cached chart if present
      final chartStr = prefs.getString(_kChartJson);
      if (chartStr != null && chartStr.isNotEmpty) {
        try {
          _cachedChart = jsonDecode(chartStr) as Map<String, dynamic>;
        } catch (_) {}
      }
    } catch (_) {
      // SharedPreferences unavailable or in test environment without mock
    }

    if (date != null && date.isNotEmpty && place != null && place.isNotEmpty) {
      return {
        'birth_date': date,
        'birth_time': time ?? '',
        'birth_place': place,
      };
    }
    return null;
  }

  /// Saves the confirmed birth details to SharedPreferences and backend `/profile/me`.
  Future<void> saveBirthDetails({
    required String birthDate,
    required String birthTime,
    required String birthPlace,
    Map<String, dynamic>? chartJson,
  }) async {
    _cachedDate = birthDate;
    _cachedTime = birthTime;
    _cachedPlace = birthPlace;
    if (chartJson != null) {
      _cachedChart = chartJson;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBirthDate, birthDate);
      await prefs.setString(_kBirthTime, birthTime);
      await prefs.setString(_kBirthPlace, birthPlace);

      if (chartJson != null) {
        try {
          await prefs.setString(_kChartJson, jsonEncode(_jsonSafe(chartJson)));
        } catch (_) {}
      }
    } catch (_) {}

    // Best-effort sync with backend
    try {
      if (await AvaraApiClient.instance.isAuthenticated) {
        await AvaraApiClient.instance.patch('/profile/me', body: {
          'birth_date': birthDate,
          'birth_time': birthTime,
          'birth_place': birthPlace,
        });
      }
    } catch (_) {}
  }

  /// Updates or clears stored details.
  Future<void> clear() async {
    _cachedChart = null;
    _cachedDate = null;
    _cachedTime = null;
    _cachedPlace = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBirthDate);
      await prefs.remove(_kBirthTime);
      await prefs.remove(_kBirthPlace);
      await prefs.remove(_kChartJson);
    } catch (_) {}
  }

  /// Sets the active chart in memory.
  void setChart(Map<String, dynamic> chart) {
    _cachedChart = chart;
  }

  static dynamic _jsonSafe(dynamic value) {
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
