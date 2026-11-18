import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sweph/sweph.dart';

/// `true` when running in a web (JS/WASM) environment. See `telugu_kundali.dart`
/// for the rationale behind defining this locally instead of importing Flutter.
const bool kIsWeb = bool.fromEnvironment('dart.library.js_interop');

/// A class for calculating natal birth charts using the Swiss Ephemeris.
class ChartCalculator {
  bool _initialized = false;
  String? _modulePath;

  /// Creates a new ChartCalculator.
  ///
  /// Optionally provide a [modulePath] to the native sweph library (sweph.dll on Windows,
  /// libsweph.so on Linux). If null, attempts to locate it in the pub cache.
  ChartCalculator({String? modulePath}) : _modulePath = modulePath;

  /// Initializes the Swiss Ephemeris library.
  Future<void> initialize() async {
    if (_initialized) return;

    _modulePath ??= _findNativeLibrary();

    await Sweph.init(modulePath: _modulePath);
    _initialized = true;
  }

  /// Attempts to locate the native sweph library in the pub cache.
  String? _findNativeLibrary() {
    // On the web there is no native library and `dart:io`'s `Platform` throws,
    // so skip native path extraction entirely and let sweph load via WASM.
    if (kIsWeb) {
      return null;
    }
    if (Platform.isWindows) {
      final dll = File(p.join(
        Platform.environment['USERPROFILE'] ?? '',
        'AppData',
        'Local',
        'Pub',
        'Cache',
        'hosted',
        'pub.dev',
        'sweph-3.2.1+2.10.3',
        'example.dart',
        'sweph.dll',
      ));
      if (dll.existsSync()) return dll.path;
    } else if (Platform.isLinux) {
      final so = File(p.join(
        Platform.environment['HOME'] ?? '',
        '.pub-cache',
        'hosted',
        'pub.dev',
        'sweph-3.2.1+2.10.3',
        'example.dart',
        'libsweph.so',
      ));
      if (so.existsSync()) return so.path;
    } else if (Platform.isMacOS) {
      final dylib = File(p.join(
        Platform.environment['HOME'] ?? '',
        '.pub-cache',
        'hosted',
        'pub.dev',
        'sweph-3.2.1+2.10.3',
        'example.dart',
        'libsweph.dylib',
      ));
      if (dylib.existsSync()) return dylib.path;
    }
    return null;
  }

