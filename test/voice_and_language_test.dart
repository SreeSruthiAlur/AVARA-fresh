import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/widgets/voice_input_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguageService.instance.init();
    await AppLanguageService.instance.setLanguage(AppLanguage.english);
  });

  group('AVARA Multi-Language Localization Tests (English, Telugu, Tanglish)', () {
    test('Defaults to English with correct translations', () {
      final service = AppLanguageService.instance;
      expect(service.currentLanguage, equals(AppLanguage.english));
      expect(service.tr('tab_home'), equals('Home'));
      expect(service.tr('tab_finance'), equals('Finance'));
      expect(service.tr('tab_health'), equals('Health'));
      expect(service.tr('tab_astrology'), equals('Astrology'));
      expect(service.tr('tab_track'), equals('Track'));
      expect(service.tr('tab_insights'), equals('Insights'));
    });

    test('Switches to Telugu and updates visual strings immediately', () async {
      final service = AppLanguageService.instance;
      bool notified = false;
      service.addListener(() => notified = true);

      await service.setLanguage(AppLanguage.telugu);

      expect(service.currentLanguage, equals(AppLanguage.telugu));
      expect(notified, isTrue);
      expect(service.tr('tab_home'), equals('హోమ్'));
      expect(service.tr('tab_finance'), equals('ఆర్థికం'));
      expect(service.tr('tab_health'), equals('ఆరోగ్యం'));
      expect(service.tr('tab_astrology'), equals('జ్యోతిషం'));
      expect(service.tr('tab_track'), equals('అలవాట్లు'));
      expect(service.tr('tab_insights'), equals('విశ్లేషణలు'));
      expect(service.tr('greeting_morning'), equals('శుభోదయం'));
      expect(service.tr('explore_avara'), equals('AVARA ని అన్వేషించండి'));
    });

    test('Switches to Tanglish (Telugu in English script) and updates visuals', () async {
      final service = AppLanguageService.instance;
      await service.setLanguage(AppLanguage.tanglish);

      expect(service.currentLanguage, equals(AppLanguage.tanglish));
      expect(service.tr('tab_finance'), equals('Kharchulu'));
      expect(service.tr('tab_health'), equals('Aarogyam'));
      expect(service.tr('tab_track'), equals('Alavatlu'));
      expect(service.tr('tab_insights'), equals('Pragathi'));
      expect(service.tr('greeting_morning'), equals('Shubhodhayam'));
      expect(service.tr('explore_avara'), equals('AVARA Explore Cheyandi'));
      expect(service.tr('mod_finance_title'), equals('Kharchulu'));
    });

    test('Persists language in SharedPreferences across sessions', () async {
      final service = AppLanguageService.instance;
      await service.setLanguage(AppLanguage.telugu);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('avara_visual_language'), equals('te'));
    });
  });

  group('AVARA Voice Command Recognition Tests', () {
    test('Voice command switches language to Telugu', () {
      final voice = VoiceService.instance;
      final result1 = voice.parseAndExecuteCommand('Change to Telugu', speakFeedback: false);

      expect(result1.type, equals(VoiceCommandType.changeLanguage));
      expect(result1.targetLanguage, equals(AppLanguage.telugu));
      expect(AppLanguageService.instance.currentLanguage, equals(AppLanguage.telugu));

      final result2 = voice.parseAndExecuteCommand('telugu lo marchu', speakFeedback: false);
      expect(result2.type, equals(VoiceCommandType.changeLanguage));
      expect(result2.targetLanguage, equals(AppLanguage.telugu));
    });

    test('Voice command switches language to Tanglish', () {
      final voice = VoiceService.instance;
      final result = voice.parseAndExecuteCommand('Tanglish lo marchu', speakFeedback: false);

      expect(result.type, equals(VoiceCommandType.changeLanguage));
      expect(result.targetLanguage, equals(AppLanguage.tanglish));
      expect(AppLanguageService.instance.currentLanguage, equals(AppLanguage.tanglish));
    });

    test('Voice command switches language to English', () {
      final voice = VoiceService.instance;
      final result = voice.parseAndExecuteCommand('Switch to English', speakFeedback: false);

      expect(result.type, equals(VoiceCommandType.changeLanguage));
      expect(result.targetLanguage, equals(AppLanguage.english));
      expect(AppLanguageService.instance.currentLanguage, equals(AppLanguage.english));
    });

    test('Voice navigation commands switch tabs correctly', () {
      final voice = VoiceService.instance;
      int? navigatedTab;
      voice.onNavigateRequest = (idx) => navigatedTab = idx;

      // Home
      voice.parseAndExecuteCommand('Go to home', speakFeedback: false);
      expect(navigatedTab, equals(0));

      // Astrology
      voice.parseAndExecuteCommand('Open astrology', speakFeedback: false);
      expect(navigatedTab, equals(1));
      voice.parseAndExecuteCommand('jathakam', speakFeedback: false);
      expect(navigatedTab, equals(1));

      // Finance
      voice.parseAndExecuteCommand('Go to finance', speakFeedback: false);
      expect(navigatedTab, equals(2));
      voice.parseAndExecuteCommand('kharchulu', speakFeedback: false);
      expect(navigatedTab, equals(2));

      // Health
      voice.parseAndExecuteCommand('Open health', speakFeedback: false);
      expect(navigatedTab, equals(3));
      voice.parseAndExecuteCommand('aarogyam', speakFeedback: false);
      expect(navigatedTab, equals(3));

      // Habits
      voice.parseAndExecuteCommand('Open habits', speakFeedback: false);
      expect(navigatedTab, equals(4));
      voice.parseAndExecuteCommand('alavatlu', speakFeedback: false);
      expect(navigatedTab, equals(4));

      // Insights
      voice.parseAndExecuteCommand('Go to insights', speakFeedback: false);
      expect(navigatedTab, equals(5));
      voice.parseAndExecuteCommand('pragathi', speakFeedback: false);
      expect(navigatedTab, equals(5));
    });

    test('Non-command speech falls back to text entry dictation', () {
      final voice = VoiceService.instance;
      final result = voice.parseAndExecuteCommand('Coffee with friends 250', speakFeedback: false);

      expect(result.type, equals(VoiceCommandType.dictateText));
      expect(result.dictatedText, equals('Coffee with friends 250'));
    });

    test('extractExpenseFromSpeech intelligently extracts amount, category, and description', () {
      final voice = VoiceService.instance;
      final r1 = voice.extractExpenseFromSpeech('Coffee 150 rupees');
      expect(r1['amount'], equals(150.0));
      expect(r1['category'], equals('Food & Dining'));
      expect(r1['description'], equals('Coffee'));

      final r2 = voice.extractExpenseFromSpeech('Spent 500 on petrol');
      expect(r2['amount'], equals(500.0));
      expect(r2['category'], equals('Transportation'));
    });
  });

  group('VoiceInputButton Widget Tests', () {
    testWidgets('VoiceInputButton renders and attaches to TextEditingController',
        (tester) async {
      final controller = TextEditingController(text: 'Initial text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceInputButton(controller: controller),
          ),
        ),
      );

      expect(find.byType(VoiceInputButton), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      controller.dispose();
    });
  });
}
