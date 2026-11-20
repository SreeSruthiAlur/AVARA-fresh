import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User age classification to dynamically tailor graphics, UX tone, and content.
enum AgeGroup {
  youth, // Under 22: energetic, neon/vibrant accents, study & exam focus, self-discovery
  adult, // 22 - 45: modern, sleek executive, career growth, financial mindfulness & balance
  senior, // 45+: warm saffron/gold/sage, high-contrast, sacred geometry, peace & daily health
}

/// Dynamic survey option model tailored by age.
class SurveyOptionItem {
  const SurveyOptionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

/// Visual theme and stylistic preferences customized for each age group.
class AgeThemeConfig {
  const AgeThemeConfig({
    required this.group,
    required this.displayName,
    required this.tagline,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.cardBackground,
    required this.badgeColor,
    required this.iconData,
    required this.textScaleFactor,
    required this.graphicStyleDescription,
    required this.bannerGradient,
    required this.momentTitle,
    required this.momentSubtitle,
    required this.greetingBadge,
    required this.defaultHabitGoal,
  });

  final AgeGroup group;
  final String displayName;
  final String tagline;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color cardBackground;
  final Color badgeColor;
  final IconData iconData;
  final double textScaleFactor;
  final String graphicStyleDescription;
  final List<Color> bannerGradient;
  final String momentTitle;
  final String momentSubtitle;
  final String greetingBadge;
  final String defaultHabitGoal;
}

/// Reactive service that stores and provides the active user's age group
/// to power dynamic age-adaptive creative graphics throughout AVARA.
class AgeProfileService extends ChangeNotifier {
  AgeProfileService._();
  static final AgeProfileService instance = AgeProfileService._();

  static const String _prefKeyAge = 'avara_user_age';
  static const String _prefKeyAgeGroup = 'avara_user_age_group';

  int _age = 24;
  AgeGroup _ageGroup = AgeGroup.adult;
  bool _isLoaded = false;

  int get age => _age;
  AgeGroup get ageGroup => _ageGroup;
  bool get isLoaded => _isLoaded;

  /// Returns the tailored design configuration for the active age group.
  AgeThemeConfig get activeTheme => getThemeForGroup(_ageGroup);

