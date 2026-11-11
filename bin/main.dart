import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avara_astrology_trial/telugu_kundali.dart';

Future<void> main() async {
  print('AVARA - Telugu Kundali Calculator (Interactive)');
  print('=================================================\n');

  // 1. Get Date of Birth
  stdout.write('Enter Date of Birth (YYYY-MM-DD): ');
  final dobInput = stdin.readLineSync()?.trim();
  if (dobInput == null || dobInput.isEmpty) {
    stderr.writeln('Error: Date of birth is required.');
    exit(1);
  }

  final dobParts = dobInput.split('-');
  if (dobParts.length != 3) {
    stderr.writeln('Error: Invalid date format. Use YYYY-MM-DD.');
    exit(1);
  }
  int year = int.tryParse(dobParts[0]) ?? 0;
  int month = int.tryParse(dobParts[1]) ?? 0;
  int day = int.tryParse(dobParts[2]) ?? 0;
  if (year == 0 || month < 1 || month > 12 || day < 1 || day > 31) {
    stderr.writeln('Error: Invalid date values.');
    exit(1);
  }

  // 2. Get Time of Birth (Local Time)
  stdout.write('Enter Time of Birth (HH:MM in 24-hour Local Time): ');
  final timeInput = stdin.readLineSync()?.trim();
  if (timeInput == null || timeInput.isEmpty) {
    stderr.writeln('Error: Time of birth is required.');
    exit(1);
  }

  final timeParts = timeInput.split(':');
  if (timeParts.length != 2) {
    stderr.writeln('Error: Invalid time format. Use HH:MM (24-hour).');
    exit(1);
  }
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if (hour == null || minute == null ||
      hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    stderr.writeln('Error: Invalid time values. Hour 0-23, Minute 0-59.');
    exit(1);
  }

  // 2b. Get Time Zone Offset from UTC
  stdout.write('Enter Time Zone Offset from UTC (e.g., +5.5 for IST, -4.0 for EST): ');
  final tzInput = stdin.readLineSync()?.trim();
  if (tzInput == null || tzInput.isEmpty) {
    stderr.writeln('Error: Time zone offset is required.');
    exit(1);
  }
  final tzOffset = double.tryParse(tzInput);
  if (tzOffset == null || tzOffset < -12.0 || tzOffset > 14.0) {
    stderr.writeln('Error: Invalid time zone offset. Must be between -12 and +14.');
    exit(1);
  }

  // Convert Local Time to UTC
  final localMinutes = hour * 60 + minute;
  final offsetMinutes = (tzOffset * 60).round();
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

  final utcHour = utcMinutes ~/ 60;
  final utcMinute = utcMinutes % 60;
  final hourDecimal = utcHour + utcMinute / 60.0;

  if (dayDelta != 0) {
    final dateTime = DateTime.utc(year, month, day);
    final adjustedDate = dateTime.add(Duration(days: dayDelta));
    year = adjustedDate.year;
    month = adjustedDate.month;
    day = adjustedDate.day;
    print('\nTime zone adjustment applied:');
    print('  Local: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (UTC${tzOffset >= 0 ? '+' : ''}$tzOffset)');
    print('  UTC:   ${utcHour.toString().padLeft(2, '0')}:${utcMinute.toString().padLeft(2, '0')} on $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
  }

  // 2c. Select Ayanamsa
  stdout.write('\nSelect Ayanamsa (1: Lahiri, 2: Raman, 3: KP): ');
  final ayanInput = stdin.readLineSync()?.trim();
  final ayanamsaChoice = int.tryParse(ayanInput ?? '1') ?? 1;

  // 3. Get Place of Birth
  stdout.write('\nEnter Place of Birth (City, State, Country): ');
  final placeInput = stdin.readLineSync()?.trim();
  if (placeInput == null || placeInput.isEmpty) {
    stderr.writeln('Error: Place of birth is required.');
    exit(1);
  }

  // 4. Geocode using Nominatim
  print('\nGeocoding location...');
  final encodedPlace = Uri.encodeComponent(placeInput);
  final nominatimUrl = 'https://nominatim.openstreetmap.org/search?q=$encodedPlace&format=json&limit=1';
  
  final response = await http.get(
    Uri.parse(nominatimUrl),
    headers: {'User-Agent': 'AVARA-Astrology/1.0 (contact@avara.example)'},
  );

  if (response.statusCode != 200) {
    stderr.writeln('Error: Geocoding request failed (${response.statusCode}).');
    exit(1);
  }

  final results = json.decode(response.body) as List;
  if (results.isEmpty) {
    stderr.writeln('Error: Could not find coordinates for "$placeInput".');
    exit(1);
  }

  final lat = double.tryParse(results[0]['lat'].toString());
  final lon = double.tryParse(results[0]['lon'].toString());
  if (lat == null || lon == null) {
    stderr.writeln('Error: Invalid coordinates received.');
    exit(1);
  }

  print('Found: ${results[0]['display_name']}');
  print('Coordinates: $lat, $lon\n');

  // 5. Calculate Full Vedic Kundali
  final calculator = TeluguKundaliCalculator(ayanamsa: ayanamsaChoice);
  final kundali = await calculator.calculateFullKundali(
    year,
    month,
    day,
    hourDecimal,
    lat,
    lon,
  );

  final moon = kundali['planets']['Moon'] as Map<String, dynamic>;
  final lagnaObj = kundali['lagna'] as Map<String, dynamic>;

  // 6. Print the South Indian Chart
  print('═' * 60);
  print('      JANAMA KUNDALI - SOUTH INDIAN CHART FORMAT');
  print('═' * 60);
  print(kundali['south_indian_chart'] as String);

  // 7. Print Rasi & Nakshatra Summary
  print('\n${'═' * 60}');
  print('                RASI & NAKSHATRA');
  print('═' * 60);
  print('Moon Rasi:     ${moon['rasi_name_telugu']} (${moon['rasi_name_sanskrit']})');
  print('Moon Nakshatra: ${moon['nakshatra_name_telugu']} (${moon['nakshatra_name_sanskrit']})');
  print('Pada:          ${moon['pada']}');
  print('Nakshatra Lord: ${moon['nakshatra_lord']}');
  print('Lagna:         ${lagnaObj['rasi_name_telugu']} (${lagnaObj['rasi_name_sanskrit']}) - ${lagnaObj['degrees_in_rasi'].toStringAsFixed(2)}°');
  print('Lagna Nakshatra: ${lagnaObj['nakshatra_name_telugu']} (${lagnaObj['nakshatra_name_sanskrit']}) - Pada ${lagnaObj['pada']}');

  // 8. Code snippet output
  print('\n${'═' * 60}');
  print('                RASI & NAKSHATRA (CODE SNIPPET)');
  print('═' * 60);
  print('```');
  print('rasi: "${moon['rasi_name_telugu']}"');
  print('nakshatra: "${moon['nakshatra_name_telugu']}"');
  print('pada: ${moon['pada']}');
  print('nakshatra_lord: "${moon['nakshatra_lord']}"');
  print('moon_rasi_telugu: "${moon['rasi_name_telugu']}"');
  print('moon_nakshatra_telugu: "${moon['nakshatra_name_telugu']}"');
  print('lagna_rasi_telugu: "${lagnaObj['rasi_name_telugu']}"');
  print('lagna_nakshatra_telugu: "${lagnaObj['nakshatra_name_telugu']}"');
  print('lagna_pada: ${lagnaObj['pada']}');
  print('```');

  // 9. Print Planet Details Table
  print('\nPLANETARY POSITIONS (Sidereal - ${kundali['ayanamsa_name']} Ayanamsa)');
  print('─' * 80);
  print('${'Planet'.padRight(10)} ${'Rasi'.padRight(12)} ${'Deg'.padRight(8)} ${'Nakshatra'.padRight(14)} ${'Pada'.padRight(5)} ${'Retro'}');
  print('─' * 80);

  final planets = kundali['planets'] as Map<String, Map<String, dynamic>>;
  final planetOrder = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
  
  for (final name in planetOrder) {
    final p = planets[name]!;
    final rasi = p['rasi_name_telugu'] as String;
    final deg = (p['degrees_in_rasi'] as double).toStringAsFixed(2);
    final nak = p['nakshatra_name_telugu'] as String;
    final pada = p['pada'] as int;
    final retro = p['is_retrograde'] as bool ? 'Rx' : '';
    print('${name.padRight(10)} ${rasi.padRight(12)} ${deg.padRight(8)} ${nak.padRight(14)} ${pada.toString().padRight(5)} $retro');
  }

  print('${'Lagna'.padRight(10)} ${lagnaObj['rasi_name_telugu'].padRight(12)} ${lagnaObj['degrees_in_rasi'].toStringAsFixed(2).padRight(8)} ${lagnaObj['nakshatra_name_telugu'].padRight(14)} ${lagnaObj['pada'].toString().padRight(5)}');

  print('─' * 80);
  print('Lagna (Sidereal): ${(lagnaObj['sidereal_longitude'] as double).toStringAsFixed(6)}°');
  print('Ayanamsa (${kundali['ayanamsa_name']}): ${(kundali['ayanamsa'] as double).toStringAsFixed(6)}°');
  print('Julian Day: ${kundali['julian_day']}');
  print('Time (UTC): ${kundali['timestamp_utc']}');
}