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

    test('Switches to Malayalam and updates visuals in native script', () async {
      final service = AppLanguageService.instance;
      await service.setLanguage(AppLanguage.malayalam);

      expect(service.currentLanguage, equals(AppLanguage.malayalam));
      expect(service.tr('tab_home'), equals('ഹോം'));
      expect(service.tr('tab_astrology'), equals('ജ്യോതിഷം'));
      expect(service.tr('tab_finance'), equals('ധനകാര്യം'));
      expect(service.tr('tab_health'), equals('ആരോഗ്യം'));
      expect(service.tr('tab_track'), equals('ശീലങ്ങൾ'));
      expect(service.tr('greeting_morning'), equals('സുപ്രഭാതം'));
      expect(service.tr('explore_avara'), equals('AVARA പര്യവേക്ഷണം ചെയ്യുക'));
    });

    test('Switches to Manglish (Malayalam in English script) and updates visuals', () async {
      final service = AppLanguageService.instance;
      await service.setLanguage(AppLanguage.manglish);

      expect(service.currentLanguage, equals(AppLanguage.manglish));
      expect(service.tr('tab_finance'), equals('Dhanakaryam'));
      expect(service.tr('tab_health'), equals('Aarogyam'));
      expect(service.tr('tab_track'), equals('Sheelangal'));
      expect(service.tr('greeting_morning'), equals('Suprabhatham'));
      expect(service.tr('explore_avara'), equals('AVARA Explore Cheyyuka'));
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

    test('Voice command switches language to Malayalam', () {
      final voice = VoiceService.instance;
      final result = voice.parseAndExecuteCommand('Change to Malayalam', speakFeedback: false);

      expect(result.type, equals(VoiceCommandType.changeLanguage));
      expect(result.targetLanguage, equals(AppLanguage.malayalam));
      expect(AppLanguageService.instance.currentLanguage, equals(AppLanguage.malayalam));
    });

    test('Voice command switches language to Manglish', () {
      final voice = VoiceService.instance;
      final result = voice.parseAndExecuteCommand('Change to Manglish', speakFeedback: false);

      expect(result.type, equals(VoiceCommandType.changeLanguage));
      expect(result.targetLanguage, equals(AppLanguage.manglish));
      expect(AppLanguageService.instance.currentLanguage, equals(AppLanguage.manglish));
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

    test('Astrology voice questions invoke onAskAstrologyRequest', () {
      final voice = VoiceService.instance;
      String? askedQuestion;
      voice.onAskAstrologyRequest = (q) => askedQuestion = q;

      final res1 = voice.parseAndExecuteCommand('What is my horoscope?', speakFeedback: false);
      expect(res1.type, equals(VoiceCommandType.askAstrology));
      expect(askedQuestion, contains('horoscope'));

      final res2 = voice.parseAndExecuteCommand('Naa rasi enti', speakFeedback: false);
      expect(res2.type, equals(VoiceCommandType.askAstrology));
      expect(askedQuestion, contains('rasi'));
    });

    test('Direct screen navigation voice commands open target screens', () {
      final voice = VoiceService.instance;
      String? openedScreen;
      voice.onOpenScreenRequest = (s) => openedScreen = s;

      voice.parseAndExecuteCommand('Open astrology chat', speakFeedback: false);
      expect(openedScreen, equals('chat'));

      voice.parseAndExecuteCommand('talk to astrologer', speakFeedback: false);
      expect(openedScreen, equals('astrologers'));

      voice.parseAndExecuteCommand('Open kundli', speakFeedback: false);
      expect(openedScreen, equals('birth_profile'));

      voice.parseAndExecuteCommand('Open profile', speakFeedback: false);
      expect(openedScreen, equals('profile'));
    });

    test('Actionable expense speech invokes onAddExpenseRequest', () {
      final voice = VoiceService.instance;
      double? loggedAmount;
      String? loggedDesc;
      voice.onAddExpenseRequest = (amt, cat, desc) {
        loggedAmount = amt;
        loggedDesc = desc;
      };

      final res = voice.parseAndExecuteCommand('Add expense 150 for coffee', speakFeedback: false);
      expect(res.type, equals(VoiceCommandType.addExpense));
      expect(loggedAmount, equals(150.0));
      expect(loggedDesc, equals('coffee'));
    });

    test('Conversational queries provide helpful system overview', () {
      final voice = VoiceService.instance;
      final res = voice.parseAndExecuteCommand('Who are you?', speakFeedback: false);
      expect(res.type, equals(VoiceCommandType.conversational));
      expect(res.feedbackMessage, contains('AVARA'));
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