  static AgeThemeConfig getThemeForGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.youth:
        return const AgeThemeConfig(
          group: AgeGroup.youth,
          displayName: 'Youth & Explorer (Under 22)',
          tagline: 'Dynamic, inspiring, study focus & self-discovery',
          primaryAccent: Color(0xFF6C5CE7), // Electric Iris
          secondaryAccent: Color(0xFF00CEC9), // Radiant Mint
          cardBackground: Color(0xFFFAF8FF),
          badgeColor: Color(0xFFFF7675),
          iconData: Icons.bolt_rounded,
          textScaleFactor: 1.0,
          graphicStyleDescription: 'Constellation particle waves & XP energy rings',
          bannerGradient: [Color(0xFF2E0854), Color(0xFF4834D4), Color(0xFF00CEC9)],
          momentTitle: '⚡ Boost Your Study Momentum',
          momentSubtitle: 'Mercury favors sharp intellect and fast retention today. Power through your high-priority study block!',
          greetingBadge: '🎒 Student & Early Explorer',
          defaultHabitGoal: '25-minute Pomodoro study block without phone',
        );
      case AgeGroup.adult:
        return const AgeThemeConfig(
          group: AgeGroup.adult,
          displayName: 'Achiever & Mindful Professional (22 - 45)',
          tagline: 'Sleek, executive clarity, financial mindfulness & balance',
          primaryAccent: Color(0xFF1E3A8A), // Deep Navy
          secondaryAccent: Color(0xFF0D9488), // Ocean Teal
          cardBackground: Color(0xFFF8FAFC),
          badgeColor: Color(0xFF3B82F6),
          iconData: Icons.self_improvement_rounded,
          textScaleFactor: 1.05,
          graphicStyleDescription: 'Minimalist geometric mandalas & circadian sine curves',
          bannerGradient: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0D9488)],
          momentTitle: '✦ Executive Clarity & Balance',
          momentSubtitle: 'Align strategic decisions with calm circadian focus. Decompress early to protect sleep quality.',
          greetingBadge: '💼 Achiever & Professional',
          defaultHabitGoal: 'Morning high-leverage priority execution before email',
        );
      case AgeGroup.senior:
        return const AgeThemeConfig(
          group: AgeGroup.senior,
          displayName: 'Grace & Serenity (45+)',
          tagline: 'Calming, sacred saffron & sandalwood, peace & daily health',
          primaryAccent: Color(0xFFB45309), // Warm Temple Amber / Saffron
          secondaryAccent: Color(0xFF047857), // Deep Sage
          cardBackground: Color(0xFFFFFDF5),
          badgeColor: Color(0xFFD97706),
          iconData: Icons.spa_rounded,
          textScaleFactor: 1.15,
          graphicStyleDescription: 'Sacred blooming lotus & traditional high-contrast geometry',
          bannerGradient: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
          momentTitle: '🙏 Sacred Peace & Daily Vitality',
          momentSubtitle: 'Begin with gentle breathwork and warm hydration. May tranquility and contentment guide your day.',
          greetingBadge: '🌸 Grace & Serenity (45+)',
          defaultHabitGoal: 'Brahma Muhurtha gentle morning walk & pranayama',
        );
    }
  }

  /// Returns 5 tailored chatbot questions dynamically matched to the user's age and language.
  List<String> getChatSuggestions({AgeGroup? group, AppLanguage? language}) {
    final activeGroup = group ?? _ageGroup;
    final activeLang = language ?? AppLanguageService.instance.currentLanguage;

    switch (activeGroup) {
      case AgeGroup.youth:
        switch (activeLang) {
          case AppLanguage.telugu:
            return const [
              'పరీక్షల ఒత్తిడిని తగ్గించి, ఏకాగ్రతను ఎలా పెంచుకోవాలి?',
              'నా సహజ ప్రతిభకు ఏ చదువు లేదా ప్రారంభ ఉద్యోగం సరిపోతుంది?',
              'సోషల్ మీడియా పరధ్యానాన్ని ఆపి సమయాన్ని ఎలా సద్వినియోగం చేసుకోవాలి?',
              'నా ఆత్మవిశ్వాసాన్ని పెంచే రోజువారీ వేద అలవాట్లు ఏమిటి?',
              'నా చంద్ర రాశి నా మానసిక ఉత్సాహం మరియు భావోద్వేగాల గురించి ఏమి చెబుతోంది?',
            ];
          case AppLanguage.tanglish:
            return const [
              'Exams stress tagginchi, study focus ela penchukovali?',
              'Naa talents ki ae course or early career baguntundi?',
              'Mobile distraction mariyu procrastination ela aapali?',
              'Self-confidence penchadaniki daily habits emiti?',
              'Naa Moon sign emotions and energy gurinchi em chepthondi?',
            ];
          case AppLanguage.english:
            return const [
              'How can I improve my study focus and beat exam anxiety?',
              'Which college major or early career stream fits my natural talents?',
              'How do I overcome procrastination and social media distraction?',
              'What daily routine boosts my brainpower and confidence?',
              'What does my Moon sign say about my moods and energy?',
            ];
        }

      case AgeGroup.adult:
        switch (activeLang) {
          case AppLanguage.telugu:
            return const [
              'కెరీర్ మార్పు లేదా ప్రమోషన్ కోసం వేద జ్యోతిష మార్గదర్శనం ఏమిటి?',
              'ఉద్యోగ ఒత్తిడి మరియు కుటుంబ బాధ్యతల మధ్య సమతుల్యత ఎలా సాధించాలి?',
              'వివాహం మరియు దాంపత్య సామరస్యం గురించి నా జాతకం ఏమి చెబుతోంది?',
              'ఆర్థిక స్థిరత్వం మరియు పెట్టుబడుల వృద్ధి కోసం ఎలాంటి నిర్ణయాలు తీసుకోవాలి?',
              'రోజూ మానసిక ప్రశాంతతను మరియు శక్తిని ఎలా కాపాడుకోవాలి?',
            ];
          case AppLanguage.tanglish:
            return const [
              'Career growth or job switch ki right time kabolu?',
              'Work pressure mariyu family balance ela manage cheyali?',
              'Marriage and relationship harmony gurinchi naa chart em chepthondi?',
              'Financial growth and wealth creation ki best guidance enti?',
              'Daily stress tagginchi mind active ga ela unchali?',
            ];
          case AppLanguage.english:
            return const [
              'When is the best astrological timing for career transition or promotion?',
              'How can I balance heavy work demands with family and avoid burnout?',
              'What does my birth chart indicate about marriage and relationship harmony?',
              'How can I optimize financial investments and build lasting wealth?',
              'What daily practices keep my mind sharp and stress-free?',
            ];
        }

      case AgeGroup.senior:
        switch (activeLang) {
          case AppLanguage.telugu:
            return const [
              'గాఢమైన మనశ్శాంతిని ఇచ్చే రోజువారీ సాధన మరియు ధ్యానం ఏమిటి?',
              'ఆయుర్వేదం ప్రకారం కీళ్ల ఆరోగ్యం మరియు జీర్ణక్రియను ఎలా కాపాడుకోవాలి?',
              'నా పిల్లలు మరియు మనవళ్ల శ్రేయస్సు కోసం ఎలాంటి పూజలు/పరిహారాలు చేయాలి?',
              'సంతోషం మరియు ఆధ్యాత్మిక సంతృప్తిని ఎలా పెంపొందించుకోవాలి?',
              'ప్రస్తుత మహాదశ నా ఆరోగ్యం మరియు ఆధ్యాత్మిక ప్రయాణం గురించి ఏమి చెబుతోంది?',
            ];
          case AppLanguage.tanglish:
            return const [
              'Deep mental peace kosam ae Sadhana or meditation cheyali?',
              'Ayurveda prakaram health, digestion mariyu joint pain ela manage cheyali?',
              'Pillala and family kshemam kosam best remedies enti?',
              'Inner peace mariyu spiritual happiness ela labhisthundi?',
              'Naa current Mahadasha health and spiritual growth gurinchi em chepthondi?',
            ];
          case AppLanguage.english:
            return const [
              'What daily spiritual Sadhana and meditation bring deepest inner peace?',
              'How can I improve joint mobility, digestion, and vitality through Ayurveda?',
              'What astrological remedies and prayers support my family & grandchildren?',
              'How can I cultivate emotional detachment, contentment, and joy?',
              'What does my current Mahadasha indicate for my health and spiritual path?',
            ];
        }
    }
  }

  /// Tailored Survey Step 1 (Main Focus) options based on age.
  List<SurveyOptionItem> getSurveyFocusOptions(AgeGroup group) {
    switch (group) {
      case AgeGroup.youth:
        return const [
          SurveyOptionItem(
            title: 'Academic Excellence & Exam Focus',
            subtitle: 'Top grades, sharp retention & calm composure during tests',
            icon: Icons.school_rounded,
          ),
          SurveyOptionItem(
            title: 'Career Discovery & Passion',
            subtitle: 'Finding college majors & fields aligned with natural gifts',
            icon: Icons.rocket_launch_rounded,
          ),
          SurveyOptionItem(
            title: 'Self-Confidence & Beating Peer Pressure',
            subtitle: 'Standing tall in personal identity without comparison',
            icon: Icons.auto_awesome,
          ),
          SurveyOptionItem(
            title: 'Digital Detox & Active Fitness',
            subtitle: 'Beating screen addiction and building vibrant athletic energy',
            icon: Icons.directions_run_rounded,
          ),
        ];

      case AgeGroup.adult:
        return const [
          SurveyOptionItem(
            title: 'Career Elevation & Leadership',
            subtitle: 'Strategic promotions, high impact work, and entrepreneurial growth',
            icon: Icons.trending_up_rounded,
          ),
          SurveyOptionItem(
            title: 'Mindful Wealth & Abundance',
            subtitle: 'Smart investments, disciplined savings, and financial security',
            icon: Icons.account_balance_wallet_rounded,
          ),
          SurveyOptionItem(
            title: 'Relationship Harmony & Marriage',
            subtitle: 'Mutual empathy, relationship stability, and family happiness',
            icon: Icons.favorite_rounded,
          ),
          SurveyOptionItem(
            title: 'Work-Life Balance & Burnout Relief',
            subtitle: 'Reclaiming personal calm without sacrificing professional success',
            icon: Icons.self_improvement_rounded,
          ),
        ];

      case AgeGroup.senior:
        return const [
          SurveyOptionItem(
            title: 'Deep Inner Peace & Spiritual Sadhana',
            subtitle: 'Meditation, daily chanting, and serene mental stillness',
            icon: Icons.spa_rounded,
          ),
          SurveyOptionItem(
            title: 'Ayurvedic Vitality & Joint Health',
            subtitle: 'Preserving natural mobility, good digestion, and deep restorative rest',
            icon: Icons.health_and_safety_rounded,
          ),
          SurveyOptionItem(
            title: 'Blessings & Protection for Family',
            subtitle: 'Vedic guidance and planetary remedies for children & grandchildren',
            icon: Icons.diversity_1_rounded,
          ),
          SurveyOptionItem(
            title: 'Contentment (Santosha) & Wisdom',
            subtitle: 'Releasing past worries and living peacefully in gratitude',
            icon: Icons.favorite_border_rounded,
          ),
        ];
    }
  }

  /// Tailored Survey Step 2 (Daily Challenge) options based on age.
  List<SurveyOptionItem> getSurveyChallengeOptions(AgeGroup group) {
    switch (group) {
      case AgeGroup.youth:
        return const [
          SurveyOptionItem(
            title: 'Phone Scrolling & Reel Addiction',
            subtitle: 'Losing hours on shorts/social apps instead of study or rest',
            icon: Icons.phonelink_erase_rounded,
          ),
          SurveyOptionItem(
            title: 'Exam Anxiety & Fear of Low Marks',
            subtitle: 'Freezing up during tests or feeling crushed by expectations',
            icon: Icons.psychology_alt_rounded,
          ),
          SurveyOptionItem(
            title: 'Late Bedtimes & Groggy Mornings',
            subtitle: 'Sleeping late and struggling to focus in morning classes',
            icon: Icons.bedtime_rounded,
          ),
        ];

      case AgeGroup.adult:
        return const [
          SurveyOptionItem(
            title: 'Workplace Stress & Mental Exhaustion',
            subtitle: 'Racing thoughts about deadlines, targets, and endless meetings',
            icon: Icons.work_off_rounded,
          ),
          SurveyOptionItem(
            title: 'Impulsive Spending & Financial Stress',
            subtitle: 'Quick retail dopamine purchases before saving for the future',
            icon: Icons.credit_card_off_rounded,
          ),
          SurveyOptionItem(
            title: 'Irregular Routines & Missed Workouts',
            subtitle: 'Skipping exercise and healthy meals due to busy schedule',
            icon: Icons.timer_off_rounded,
          ),
        ];

      case AgeGroup.senior:
        return const [
          SurveyOptionItem(
            title: 'Interrupted Sleep & Early Morning Fatigue',
            subtitle: 'Waking up frequently at night and feeling tired by afternoon',
            icon: Icons.night_shelter_rounded,
          ),
          SurveyOptionItem(
            title: 'Worrying About Family & Children',
            subtitle: 'Mind continuously anxious about loved ones’ problems',
            icon: Icons.favorite_rounded,
          ),
          SurveyOptionItem(
            title: 'Joint Stiffness & Sluggish Digestion',
            subtitle: 'Ayurvedic vata/kapha imbalances affecting mobility',
            icon: Icons.assist_walker_rounded,
          ),
        ];
    }
  }

  /// Tailored AI System Prompt demographic coaching guideline.
  String getSystemPromptGuideline(AgeGroup group) {
    switch (group) {
      case AgeGroup.youth:
        return 'COACHING TONE: Energetic, encouraging, mentor-like, inspiring.\n'
            'FOCUS: Study focus, college majors, exam calmness, overcoming peer pressure, digital detox, and personal self-belief.\n'
            'STYLE: Use modern, relatable student and early-career analogies. Avoid overly archaic religious jargon; explain Vedic terms through curiosity and empowerment.';
      case AgeGroup.adult:
        return 'COACHING TONE: Executive, strategic, mindful, practical.\n'
            'FOCUS: Career elevation, leadership, work-life balance, marriage/relationship harmony, financial discipline, and stress reduction.\n'
            'STYLE: Deliver structured, actionable insights that busy professionals can immediately apply to their daily schedule.';
      case AgeGroup.senior:
        return 'COACHING TONE: Deeply respectful, reverent, serene, comforting.\n'
            'FOCUS: Inner peace, spiritual Sadhana, Ayurvedic wellness and joint health, emotional contentment (Santosha), and family blessings.\n'
            'STYLE: Ground responses in authentic Vedic and Ayurvedic tradition with gentle warmth, honoring life wisdom.';
    }
  }

  /// Loads saved age preferences from storage.
  Future<void> loadPreferences() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _age = prefs.getInt(_prefKeyAge) ?? 24;
    final groupStr = prefs.getString(_prefKeyAgeGroup);
    if (groupStr != null) {
      _ageGroup = AgeGroup.values.firstWhere(
        (g) => g.name == groupStr,
        orElse: () => _groupFromAge(_age),
      );
    } else {
      _ageGroup = _groupFromAge(_age);
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Sets the user's age and auto-calculates the matching age group.
  Future<void> setAge(int newAge) async {
    _age = newAge;
    _ageGroup = _groupFromAge(newAge);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyAge, _age);
    await prefs.setString(_prefKeyAgeGroup, _ageGroup.name);
  }

  /// Sets the age group directly (e.g. from the onboarding survey).
  Future<void> setAgeGroup(AgeGroup group) async {
    _ageGroup = group;
    switch (group) {
      case AgeGroup.youth:
        _age = 19;
        break;
      case AgeGroup.adult:
        _age = 28;
        break;
      case AgeGroup.senior:
        _age = 52;
        break;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyAge, _age);
    await prefs.setString(_prefKeyAgeGroup, _ageGroup.name);
  }

  static AgeGroup _groupFromAge(int age) {
    if (age < 22) return AgeGroup.youth;
    if (age <= 45) return AgeGroup.adult;
    return AgeGroup.senior;
  }
}

