import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodeResult {
  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
}

/// Geocoding service with pre-populated major cities and Nominatim fallback.
class AvaraGeocoder {
  AvaraGeocoder._();

  static final Map<String, GeocodeResult> _cityCache = {
    'bengaluru': const GeocodeResult(latitude: 12.9716, longitude: 77.5946, displayName: 'Bengaluru, Karnataka, India'),
    'bangalore': const GeocodeResult(latitude: 12.9716, longitude: 77.5946, displayName: 'Bengaluru, Karnataka, India'),
    'hyderabad': const GeocodeResult(latitude: 17.3850, longitude: 78.4867, displayName: 'Hyderabad, Telangana, India'),
    'chennai': const GeocodeResult(latitude: 13.0827, longitude: 80.2707, displayName: 'Chennai, Tamil Nadu, India'),
    'madras': const GeocodeResult(latitude: 13.0827, longitude: 80.2707, displayName: 'Chennai, Tamil Nadu, India'),
    'mumbai': const GeocodeResult(latitude: 19.0760, longitude: 72.8777, displayName: 'Mumbai, Maharashtra, India'),
    'bombay': const GeocodeResult(latitude: 19.0760, longitude: 72.8777, displayName: 'Mumbai, Maharashtra, India'),
    'delhi': const GeocodeResult(latitude: 28.6139, longitude: 77.2090, displayName: 'New Delhi, Delhi, India'),
    'new delhi': const GeocodeResult(latitude: 28.6139, longitude: 77.2090, displayName: 'New Delhi, Delhi, India'),
    'kolkata': const GeocodeResult(latitude: 22.5726, longitude: 88.3639, displayName: 'Kolkata, West Bengal, India'),
    'calcutta': const GeocodeResult(latitude: 22.5726, longitude: 88.3639, displayName: 'Kolkata, West Bengal, India'),
    'tirupati': const GeocodeResult(latitude: 13.6288, longitude: 79.4192, displayName: 'Tirupati, Andhra Pradesh, India'),
    'vijayawada': const GeocodeResult(latitude: 16.5062, longitude: 80.6480, displayName: 'Vijayawada, Andhra Pradesh, India'),
    'visakhapatnam': const GeocodeResult(latitude: 17.6868, longitude: 83.2185, displayName: 'Visakhapatnam, Andhra Pradesh, India'),
    'vizag': const GeocodeResult(latitude: 17.6868, longitude: 83.2185, displayName: 'Visakhapatnam, Andhra Pradesh, India'),
    'guntur': const GeocodeResult(latitude: 16.3067, longitude: 80.4365, displayName: 'Guntur, Andhra Pradesh, India'),
    'warangal': const GeocodeResult(latitude: 17.9689, longitude: 79.5941, displayName: 'Warangal, Telangana, India'),
    'nellore': const GeocodeResult(latitude: 14.4426, longitude: 79.9865, displayName: 'Nellore, Andhra Pradesh, India'),
    'kurnool': const GeocodeResult(latitude: 15.8281, longitude: 78.0373, displayName: 'Kurnool, Andhra Pradesh, India'),
    'pune': const GeocodeResult(latitude: 18.5204, longitude: 73.8567, displayName: 'Pune, Maharashtra, India'),
    'ahmedabad': const GeocodeResult(latitude: 23.0225, longitude: 72.5714, displayName: 'Ahmedabad, Gujarat, India'),
    'jaipur': const GeocodeResult(latitude: 26.9124, longitude: 75.7873, displayName: 'Jaipur, Rajasthan, India'),
    'lucknow': const GeocodeResult(latitude: 26.8467, longitude: 80.9462, displayName: 'Lucknow, Uttar Pradesh, India'),
    'london': const GeocodeResult(latitude: 51.5074, longitude: -0.1278, displayName: 'London, United Kingdom'),
    'new york': const GeocodeResult(latitude: 40.7128, longitude: -74.0060, displayName: 'New York, NY, USA'),
    'san francisco': const GeocodeResult(latitude: 37.7749, longitude: -122.4194, displayName: 'San Francisco, CA, USA'),
    'singapore': const GeocodeResult(latitude: 1.3521, longitude: 103.8198, displayName: 'Singapore'),
    'dubai': const GeocodeResult(latitude: 25.2048, longitude: 55.2708, displayName: 'Dubai, United Arab Emirates'),
  };

  /// Geocodes [place] to latitude and longitude.
  static Future<GeocodeResult> geocode(String place) async {
    final clean = place.toLowerCase().trim();

    // Check fast cache first
    for (final entry in _cityCache.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }

    // Attempt Nominatim query with a fast timeout
    try {
      final encoded = Uri.encodeComponent(place);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'AVARA-Astrology/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.parse(first['lat'].toString());
          final lon = double.parse(first['lon'].toString());
          final name = first['display_name']?.toString() ?? place;
          final result = GeocodeResult(latitude: lat, longitude: lon, displayName: name);
          _cityCache[clean] = result;
          return result;
        }
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Default fallback to central India (Hyderabad / IST anchor)
    return GeocodeResult(
      latitude: 17.3850,
      longitude: 78.4867,
      displayName: place,
    );
  }
}