  /// Generates a complete birth chart for the given date, time, and location.
  ///
  /// Parameters:
  /// - [year]: Year (e.g., 1990)
  /// - [month]: Month (1-12)
  /// - [day]: Day (1-31)
  /// - [hour]: Hour in 24-hour format, UTC (e.g., 14.5 for 2:30 PM)
  /// - [lat]: Latitude in degrees (positive = North, negative = South)
  /// - [lon]: Longitude in degrees (positive = East, negative = West)
  ///
  /// Returns a Map containing planetary longitudes and the Ascendant,
  /// ready to be encoded as JSON.
  Future<Map<String, dynamic>> generateBirthChart(
    int year,
    int month,
    int day,
    double hour,
    double lat,
    double lon,
  ) async {
    await initialize();

    // Calculate Julian Day in UTC
    final julianDay = Sweph.swe_julday(year, month, day, hour, CalendarType.SE_GREG_CAL);

    // Flags for calculation: use Swiss Ephemeris, calculate speed
    final flags = SwephFlag.SEFLG_SPEED | SwephFlag.SEFLG_SWIEPH;

    // Calculate planetary positions
    final planets = {
      'Sun': HeavenlyBody.SE_SUN,
      'Moon': HeavenlyBody.SE_MOON,
      'Mercury': HeavenlyBody.SE_MERCURY,
      'Venus': HeavenlyBody.SE_VENUS,
      'Mars': HeavenlyBody.SE_MARS,
      'Jupiter': HeavenlyBody.SE_JUPITER,
      'Saturn': HeavenlyBody.SE_SATURN,
    };

    final Map<String, dynamic> chart = {
      'julian_day': julianDay,
      'timestamp_utc': _formatTimestamp(year, month, day, hour),
      'location': {'latitude': lat, 'longitude': lon},
      'planets': <String, dynamic>{},
      'houses': <String, dynamic>{},
    };

    // Calculate each planet's position
    for (final entry in planets.entries) {
      final name = entry.key;
      final body = entry.value;

      final result = Sweph.swe_calc_ut(julianDay, body, flags);
      final normalizedLon = _normalizeLongitude(result.longitude);

      chart['planets'][name] = {
        'longitude': normalizedLon,
        'latitude': result.latitude,
        'distance_au': result.distance,
        'speed_longitude': result.speedInLongitude,
        'speed_latitude': result.speedInLatitude,
        'speed_distance': result.speedInDistance,
        'sign': _getZodiacSign(normalizedLon),
        'degrees_in_sign': _getDegreesInSign(normalizedLon),
      };
    }

    // Calculate houses and Ascendant using Placidus system
    final houses = Sweph.swe_houses(julianDay, lat, lon, Hsys.P);

    // ascmc array: [Ascendant, MC, ARMC, Vertex, EquAsc, CoAsc1, CoAsc2, PolAsc]
    final ascendantLon = _normalizeLongitude(houses.ascmc[0]);
    final mcLon = _normalizeLongitude(houses.ascmc[1]);

    chart['houses']['ascendant'] = {
      'longitude': ascendantLon,
      'sign': _getZodiacSign(ascendantLon),
      'degrees_in_sign': _getDegreesInSign(ascendantLon),
    };

    chart['houses']['midheaven'] = {
      'longitude': mcLon,
      'sign': _getZodiacSign(mcLon),
      'degrees_in_sign': _getDegreesInSign(mcLon),
    };

    // House cusps (12 houses, index 1-12 in cusps array)
    final houseCusps = <Map<String, dynamic>>[];
    for (int i = 1; i <= 12; i++) {
      final cuspLon = _normalizeLongitude(houses.cusps[i]);
      houseCusps.add({
        'house': i,
        'longitude': cuspLon,
        'sign': _getZodiacSign(cuspLon),
        'degrees_in_sign': _getDegreesInSign(cuspLon),
      });
    }
    chart['houses']['cusps'] = houseCusps;

    return chart;
  }

  /// Normalizes longitude to 0-360 degrees.
  double _normalizeLongitude(double lon) {
    lon = lon % 360.0;
    if (lon < 0) lon += 360.0;
    return lon;
  }

  /// Returns the zodiac sign index (0-11) for a given longitude.
  int _getZodiacSign(double lon) {
    return (lon / 30.0).floor() % 12;
  }

  /// Returns degrees within the sign (0-30).
  double _getDegreesInSign(double lon) {
    return lon % 30.0;
  }

  /// Formats the timestamp as ISO 8601 UTC string.
  String _formatTimestamp(int year, int month, int day, double hour) {
    final h = hour.floor();
    final min = ((hour - h) * 60).floor();
    final sec = (((hour - h) * 60) - min) * 60;
    return DateTime.utc(year, month, day, h, min, sec.floor(), (sec * 1000).floor() % 1000)
        .toIso8601String();
  }

  /// Returns the zodiac sign name for a given sign index.
  static String getSignName(int signIndex) {
    const signs = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
    ];
    return signs[signIndex % 12];
  }

  /// Returns a formatted string representation of a planetary position.
  static String formatPosition(Map<String, dynamic> planet) {
    final lon = planet['longitude'] as double;
    final signIdx = planet['sign'] as int;
    final degInSign = planet['degrees_in_sign'] as double;
    final deg = degInSign.floor();
    final min = ((degInSign - deg) * 60).floor();
    final sec = (((degInSign - deg) * 60) - min) * 60;
    return '${getSignName(signIdx)} ${deg}°${min}\'${sec.toStringAsFixed(1)}\"';
  }
}