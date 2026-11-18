import 'dart:convert';

void main() {
  // Mirrors the shape of TeluguKundaliCalculator.calculateFullKundali output.
  final kundali = <String, dynamic>{
    'timestamp_utc': '1990-06-15T10:00:00.000Z',
    'ayanamsa_name': 'Lahiri',
    'ayanamsa': 23.85,
    'location': <String, dynamic>{'latitude': 17.38, 'longitude': 78.48},
    'planets': <String, Map<String, dynamic>>{
      'Moon': <String, dynamic>{
        'rasi_name_telugu': 'Mithuna',
        'nakshatra_name_telugu': 'Punarvasu',
        'rasi_index': 2,
        'pada': 3,
        'is_retrograde': false,
      },
    },
    'rasi_to_planets': <int, List<String>>{
      0: ['Su'],
      2: ['Mo', 'As'],
      7: ['MaR'],
    },
    'south_indian_chart': '+----+\n|Mo  |\n+----+',
  };
  print(const JsonEncoder.withIndent('  ').convert(_jsonSafe(kundali)));
}

dynamic _jsonSafe(dynamic value) {
  if (value is Map) {
    return value.map(
        (dynamic k, dynamic v) => MapEntry(k.toString(), _jsonSafe(v)));
  }
  if (value is List) {
    return value.map(_jsonSafe).toList(growable: false);
  }
  return value;
}

