import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/survey_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Unified 5-Pillar Connected Flow & Language/Age Tests', () {
    testWidgets('UnifiedFivePillarsLifeRiver renders 5 connected nodes and cycles through flow', (tester) async {
      int openedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UnifiedFivePillarsLifeRiver(
                onOpenPillar: (idx) => openedIndex = idx,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the title & subtitle
      expect(find.text('Unified Life Ecosystem'), findsOneWidget);
      expect(find.text('All 5 pillars connected as one continuous life flow'), findsOneWidget);

      // Verify all 5 pillar names appear
      expect(find.text('Astrology'), findsWidgets);
      expect(find.text('Health'), findsWidgets);
      expect(find.text('Habits'), findsWidgets);
      expect(find.text('Finance'), findsWidgets);
      expect(find.text('Insights'), findsWidgets);

      // Verify "Follow Flow to Next Pillar ➔" button exists
      final nextBtn = find.text('Follow Flow to Next Pillar ➔');
      expect(nextBtn, findsOneWidget);

      // Tap next in flow
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Now active node should be Health
      expect(find.text('Health • Vital Body, Rest & Ayurveda'), findsOneWidget);

      // Tap "Health ➔" button to verify onOpenPillar triggers
      final openBtn = find.text('Health ➔');
      expect(openBtn, findsOneWidget);
      await tester.tap(openBtn);
      expect(openedIndex, 1);
    });

    testWidgets('Instant Language Reactivity updates UnifiedFivePillarsLifeRiver to Telugu', (tester) async {
      await AppLanguageService.instance.setLanguage(AppLanguage.telugu);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UnifiedFivePillarsLifeRiver(
                onOpenPillar: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // In Telugu
      expect(find.text('జీవన సమగ్ర ప్రవాహం'), findsOneWidget);
      expect(find.text('జ్యోతిషం'), findsWidgets);
      expect(find.text('ఆరోగ్యం'), findsWidgets);
      expect(find.text('అలవాట్లు'), findsWidgets);
      expect(find.text('ఆర్థికం'), findsWidgets);
      expect(find.text('విశ్లేషణలు'), findsWidgets);

      // Restore to English
      await AppLanguageService.instance.setLanguage(AppLanguage.english);
    });

    testWidgets('Instant Language Reactivity updates UnifiedFivePillarsLifeRiver to Malayalam', (tester) async {
      await AppLanguageService.instance.setLanguage(AppLanguage.malayalam);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UnifiedFivePillarsLifeRiver(
                onOpenPillar: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // In Malayalam
      expect(find.text('സമഗ്ര ജീവിത പ്രവാഹം'), findsOneWidget);
      expect(find.text('ജ്യോതിഷം'), findsWidgets);
      expect(find.text('ആരോഗ്യം'), findsWidgets);
      expect(find.text('ശീലങ്ങൾ'), findsWidgets);
      expect(find.text('ധനകാര്യം'), findsWidgets);

      // Restore to English
      await AppLanguageService.instance.setLanguage(AppLanguage.english);
    });

    testWidgets('AgeCohortAmbientBackground renders without error for Youth, Adult, Senior', (tester) async {
      for (final group in [AgeGroup.youth, AgeGroup.adult, AgeGroup.senior]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgeCohortAmbientBackground(
                ageGroup: group,
                child: const Text('Test Child'),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Test Child'), findsOneWidget);
      }
    });

    testWidgets('SurveyModal renders all 5 steps on compact and desktop viewports without any overflow', (tester) async {
      for (final size in [const Size(360, 640), const Size(768, 1024), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurveyModal(
                key: ValueKey(size.toString()),
                onCompleted: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Step 0: Language selection
        expect(find.text('AVARA Self-Help Survey (1/5)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to step 1
        await tester.tap(find.text('Continue'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('AVARA Self-Help Survey (2/5)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to step 2
        await tester.tap(find.text('Continue'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('AVARA Self-Help Survey (3/5)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to step 3
        await tester.tap(find.text('Continue'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('AVARA Self-Help Survey (4/5)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to step 4
        await tester.tap(find.text('Continue'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('AVARA Self-Help Survey (5/5)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
