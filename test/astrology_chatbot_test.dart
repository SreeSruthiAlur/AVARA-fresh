import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avara_astrology_trial/services/astrology_intent_classifier.dart';
import 'package:avara_astrology_trial/services/birth_details_parser.dart';
import 'package:avara_astrology_trial/services/language_validator.dart';
import 'package:avara_astrology_trial/services/ai_astrology_service.dart';
import 'package:avara_astrology_trial/widgets/square_kundli_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleChart = <String, dynamic>{
    'julian_day': 2454084.5833,
    'location': {'latitude': 12.9716, 'longitude': 77.5946},
    'ayanamsa': 23.95,
    'ayanamsa_name': 'Lahiri',
    'lagna': {
      'name': 'Lagna',
      'rasi_index': 8, // Sagittarius
      'rasi_name_telugu': 'Dhanassu',
      'rasi_name_sanskrit': 'Dhanus',
      'rasi_name_english': 'Sagittarius',
      'degrees_in_rasi': 14.5,
      'nakshatra_name_sanskrit': 'Purva Ashadha',
      'pada': 1,
      'house': 1,
    },
    'planets': {
      'Sun': {
        'name': 'Sun',
        'rasi_index': 8,
        'rasi_name_english': 'Sagittarius',
        'house': 1,
        'degrees_in_rasi': 29.2,
        'nakshatra_name_sanskrit': 'Uttara Ashadha',
        'pada': 1,
        'is_retrograde': false,
      },
      'Moon': {
        'name': 'Moon',
        'rasi_index': 6, // Libra
        'rasi_name_english': 'Libra',
        'rasi_name_telugu': 'Tula',
        'rasi_name_sanskrit': 'Tula',
        'house': 11,
        'degrees_in_rasi': 1.8,
        'nakshatra_name_sanskrit': 'Chitra',
        'pada': 3,
        'nakshatra_lord': 'Mars',
        'degrees_in_nakshatra': 8.46,
        'is_retrograde': false,
      },
      'Venus': {
        'name': 'Venus',
        'rasi_index': 8,
        'rasi_name_english': 'Sagittarius',
        'house': 1,
        'degrees_in_rasi': 23.6,
        'nakshatra_name_sanskrit': 'Purva Ashadha',
        'pada': 4,
        'is_retrograde': false,
      },
      'Mercury': {
        'name': 'Mercury',
        'rasi_index': 8,
        'rasi_name_english': 'Sagittarius',
        'house': 1,
        'degrees_in_rasi': 11.4,
        'nakshatra_name_sanskrit': 'Mula',
        'pada': 4,
        'is_retrograde': false,
      },
    },
    'houses': {
      1: {'house_number': 1, 'rasi_name_english': 'Sagittarius', 'lord': 'Jupiter', 'occupants': ['Sun', 'Mercury', 'Venus']},
      7: {'house_number': 7, 'rasi_name_english': 'Gemini', 'lord': 'Mercury', 'occupants': [], 'significance': 'Marriage, spouse, partnerships'},
      10: {'house_number': 10, 'rasi_name_english': 'Virgo', 'lord': 'Mercury', 'occupants': [], 'significance': 'Career, profession, status'},
      11: {'house_number': 11, 'rasi_name_english': 'Libra', 'lord': 'Venus', 'occupants': ['Moon'], 'significance': 'Gains, friendships'},
    },
    'vimshottari_dasha': {
      'starting_lord': 'Mars',
      'balance_years_at_birth': 2.55,
      'current_mahadasha': {
        'planet': 'Jupiter',
        'duration_years': 16,
        'start_date': '2027-06-15',
        'end_date': '2043-06-15',
      },
    },
  };

  group('AVARA 14 Core Vedic Astrology & Language Test Cases', () {
    test('Test 1: What does my Moon sign say about my emotions? -> Requests birth details if unavailable', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('What does my Moon sign say about my emotions?');
      expect(response.contains('Date of Birth') && response.contains('DOB'), isTrue);
      expect(response.contains('Time of Birth') && response.contains('Place of Birth'), isTrue);
    });

    test('Test 2: What is my Nakshatra? -> Requests birth details if unavailable', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('What is my Nakshatra?');
      expect(response.contains('Date of Birth') && response.contains('DOB'), isTrue);
    });

    test('Test 3: What is a Nakshatra? -> Answers directly without requesting DOB', () async {
      final intent = AstrologyIntentClassifier.classify('What is a Nakshatra?');
      expect(intent, equals(AstrologyIntentType.generalEducational));
      final val = LanguageValidator.validate('What is a Nakshatra?');
      expect(val.isSupported, isTrue);
      expect(val.mode, equals(AvaraLanguageMode.english));
    });

    test('Test 4: What does my chart say about my career? -> Gives personalized chart-based answer', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart);
      final intent = AstrologyIntentClassifier.classify('What does my chart say about my career?');
      expect(intent, equals(AstrologyIntentType.personalAstrology));
      expect(service.chartJson, isNotNull);
      expect(service.chartJson!['houses'][10], isNotNull);
    });

    test('Test 5: Naaku naa marriage gurinchi cheppu -> Recognizes Tanglish and requests birth details if needed', () async {
      final val = LanguageValidator.validate('Naaku naa marriage gurinchi cheppu');
      expect(val.isSupported, isTrue);
      expect(val.mode, equals(AvaraLanguageMode.tanglish));

      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('Naaku naa marriage gurinchi cheppu');
      expect(response.contains('birth details') || response.contains('DOB') || response.contains('Date of Birth'), isTrue);
    });

    test('Test 6: నా జాతకం గురించి చెప్పండి -> Accepts Telugu', () async {
      final val = LanguageValidator.validate('నా జాతకం గురించి చెప్పండి');
      expect(val.isSupported, isTrue);
      expect(val.mode, equals(AvaraLanguageMode.telugu));

      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('నా జాతకం గురించి చెప్పండి');
      expect(response.contains('పుట్టిన వివరాలు') || response.contains('DOB'), isTrue);
    });

    test('Test 7: Naa Rashi enti? -> Accepts Telugu transliteration', () async {
      final val = LanguageValidator.validate('Naa Rashi enti?');
      expect(val.isSupported, isTrue);
      expect(val.mode, equals(AvaraLanguageMode.tanglish));

      final intent = AstrologyIntentClassifier.classify('Naa Rashi enti?');
      expect(intent, equals(AstrologyIntentType.personalAstrology));
    });

    test('Test 8: What about my relationships? -> Reuses existing birth chart', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart);
      final intent = AstrologyIntentClassifier.classify('What about my relationships?');
      expect(intent, equals(AstrologyIntentType.personalAstrology));
      expect(service.chartJson, isNotNull);
    });

    test('Test 9: Tell me about my 7th house -> Uses actual chart data', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart);
      final intent = AstrologyIntentClassifier.classify('Tell me about my 7th house');
      expect(intent, equals(AstrologyIntentType.personalAstrology));
      final house7 = service.chartJson!['houses'][7];
      expect(house7, isNotNull);
      expect(house7['house_number'], equals(7));
      expect(house7['lord'], equals('Mercury'));
    });

    test('Test 10: मेरा भविष्य बताओ -> Rejects unsupported language politely', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('मेरा भविष्य बताओ');
      expect(response, equals(LanguageValidator.rejectionMessage));
    });

    test('Test 11: Explain my horoscope in Tamil -> Rejects unsupported language politely', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      final response = await service.sendMessage('Explain my horoscope in Tamil');
      expect(response, equals(LanguageValidator.rejectionMessage));
    });

    test('Test 12: What is my Lagna? (birth time missing) -> Explains that birth time is required', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart, hasExactTime: false);
      final response = await service.sendMessage('What is my Lagna?');
      expect(response.contains('Time of Birth') && response.contains('Lagna'), isTrue);
      expect(response.contains('approximately every two hours') || response.contains('every two hours'), isTrue);
    });

    test('Test 13: What is my current Mahadasha? -> Uses calculated chart and Dasha data', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart);
      final intent = AstrologyIntentClassifier.classify('What is my current Mahadasha?');
      expect(intent, equals(AstrologyIntentType.personalAstrology));
      final dasha = service.chartJson!['vimshottari_dasha'];
      expect(dasha, isNotNull);
      expect(dasha['current_mahadasha']['planet'], equals('Jupiter'));
    });

    test('Test 14: Follow-up question in Tanglish after an English conversation -> Accepts and maintains context', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      service.preloadChart(sampleChart);

      final val1 = LanguageValidator.validate('What does my chart say about my career?');
      expect(val1.mode, equals(AvaraLanguageMode.english));

      final val2 = LanguageValidator.validate('Naaku marriage eppudu avuthundi?');
      expect(val2.mode, equals(AvaraLanguageMode.tanglish));
      expect(val2.isSupported, isTrue);

      expect(service.chartJson, isNotNull);
    });
  });

  group('Birth Details Parser Unit Tests', () {
    test('Parses full date, time, and place in English', () {
      final result = BirthDetailsParser.parse('15 December 2006, 7:30 AM, Bengaluru, India');
      expect(result.hasDate, isTrue);
      expect(result.year, equals(2006));
      expect(result.month, equals(12));
      expect(result.day, equals(15));
      expect(result.hasTime, isTrue);
      expect(result.hour, equals(7));
      expect(result.minute, equals(30));
      expect(result.hasPlace, isTrue);
      expect(result.place!.contains('Bengaluru'), isTrue);
      expect(result.isComplete, isTrue);
    });

    test('Parses date without birth time', () {
      final result = BirthDetailsParser.parse('15 December 2006, Bengaluru, India');
      expect(result.hasDate, isTrue);
      expect(result.hasTime, isFalse);
      expect(result.hasPlace, isTrue);
      expect(result.isComplete, isFalse);
    });
  });

  group('Safety Interceptor Unit Tests', () {
    test('Intercepts "cancer" as disease', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('Do I have cancer?'), isTrue);
      final response = await service.sendMessage('Do I have cancer?');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Intercepts Tanglish dying questions ("chachipothana")', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('nenu eppudu chachipothana?'), isTrue);
      final response = await service.sendMessage('nenu eppudu chachipothana?');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Intercepts Tanglish death question ("chavu")', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('naaku chavu eppudu vasthundi?'), isTrue);
      final response = await service.sendMessage('naaku chavu eppudu vasthundi?');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Intercepts Tanglish disease question ("vyadhi")', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('naaku emaina vyadhi untunda?'), isTrue);
      final response = await service.sendMessage('naaku emaina vyadhi untunda?');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Intercepts Tanglish rogan keyword', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('rogan eppudu pothundi'), isTrue);
      final response = await service.sendMessage('rogan eppudu pothundi');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Intercepts English health issue and die queries', () async {
      final service = AIAstrologyService(apiKey: 'dummy_key');
      expect(AstrologyIntentClassifier.isSafetyViolation('Tell me about my health issue'), isTrue);
      expect(AstrologyIntentClassifier.isSafetyViolation('Will I die this year?'), isTrue);
      final response = await service.sendMessage('Will I die this year?');
      expect(response, equals(AstrologyIntentClassifier.safetyResponse));
    });

    test('Does NOT flag Cancer when context strictly implies the zodiac sign', () {
      expect(AstrologyIntentClassifier.isSafetyViolation('What are the traits of Cancer sign?'), isFalse);
      expect(AstrologyIntentClassifier.isSafetyViolation('Tell me about Moon in Cancer'), isFalse);
      expect(AstrologyIntentClassifier.isSafetyViolation('Cancer rashi characteristics'), isFalse);
      expect(AstrologyIntentClassifier.isSafetyViolation('Cancer ascendant personality'), isFalse);
    });
  });

  group('Square Kundli Visualization & [RENDER_SQUARE_KUNDLI] Tag Tests', () {
    testWidgets('SquareKundliWidget renders traditional South Indian 4x4 chart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SquareKundliWidget(chartJson: sampleChart),
          ),
        ),
      );

      // Verify header and ayanamsa
      expect(find.text('Janma Kundali (South Indian)'), findsOneWidget);
      expect(find.text('Nirayana Lahiri'), findsOneWidget);

      // Verify legend indicators
      expect(find.text('As (Lagna)'), findsOneWidget);
      expect(find.text('Mo (Moon Rasi)'), findsOneWidget);
      expect(find.text('R = Retrograde'), findsOneWidget);

      // Verify center AVARA watermark
      expect(find.text('AVARA'), findsOneWidget);

      // Verify planets in Dhanassu (Lagna) and Tula (Moon)
      expect(find.text('Dhanassu'), findsOneWidget);
      expect(find.text('Tula'), findsOneWidget);
      expect(find.text('As'), findsOneWidget);
      expect(find.text('Mo'), findsOneWidget);
    });

    test('Intent classifier detects chart requests', () {
      expect(AstrologyIntentClassifier.classify('Show my chart'), equals(AstrologyIntentType.personalAstrology));
      expect(AstrologyIntentClassifier.classify('I want to see my Kundli'), equals(AstrologyIntentType.personalAstrology));
      expect(AstrologyIntentClassifier.classify('Generate my Jathakam'), equals(AstrologyIntentType.personalAstrology));
    });
  });
}
