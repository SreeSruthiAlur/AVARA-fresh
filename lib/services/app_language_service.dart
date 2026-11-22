import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported display language modes for the AVARA app UI visuals.
enum AppLanguage {
  english,
  telugu,
  tanglish,
  malayalam,
  manglish,
}

extension AppLanguageExtension on AppLanguage {
  /// Code identifier stored in SharedPreferences.
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.telugu:
        return 'te';
      case AppLanguage.tanglish:
        return 'tanglish';
      case AppLanguage.malayalam:
        return 'ml';
      case AppLanguage.manglish:
        return 'manglish';
    }
  }

  /// Human-friendly display title.
  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.telugu:
        return 'తెలుగు (Telugu)';
      case AppLanguage.tanglish:
        return 'Tanglish (Telugu in English)';
      case AppLanguage.malayalam:
        return 'മലയാളം (Malayalam)';
      case AppLanguage.manglish:
        return 'Manglish (Malayalam in English)';
    }
  }

  /// Short badge label for quick switcher button.
  String get shortLabel {
    switch (this) {
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.telugu:
        return 'తెలుగు';
      case AppLanguage.tanglish:
        return 'Tanglish';
      case AppLanguage.malayalam:
        return 'മലയാളം';
      case AppLanguage.manglish:
        return 'Manglish';
    }
  }

  /// Preferred speech recognition locale tag (BCP-47 format with hyphen for web & mobile).
  String get speechLocaleId {
    switch (this) {
      case AppLanguage.english:
        return 'en-IN';
      case AppLanguage.telugu:
        return 'te-IN';
      case AppLanguage.tanglish:
        return 'en-IN'; // Latin phonetics for Tanglish
      case AppLanguage.malayalam:
        return 'ml-IN';
      case AppLanguage.manglish:
        return 'en-IN'; // Latin phonetics for Manglish
    }
  }
}

/// Central Localization & Language state manager for AVARA.
///
/// Implements [ChangeNotifier] so any UI listening to [AppLanguageService.instance]
/// re-renders instantly upon language selection or voice-triggered language changes.
class AppLanguageService extends ChangeNotifier {
  AppLanguageService._();
  static final AppLanguageService instance = AppLanguageService._();

  static const String _kLanguagePrefKey = 'avara_visual_language';

  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Loads saved language preference from SharedPreferences.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLanguagePrefKey);
      if (saved != null) {
        if (saved == 'te' || saved == 'telugu') {
          _currentLanguage = AppLanguage.telugu;
        } else if (saved == 'tanglish') {
          _currentLanguage = AppLanguage.tanglish;
        } else if (saved == 'ml' || saved == 'malayalam') {
          _currentLanguage = AppLanguage.malayalam;
        } else if (saved == 'manglish') {
          _currentLanguage = AppLanguage.manglish;
        } else {
          _currentLanguage = AppLanguage.english;
        }
      }
    } catch (_) {
      _currentLanguage = AppLanguage.english;
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Switches visual language and persists preference.
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguagePrefKey, language.code);
    } catch (_) {
      // Best-effort persistence
    }
  }

  /// Translates a key to the current language string.
  /// Falls back to English if the key is missing in Telugu or Tanglish.
  String tr(String key) {
    final dict = _translations[_currentLanguage] ?? _translations[AppLanguage.english]!;
    final val = dict[key];
    if (val != null) return val;
    // Fallback to English
    return _translations[AppLanguage.english]?[key] ?? key;
  }

  // ---------------------------------------------------------------------------
  // Translations Dictionary
  // ---------------------------------------------------------------------------
  static final Map<AppLanguage, Map<String, String>> _translations = {
    // =========================================================================
    // ENGLISH
    // =========================================================================
    AppLanguage.english: {
      // Navigation Tabs
      'tab_home': 'Home',
      'tab_astrology': 'Astrology',
      'tab_finance': 'Finance',
      'tab_health': 'Health',
      'tab_track': 'Track',
      'tab_insights': 'Insights',

      // Greetings
      'greeting_morning': 'Good morning',
      'greeting_afternoon': 'Good afternoon',
      'greeting_evening': 'Good evening',
      'moment_title': 'Take a moment for yourself',
      'moment_subtitle': 'A short ritual to start your day grounded and intentional.',
      'explore_avara': 'Explore AVARA',

      // Explore Modules
      'mod_astrology_title': 'Astrology',
      'mod_astrology_sub': 'Find guidance',
      'mod_finance_title': 'Finance',
      'mod_finance_sub': 'Track spending',
      'mod_habits_title': 'Habits',
      'mod_habits_sub': 'Build consistency',
      'mod_health_title': 'Health',
      'mod_health_sub': 'Track wellness',
      'mod_insights_title': 'Insights',
      'mod_insights_sub': 'See your progress',

      // Actions & Common
      'btn_add': 'Add',
      'btn_save': 'Save',
      'btn_cancel': 'Cancel',
      'btn_submit': 'Submit',
      'btn_delete': 'Delete',
      'btn_edit': 'Edit',
      'btn_back': 'Back',
      'btn_logout': 'Log out',
      'btn_done': 'Done',
      'btn_close': 'Close',
      'coming_soon': 'Coming soon!',

      // Language Switcher
      'lang_switch_title': 'Select Display Language',
      'lang_switch_subtitle': 'Visual visuals will update instantly across the app',
      'lang_english': 'English',
      'lang_telugu': 'తెలుగు (Telugu)',
      'lang_tanglish': 'Tanglish (Telugu in English)',

      // Voice
      'voice_assistant_title': 'AVARA Voice Assistant',
      'voice_speak_prompt': 'Listening... speak now',
      'voice_tap_to_speak': 'Tap mic to speak',
      'voice_listening': 'Listening...',
      'voice_stop_listening': 'Stop Listening',
      'voice_recognized_text': 'Recognized:',
      'voice_command_applied': 'Voice command executed',
      'voice_lang_switched': 'Language switched successfully',
      'voice_try_saying': 'Try saying: "Change to Telugu", "Switch to Tanglish", "Go to Finance", "Open Astrology"',

      // Astrology
      'astrology_title': 'Astrology Hub',
      'astrology_hero_title': 'AVARA Astrology',
      'astrology_hero_tagline': 'Ask Questions. Get Perspectives.',
      'astrology_hero_sub': 'Find Guidance for your journey',
      'astrology_tile_ask': 'Ask a Question',
      'astrology_tile_topics': 'Explore Topics',
      'astrology_tile_astrologer': 'Talk to an Astrologer',
      'astrology_disclaimer': 'Astrology offers traditional interpretations, not guaranteed outcomes.',
      'astrology_chat_title': 'AVARA Jyotisha',
      'astrology_chat_subtitle': 'Powered by Gemini • Vedic Astrology',
      'astrology_input_hint': 'Ask about your chart…',
      'astrology_birth_profile_title': 'Birth Profile & Astrology Evidence',
      'astrology_dob': 'Date of Birth',
      'astrology_tob': 'Time of Birth',
      'astrology_pob': 'Place of Birth',
      'astrology_pob_hint': 'City or Town (e.g. Hyderabad)',
      'astrology_ayanamsa': 'Ayanamsa',
      'astrology_generate_btn': 'Generate Evidence Chart',
      'astrology_calculating': 'Calculating Kundali…',

      // Finance
      'finance_title': 'Finance',
      'finance_total_spend': 'Total Spend',
      'finance_this_month': 'This Month',
      'finance_spending_cats': 'Spending Categories',
      'finance_recent_expenses': 'Recent Transactions',
      'finance_total_label': 'total',
      'finance_add_expense_btn': 'Add Expense',
      'finance_amount': 'Amount (₹)',
      'finance_amount_hint': 'e.g. 250',
      'finance_category': 'Category',
      'finance_payment_method': 'Payment Method',
      'finance_description': 'Description',
      'finance_description_hint': 'What was this expense for?',
      'finance_date': 'Date',

      // Health
      'health_title': 'Health & Wellness',
      'health_today_status': "Today's Status",
      'health_add_entry_btn': 'Log Today',
      'health_streak': 'Streak',
      'health_days_logged': 'days logged',
      'health_avg_mood': 'Avg Mood',
      'health_avg_sleep': 'Avg Sleep',
      'health_activity_label': 'Activity',
      'health_checkin_history': 'Check-in History',
      'health_mood': 'Mood',
      'health_energy': 'Energy Level',
      'health_sleep': 'Sleep (Hours)',
      'health_activity': 'Activity (Minutes)',
      'health_water': 'Water Intake (Liters)',
      'health_notes': 'Notes',
      'health_notes_hint': 'How did you feel today?',

      // Habits
      'habits_title': 'Habits & Goals',
      'habits_tab_today': 'Today',
      'habits_tab_week': 'This Week',
      'habits_tab_goals': 'Goals',
      'habits_add_btn': 'Add a Habit',
      'habits_name': 'Habit Name',
      'habits_name_hint': 'e.g. Morning Meditation',
      'habits_frequency': 'Frequency',
      'habits_daily': 'Daily',
      'habits_weekly': 'Weekly',
      'habits_no_habits': 'No habits yet',
      'habits_empty_hint': 'Tap "Add a Habit" to start building consistency.',

      // Profile
      'profile_title': 'Profile',
      'profile_personal_info': 'Personal Information',
      'profile_birth_details': 'Birth Details',
      'profile_preferences': 'Preferences & Language',
      'profile_history': 'Consultation History',
      'profile_my_data': 'My Data',
      'profile_help': 'Help & Support',
      'profile_privacy': 'Privacy & Security',

      // Login & Common UI
      'welcome_title': 'Welcome to AVARA',
      'welcome_subtitle': 'Your daily guide for mindfulness, habits & inner growth',
      'login_email': 'Email',
      'login_password': 'Password',
      'login_btn': 'Sign in to AVARA',
      'login_guest_btn': 'Continue without typing (Guest)',
      'login_no_account': "Don't have an account? Sign up",
      'explore_by_age': 'Explore AVARA by Age Cohort',
      'age_cohort_hint': '1-Tap to experience dynamic age-adaptive graphics & themes:',
      'five_pillars_connected': '5 Pillars Connected: Astrology • Health • Habits • Finance • Insights',
      'vedic_wisdom_tag': 'Vedic Wisdom & Modern Self-Help',
      'five_pillars_title': 'Unified Life Ecosystem',
      'five_pillars_subtitle': 'All 5 pillars connected as one continuous life flow',
      'flow_next_btn': 'Follow Flow to Next Pillar ➔',
      'daily_growth_report': 'Daily Holistic Growth Report',
    },

    // =========================================================================
    // TELUGU (తెలుగు)
    // =========================================================================
    AppLanguage.telugu: {
      // Navigation Tabs
      'tab_home': 'హోమ్',
      'tab_astrology': 'జ్యోతిషం',
      'tab_finance': 'ఆర్థికం',
      'tab_health': 'ఆరోగ్యం',
      'tab_track': 'అలవాట్లు',
      'tab_insights': 'విశ్లేషణలు',

      // Greetings
      'greeting_morning': 'శుభోదయం',
      'greeting_afternoon': 'శుభ మధ్యాహ్నం',
      'greeting_evening': 'శుభ సాయంత్రం',
      'moment_title': 'మీ కోసం కాసేపు కేటాయించండి',
      'moment_subtitle': 'మీ రోజును ప్రశాంతంగా, ఉద్దేశపూర్వకంగా ప్రారంభించడానికి ఒక చిన్న సంకల్పం.',
      'explore_avara': 'AVARA ని అన్వేషించండి',

      // Explore Modules
      'mod_astrology_title': 'జ్యోతిషం',
      'mod_astrology_sub': 'మార్గదర్శనం పొందండి',
      'mod_finance_title': 'ఆర్థికం',
      'mod_finance_sub': 'ఖర్చులను గమనించండి',
      'mod_habits_title': 'అలవాట్లు',
      'mod_habits_sub': 'స్థిరత్వాన్ని పెంచుకోండి',
      'mod_health_title': 'ఆరోగ్యం',
      'mod_health_sub': 'ఆరోగ్యాన్ని ట్రాక్ చేయండి',
      'mod_insights_title': 'విశ్లేషణలు',
      'mod_insights_sub': 'మీ పురోగతిని చూడండి',

      // Actions & Common
      'btn_add': 'జోడించు',
      'btn_save': 'భద్రపరచు',
      'btn_cancel': 'రద్దు చేయి',
      'btn_submit': 'సమర్పించు',
      'btn_delete': 'తొలగించు',
      'btn_edit': 'సవరించు',
      'btn_back': 'వెనుకకు',
      'btn_logout': 'లాగ్ అవుట్',
      'btn_done': 'పూర్తయింది',
      'btn_close': 'మూసివేయి',
      'coming_soon': 'త్వరలో రాబోతోంది!',

      // Language Switcher
      'lang_switch_title': 'భాషను ఎంచుకోండి',
      'lang_switch_subtitle': 'యాప్ దృశ్యాలు మరియు వచనాలన్నీ వెంటనే మారతాయి',
      'lang_english': 'English',
      'lang_telugu': 'తెలుగు (Telugu)',
      'lang_tanglish': 'Tanglish (తెలుగు ఇంగ్లీష్ లో)',

      // Voice
      'voice_assistant_title': 'AVARA వాయిస్ అసిస్టెంట్',
      'voice_speak_prompt': 'వింటున్నాను... మాట్లాడండి',
      'voice_tap_to_speak': 'మాట్లాడటానికి మైక్ నొక్కండి',
      'voice_listening': 'వింటున్నాము...',
      'voice_stop_listening': 'వినడం ఆపు',
      'voice_recognized_text': 'గుర్తించబడిన మాటలు:',
      'voice_command_applied': 'వాయిస్ ఆదేశం అమలు చేయబడింది',
      'voice_lang_switched': 'భాష విజయవంతంగా మార్చబడింది',
      'voice_try_saying': 'ఇలా చెప్పండి: "తెలుగు", "టాంగ్లిష్", "ఇంగ్లీష్", "ఆర్థికంకి వెళ్ళు", "జ్యోతిషం చూపించు"',

      // Astrology
      'astrology_title': 'జ్యోతిష కేంద్రం',
      'astrology_hero_title': 'AVARA జ్యోతిషం',
      'astrology_hero_tagline': 'ప్రశ్నలు అడగండి. మార్గదర్శనం పొందండి.',
      'astrology_hero_sub': 'మీ జీవిత ప్రయాణానికి సరైన మార్గం',
      'astrology_tile_ask': 'ప్రశ్న అడగండి',
      'astrology_tile_topics': 'విషయాలు చూడండి',
      'astrology_tile_astrologer': 'జ్యోతిష్యుడితో మాట్లాడండి',
      'astrology_disclaimer': 'జ్యోతిషం సంప్రదాయ వివరణలను అందిస్తుంది, నిర్దిష్ట ఫలితాలకు హామీ ఇవ్వదు.',
      'astrology_chat_title': 'AVARA జ్యోతిషం',
      'astrology_chat_subtitle': 'వేద జ్యోతిష మార్గదర్శి',
      'astrology_input_hint': 'మీ జాతకం గురించి అడగండి…',
      'astrology_birth_profile_title': 'జనన వివరాలు & కుండలి సాక్ష్యం',
      'astrology_dob': 'పుట్టిన తేదీ',
      'astrology_tob': 'పుట్టిన సమయం',
      'astrology_pob': 'పుట్టిన స్థలం',
      'astrology_pob_hint': 'నగరం లేదా ఊరు (ఉదా: హైదరాబాద్)',
      'astrology_ayanamsa': 'అయనాంశ',
      'astrology_generate_btn': 'జాతక చార్ట్ లెక్కించు',
      'astrology_calculating': 'కుండలి గణిస్తున్నాము…',

      // Finance
      'finance_title': 'ఆర్థిక నిర్వహణ',
      'finance_total_spend': 'మొత్తం ఖర్చు',
      'finance_this_month': 'ఈ నెల ఖర్చులు',
      'finance_spending_cats': 'ఖర్చుల వర్గాలు',
      'finance_recent_expenses': 'ఇటీవలి లావాదేవీలు',
      'finance_total_label': 'మొత్తం',
      'finance_add_expense_btn': 'ఖర్చును జోడించు',
      'finance_amount': 'మొత్తం (₹)',
      'finance_amount_hint': 'ఉదా: 250',
      'finance_category': 'వర్గం',
      'finance_payment_method': 'చెల్లింపు విధానం',
      'finance_description': 'వివరణ',
      'finance_description_hint': 'ఖర్చు దేనికోసం చేశారు?',
      'finance_date': 'తేదీ',

      // Health
      'health_title': 'ఆరోగ్యం & శ్రేయస్సు',
      'health_today_status': 'ఈ రోజు స్థితి',
      'health_add_entry_btn': 'ఈ రోజు నమోదు చేయండి',
      'health_streak': 'వరుస రోజులు',
      'health_days_logged': 'రోజులు నమోదు',
      'health_avg_mood': 'సగటు మానసిక స్థితి',
      'health_avg_sleep': 'సగటు నిద్ర',
      'health_activity_label': 'వ్యాయామం',
      'health_checkin_history': 'చెక్-ఇన్ చరిత్ర',
      'health_mood': 'మానసిక స్థితి',
      'health_energy': 'శక్తి స్థాయి',
      'health_sleep': 'నిద్ర (గంటలు)',
      'health_activity': 'వ్యాయామం / నడక (నిమిషాలు)',
      'health_water': 'నీటి పరిమాణం (లీటర్లు)',
      'health_notes': 'గమనికలు',
      'health_notes_hint': 'ఈ రోజు మీకు ఎలా అనిపించింది?',

      // Habits
      'habits_title': 'అలవాట్లు & లక్ష్యాలు',
      'habits_tab_today': 'ఈ రోజు',
      'habits_tab_week': 'ఈ వారం',
      'habits_tab_goals': 'లక్ష్యాలు',
      'habits_add_btn': 'కొత్త అలవాటు జోడించు',
      'habits_name': 'అలవాటు పేరు',
      'habits_name_hint': 'ఉదా: ఉదయం ధ్యానం లేదా నడక',
      'habits_frequency': 'తరచుదనం',
      'habits_daily': 'రోజూ',
      'habits_weekly': 'వారానికి',
      'habits_no_habits': 'ఇంకా అలవాట్లు లేవు',
      'habits_empty_hint': '"కొత్త అలవాటు జోడించు" నొక్కి ప్రారంభించండి.',

      // Profile
      'profile_title': 'ప్రొఫైల్',
      'profile_personal_info': 'వ్యక్తిగత సమాచారం',
      'profile_birth_details': 'పుట్టిన వివరాలు',
      'profile_preferences': 'ప్రాధాన్యతలు & భాష',
      'profile_history': 'సంప్రదింపుల చరిత్ర',
      'profile_my_data': 'నా సమాచారం',
      'profile_help': 'సహాయం & మద్దతు',
      'profile_privacy': 'గోప్యత & భద్రత',

      // Login & Common UI
      'welcome_title': 'అవారాకి స్వాగతం',
      'welcome_subtitle': 'దైనందిన ఆధ్యాత్మిక శాంతి, మంచి అలవాట్లు & వ్యక్తిత్వ వికాస మార్గదర్శి',
      'login_email': 'ఈమెయిల్',
      'login_password': 'పాస్‌వర్డ్',
      'login_btn': 'అవారాలోకి ప్రవేశించండి',
      'login_guest_btn': 'అతిథిగా ప్రవేశించండి (నో టైపింగ్)',
      'login_no_account': 'ఖాతా లేదా? ఇప్పుడే నమోదు చేసుకోండి',
      'explore_by_age': 'వయోవర్గాల వారీగా అవారాను అన్వేషించండి',
      'age_cohort_hint': '1-ట్యాప్‌తో వయస్సు ఆధారిత గ్రాఫిక్స్ & థీమ్‌లను అనుభవించండి:',
      'five_pillars_connected': '5 స్తంభాల అనుసంధానం: జ్యోతిషం • ఆరోగ్యం • అలవాట్లు • ఆర్థికం • విశ్లేషణ',
      'vedic_wisdom_tag': 'వేద విజ్ఞానం & ఆధునిక స్వీయ సహాయం',
      'five_pillars_title': 'జీవన సమగ్ర ప్రవాహం',
      'five_pillars_subtitle': '5 విభాగాలు అనుసంధానమై నిరంతరం ప్రవహిస్తాయి',
      'flow_next_btn': 'తదుపరి స్తంభానికి వెళ్ళండి ➔',
      'daily_growth_report': 'దైనందిన సంపూర్ణ వృద్ధి నివేదిక',
    },

    // =========================================================================
    // TANGLISH (Telugu in English / Latin script)
    // =========================================================================
    AppLanguage.tanglish: {
      // Navigation Tabs
      'tab_home': 'Home',
      'tab_astrology': 'Astrology',
      'tab_finance': 'Kharchulu',
      'tab_health': 'Aarogyam',
      'tab_track': 'Alavatlu',
      'tab_insights': 'Pragathi',

      // Greetings
      'greeting_morning': 'Shubhodhayam',
      'greeting_afternoon': 'Shubha Madhyahnam',
      'greeting_evening': 'Shubha Sayantram',
      'moment_title': 'Mee kosam konchem time teesukondi',
      'moment_subtitle': 'Mee day ni prasanthamga, intentional ga start cheyadaniki oka chinna ritual.',
      'explore_avara': 'AVARA Explore Cheyandi',

      // Explore Modules
      'mod_astrology_title': 'Jathakam',
      'mod_astrology_sub': 'Guidance pondandi',
      'mod_finance_title': 'Kharchulu',
      'mod_finance_sub': 'Spending track cheyandi',
      'mod_habits_title': 'Alavatlu',
      'mod_habits_sub': 'Consistency build cheyandi',
      'mod_health_title': 'Aarogyam',
      'mod_health_sub': 'Wellness track cheyandi',
      'mod_insights_title': 'Pragathi',
      'mod_insights_sub': 'Mee progress chudandi',

      // Actions & Common
      'btn_add': 'Add Cheyandi',
      'btn_save': 'Save Cheyandi',
      'btn_cancel': 'Cancel',
      'btn_submit': 'Submit',
      'btn_delete': 'Delete Cheyandi',
      'btn_edit': 'Edit Cheyandi',
      'btn_back': 'Venakki',
      'btn_logout': 'Log out',
      'btn_done': 'Ayyindi',
      'btn_close': 'Close',
      'coming_soon': 'Thvaralo vasthundi!',

      // Language Switcher
      'lang_switch_title': 'Display Language Select Cheyandi',
      'lang_switch_subtitle': 'App visuals ventane update avuthayi',
      'lang_english': 'English',
      'lang_telugu': 'తెలుగు (Telugu)',
      'lang_tanglish': 'Tanglish (Telugu in English)',

      // Voice
      'voice_assistant_title': 'AVARA Voice Assistant',
      'voice_speak_prompt': 'Vintunnam... Matladandi',
      'voice_tap_to_speak': 'Matladataniki mic tap cheyandi',
      'voice_listening': 'Vintunnam...',
      'voice_stop_listening': 'Aapandi',
      'voice_recognized_text': 'Recognized Words:',
      'voice_command_applied': 'Voice command execute ayyindi',
      'voice_lang_switched': 'Language successfully change chesam',
      'voice_try_saying': 'Try cheyandi: "Change to Telugu", "Tanglish lo marchu", "Switch to English", "Go to Finance"',

      // Astrology
      'astrology_title': 'Jyotisha Hub',
      'astrology_hero_title': 'AVARA Astrology',
      'astrology_hero_tagline': 'Questions Adagandi. Perspectives Pondandi.',
      'astrology_hero_sub': 'Mee life journey ki guidance pondandi',
      'astrology_tile_ask': 'Prashna Adagandi',
      'astrology_tile_topics': 'Topics Explore Cheyandi',
      'astrology_tile_astrologer': 'Astrologer tho Matladandi',
      'astrology_disclaimer': 'Astrology traditional interpretations isthundi, guaranteed outcomes kaadhu.',
      'astrology_chat_title': 'AVARA Jyotisha',
      'astrology_chat_subtitle': 'Gemini Powered • Vedic Astrology',
      'astrology_input_hint': 'Mee chart gurinchi adagandi…',
      'astrology_birth_profile_title': 'Birth Profile & Kundali Evidence',
      'astrology_dob': 'Puttina Date',
      'astrology_tob': 'Puttina Time',
      'astrology_pob': 'Puttina Ooru / Place',
      'astrology_pob_hint': 'City or Town (e.g. Hyderabad)',
      'astrology_ayanamsa': 'Ayanamsa',
      'astrology_generate_btn': 'Chart Calculate Cheyandi',
      'astrology_calculating': 'Kundali calculate chesthunnam…',

      // Finance
      'finance_title': 'Kharchulu (Finance)',
      'finance_total_spend': 'Motham Kharchu',
      'finance_this_month': 'Ee Month Kharchulu',
      'finance_spending_cats': 'Kharchula Categories',
      'finance_recent_expenses': 'Recent Transactions',
      'finance_total_label': 'total',
      'finance_add_expense_btn': 'Kharchu Add Cheyandi',
      'finance_amount': 'Amount (₹)',
      'finance_amount_hint': 'e.g. 250',
      'finance_category': 'Category',
      'finance_payment_method': 'Payment Mode',
      'finance_description': 'Description',
      'finance_description_hint': 'Deeni kosam kharchu pettaru?',
      'finance_date': 'Date',

      // Health
      'health_title': 'Aarogyam & Wellness',
      'health_today_status': 'Ee Roju Status',
      'health_add_entry_btn': 'Ee Roju Log Cheyandi',
      'health_streak': 'Streak',
      'health_days_logged': 'days logged',
      'health_avg_mood': 'Avg Mood',
      'health_avg_sleep': 'Avg Sleep',
      'health_activity_label': 'Activity',
      'health_checkin_history': 'Check-in History',
      'health_mood': 'Mood',
      'health_energy': 'Energy Level',
      'health_sleep': 'Nidra (Hours)',
      'health_activity': 'Activity / Walk (Minutes)',
      'health_water': 'Neellu (Liters)',
      'health_notes': 'Notes',
      'health_notes_hint': 'Ee roju ela anipinchindi?',

      // Habits
      'habits_title': 'Alavatlu & Goals',
      'habits_tab_today': 'Ee Roju',
      'habits_tab_week': 'Ee Varam',
      'habits_tab_goals': 'Goals',
      'habits_add_btn': 'Alavatu Add Cheyandi',
      'habits_name': 'Alavatu Peru',
      'habits_name_hint': 'e.g. Udayam Walk / Meditation',
      'habits_frequency': 'Frequency',
      'habits_daily': 'Daily',
      'habits_weekly': 'Weekly',
      'habits_no_habits': 'Inka alavatlu levu',
      'habits_empty_hint': '"Alavatu Add Cheyandi" tap chesi start cheyandi.',

      // Profile
      'profile_title': 'Profile',
      'profile_personal_info': 'Personal Information',
      'profile_birth_details': 'Birth Details',
      'profile_preferences': 'Preferences & Language',
      'profile_history': 'Consultation History',
      'profile_my_data': 'Naa Data',
      'profile_help': 'Help & Support',
      'profile_privacy': 'Privacy & Security',

      // Login & Common UI
      'welcome_title': 'AVARA ki Swagatham',
      'welcome_subtitle': 'Dainandina manasika shanthi, manchi alavatlu & inner growth guide',
      'login_email': 'Email',
      'login_password': 'Password',
      'login_btn': 'AVARA loki Sign In avvandi',
      'login_guest_btn': 'Guest ga Continue avvandi (No typing)',
      'login_no_account': 'Account leda? Sign up avvandi',
      'explore_by_age': 'Age cohort batti AVARA ni explore cheyandi',
      'age_cohort_hint': '1-Tap tho age-adaptive graphics & themes chudandi:',
      'five_pillars_connected': '5 Pillars Connected: Astrology • Health • Habits • Finance • Insights',
      'vedic_wisdom_tag': 'Vedic Vignanam & Modern Self-Help',
      'five_pillars_title': 'Unified Life Ecosystem',
      'five_pillars_subtitle': '5 pillars connected as one seamless life flow',
      'flow_next_btn': 'Next Pillar ki Vellandi ➔',
      'daily_growth_report': 'Daily Holistic Growth Report',
    },

    // =========================================================================
    // MALAYALAM (മലയാളം)
    // =========================================================================
    AppLanguage.malayalam: {
      // Navigation Tabs
      'tab_home': 'ഹോം',
      'tab_astrology': 'ജ്യോതിഷം',
      'tab_finance': 'ധനകാര്യം',
      'tab_health': 'ആരോഗ്യം',
      'tab_track': 'ശീലങ്ങൾ',
      'tab_insights': 'വിവരങ്ങൾ',

      // Greetings
      'greeting_morning': 'സുപ്രഭാതം',
      'greeting_afternoon': 'ശുഭദിനം',
      'greeting_evening': 'ശുഭസായാഹ്നം',
      'moment_title': 'നിങ്ങൾക്കായി ഒരു നിമിഷം നീക്കിവെക്കൂ',
      'moment_subtitle': 'നിങ്ങളുടെ ദിവസം ശാന്തമായും ലക്ഷ്യബോധത്തോടെയും ആരംഭിക്കാൻ ഒരു ആചാരം.',
      'explore_avara': 'AVARA പര്യവേക്ഷണം ചെയ്യുക',

      // Explore Modules
      'mod_astrology_title': 'ജ്യോതിഷം',
      'mod_astrology_sub': 'മാർഗ്ഗനിർദ്ദേശം കണ്ടെത്തൂ',
      'mod_finance_title': 'ധനകാര്യം',
      'mod_finance_sub': 'ചിലവുകൾ പരിശോധിക്കൂ',
      'mod_habits_title': 'ശീലങ്ങൾ',
      'mod_habits_sub': 'സ്ഥിരത വളർത്തൂ',
      'mod_health_title': 'ആരോഗ്യം',
      'mod_health_sub': 'ക്ഷേമം വിലയിരുത്തൂ',
      'mod_insights_title': 'സ്ഥിതിവിവരങ്ങൾ',
      'mod_insights_sub': 'പുരോഗതി കാണൂ',

      // Actions & Common
      'btn_add': 'ചേർക്കുക',
      'btn_save': 'സംരക്ഷിക്കുക',
      'btn_cancel': 'റദ്ദാക്കുക',
      'btn_submit': 'സമർപ്പിക്കുക',
      'btn_delete': 'നീക്കം ചെയ്യുക',
      'btn_edit': 'തിരുത്തുക',
      'btn_back': 'പിന്നോട്ട്',
      'btn_logout': 'ലോഗ് ഔട്ട്',
      'btn_done': 'പൂർത്തിയായി',
      'btn_close': 'അടയ്ക്കുക',
      'coming_soon': 'ഉടൻ ലഭ്യമാകും!',

      // Language Switcher
      'lang_switch_title': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      'lang_switch_subtitle': 'ആപ്പിലെ വിവരങ്ങൾ ഉടൻ തന്നെ മാറും',
      'lang_english': 'English',
      'lang_telugu': 'తెలుగు (Telugu)',
      'lang_tanglish': 'Tanglish (Telugu in English)',
      'lang_malayalam': 'മലയാളം (Malayalam)',
      'lang_manglish': 'Manglish (Malayalam in English)',

      // Voice
      'voice_assistant_title': 'AVARA വോയ്സ് അസിസ്റ്റന്റ്',
      'voice_speak_prompt': 'കേൾക്കുന്നു... സംസാരിക്കൂ',
      'voice_tap_to_speak': 'സംസാരിക്കാൻ മൈക്കിൽ തൊടൂ',
      'voice_listening': 'ശ്രദ്ധിക്കുന്നു...',
      'voice_stop_listening': 'കേൾക്കുന്നത് നിർത്തൂ',
      'voice_recognized_text': 'തിരിച്ചറിഞ്ഞ വാക്കുകൾ:',
      'voice_command_applied': 'വോയ്സ് കമാൻഡ് നടപ്പിലാക്കി',
      'voice_lang_switched': 'ഭാഷ വിജയകരമായി മാറ്റി',
      'voice_try_saying': 'ഇങ്ങനെ പറയൂ: "Change to Malayalam", "Manglish aakkuka", "Open Astrology", "Go to Finance"',

      // Astrology
      'astrology_title': 'ജ്യോതിഷ കേന്ദ്രം',
      'astrology_hero_title': 'AVARA ജ്യോതിഷം',
      'astrology_hero_tagline': 'ചോദ്യങ്ങൾ ചോദിക്കൂ. ദിശാബോധം നേടൂ.',
      'astrology_hero_sub': 'ജീവിതയാത്രയ്ക്ക് ശരിയായ മാർഗ്ഗനിർദ്ദേശം',
      'astrology_tile_ask': 'ഒരു ചോദ്യം ചോദിക്കൂ',
      'astrology_tile_topics': 'വിഷയങ്ങൾ പരിശോധിക്കൂ',
      'astrology_tile_astrologer': 'ജ്യോതിഷിയുമായി സംസാരിക്കൂ',
      'astrology_disclaimer': 'ജ്യോതിഷം പരമ്പരാഗത വ്യാഖ്യാനങ്ങളാണ് നൽകുന്നത്, നിശ്ചിത ഫലങ്ങൾ ഉറപ്പ് നൽകുന്നില്ല.',
      'astrology_chat_title': 'AVARA ജ്യോതിഷം',
      'astrology_chat_subtitle': 'വേദ ജ്യോതിഷ വഴികാട്ടി • Gemini Powered',
      'astrology_input_hint': 'ജാതകത്തെക്കുറിച്ച് ചോദിക്കൂ…',
      'astrology_birth_profile_title': 'ജനന വിവരങ്ങളും ജാതക തെളിവും',
      'astrology_dob': 'ജനന തീയതി',
      'astrology_tob': 'ജനന സമയം',
      'astrology_pob': 'ജനിച്ച സ്ഥലം',
      'astrology_pob_hint': 'നഗരം അല്ലെങ്കിൽ ഗ്രാമം (ഉദാ: കൊച്ചി)',
      'astrology_ayanamsa': 'അയനാംശം',
      'astrology_generate_btn': 'ജാതക ചാർട്ട് തയ്യാറാക്കൂ',
      'astrology_calculating': 'ജാതകം കണക്കാക്കുന്നു…',

      // Finance
      'finance_title': 'ധനകാര്യം',
      'finance_total_spend': 'ആകെ ചിലവ്',
      'finance_this_month': 'ഈ മാസത്തെ ചിലവ്',
      'finance_spending_cats': 'ചിലവ് വിഭാഗങ്ങൾ',
      'finance_recent_expenses': 'സമീപകാല ഇടപാടുകൾ',
      'finance_total_label': 'ആകെ',
      'finance_add_expense_btn': 'ചിലവ് ചേർക്കുക',
      'finance_amount': 'തുക (₹)',
      'finance_amount_hint': 'ഉദാ: 250',
      'finance_category': 'വിഭാഗം',
      'finance_payment_method': 'പണമിടപാട് രീതി',
      'finance_description': 'വിവരണം',
      'finance_description_hint': 'എന്തിനാണ് ഈ ചിലവ്?',
      'finance_date': 'തീയതി',

      // Health
      'health_title': 'ആരോഗ്യവും ക്ഷേമവും',
      'health_today_status': 'ഇന്നത്തെ അവസ്ഥ',
      'health_add_entry_btn': 'ഇന്നത്തെ രേഖപ്പെടുത്തൂ',
      'health_streak': 'തുടർച്ചയായ ദിവസങ്ങൾ',
      'health_days_logged': 'ദിവസങ്ങൾ രേഖപ്പെടുത്തി',
      'health_avg_mood': 'ശരാശരി മാനസികാവസ്ഥ',
      'health_avg_sleep': 'ശരാശരി ഉറക്കം',
      'health_activity_label': 'വ്യായാമം',
      'health_checkin_history': 'ചെക്ക്-ഇൻ ചരിത്രം',
      'health_mood': 'മാനസികാവസ്ഥ',
      'health_energy': 'ഊർജ്ജ നില',
      'health_sleep': 'ഉറക്കം (മണിക്കൂറുകൾ)',
      'health_activity': 'വ്യായാമം (മിനിറ്റുകൾ)',
      'health_water': 'വെള്ളം കുടിച്ചത് (ലിറ്റർ)',
      'health_notes': 'കുറിപ്പുകൾ',
      'health_notes_hint': 'ഇന്ന് എങ്ങനെയുണ്ടായിരുന്നു?',

      // Habits
      'habits_title': 'ശീലങ്ങളും ലക്ഷ്യങ്ങളും',
      'habits_tab_today': 'ഇന്ന്',
      'habits_tab_week': 'ഈ ആഴ്ച',
      'habits_tab_goals': 'ലക്ഷ്യങ്ങൾ',
      'habits_add_btn': 'പുതിയ ശീലം ചേർക്കൂ',
      'habits_name': 'ശീലത്തിന്റെ പേര്',
      'habits_name_hint': 'ഉദാ: രാവിലെ ധ്യാനം അല്ലെങ്കിൽ നടത്തം',
      'habits_frequency': 'ആവർത്തനം',
      'habits_daily': 'ദിവസേന',
      'habits_weekly': 'ആഴ്ചയിൽ',
      'habits_no_habits': 'ശീലങ്ങൾ ഒന്നും ചേർത്തിട്ടില്ല',
      'habits_empty_hint': '"പുതിയ ശീലം ചേർക്കൂ" അമർത്തി ആരംഭിക്കൂ.',

      // Profile
      'profile_title': 'പ്രൊഫൈൽ',
      'profile_personal_info': 'വ്യക്തിഗത വിവരങ്ങൾ',
      'profile_birth_details': 'ജനന വിവരങ്ങൾ',
      'profile_preferences': 'മുൻഗണനകളും ഭാഷയും',
      'profile_history': 'കൺസൾട്ടേഷൻ ചരിത്രം',
      'profile_my_data': 'എന്റെ വിവരങ്ങൾ',
      'profile_help': 'സഹായവും പിന്തുണയും',
      'profile_privacy': 'സ്വകാര്യതയും സുരക്ഷയും',

      // Login & Common UI
      'welcome_title': 'അവാരയിലേക്ക് സ്വാഗതം',
      'welcome_subtitle': 'ധ്യാനത്തിനും നല്ല ശീലങ്ങൾക്കും ആന്തരിക വളർച്ചയ്ക്കുമുള്ള നിങ്ങളുടെ ദൈനംദിന വഴികാട്ടി',
      'login_email': 'ഇമെയിൽ',
      'login_password': 'പാസ്‌വേഡ്',
      'login_btn': 'അവാരയിൽ പ്രവേശിക്കുക',
      'login_guest_btn': 'അതിഥിയായി തുടരുക (ടൈപ്പിംഗ് ഇല്ലാതെ)',
      'login_no_account': 'അക്കൗണ്ട് ഇല്ലേ? സൈൻ അപ്പ് ചെയ്യുക',
      'explore_by_age': 'പ്രായത്തിനനുസരിച്ച് അവാര അനുഭവിക്കൂ',
      'age_cohort_hint': 'ഒറ്റ ടാപ്പിൽ പ്രായത്തിനനുസരിച്ചുള്ള ഗ്രാഫിക്സും തീമുകളും ആസ്വദിക്കൂ:',
      'five_pillars_connected': '5 തൂണുകളുടെ സമന്വയം: ജ്യോതിഷം • ആരോഗ്യം • ശീലങ്ങൾ • സാമ്പത്തികം • ഉൾക്കാഴ്ച',
      'vedic_wisdom_tag': 'വേദ ജ്ഞാനവും ആധുനിക സ്വയംസഹായവും',
      'five_pillars_title': 'സമഗ്ര ജീവിത പ്രവാഹം',
      'five_pillars_subtitle': '5 ഘടകങ്ങളും പരസ്പരം ബന്ധിതമായ ഒരു പ്രവാഹം',
      'flow_next_btn': 'അടുത്ത ഘട്ടത്തിലേക്ക് നീങ്ങുക ➔',
      'daily_growth_report': 'ദൈനംദിന സമഗ്ര വളർച്ചാ റിപ്പോർട്ട്',
    },

    // =========================================================================
    // MANGLISH (Malayalam in English / Latin script)
    // =========================================================================
    AppLanguage.manglish: {
      // Navigation Tabs
      'tab_home': 'Home',
      'tab_astrology': 'Jyothisham',
      'tab_finance': 'Dhanakaryam',
      'tab_health': 'Aarogyam',
      'tab_track': 'Sheelangal',
      'tab_insights': 'Insights',

      // Greetings
      'greeting_morning': 'Suprabhatham',
      'greeting_afternoon': 'Shubhadinam',
      'greeting_evening': 'Shubhasayahnam',
      'moment_title': 'Ningalkkayi oru nimisham maatti vekkoo',
      'moment_subtitle': 'Ningalude divasam shanthamayi, intention-ode thudanganulla oru ritual.',
      'explore_avara': 'AVARA Explore Cheyyuka',

      // Explore Modules
      'mod_astrology_title': 'Jyothisham',
      'mod_astrology_sub': 'Guidance kandethoo',
      'mod_finance_title': 'Dhanakaryam',
      'mod_finance_sub': 'Expenses track cheyyoo',
      'mod_habits_title': 'Sheelangal',
      'mod_habits_sub': 'Consistency valarthoo',
      'mod_health_title': 'Aarogyam',
      'mod_health_sub': 'Wellness track cheyyoo',
      'mod_insights_title': 'Insights',
      'mod_insights_sub': 'Progress kaanoo',

      // Actions & Common
      'btn_add': 'Add Cheyyuka',
      'btn_save': 'Save Cheyyuka',
      'btn_cancel': 'Cancel',
      'btn_submit': 'Submit',
      'btn_delete': 'Delete Cheyyuka',
      'btn_edit': 'Edit Cheyyuka',
      'btn_back': 'Pinnottu / Back',
      'btn_logout': 'Log out',
      'btn_done': 'Aayi / Done',
      'btn_close': 'Close',
      'coming_soon': 'Udane varunnu!',

      // Language Switcher
      'lang_switch_title': 'Display Language Select Cheyyuka',
      'lang_switch_subtitle': 'App visuals udane update aavum',
      'lang_english': 'English',
      'lang_telugu': 'తెలుగు (Telugu)',
      'lang_tanglish': 'Tanglish (Telugu in English)',
      'lang_malayalam': 'മലയാളം (Malayalam)',
      'lang_manglish': 'Manglish (Malayalam in English)',

      // Voice
      'voice_assistant_title': 'AVARA Voice Assistant',
      'voice_speak_prompt': 'Kekkunnu... Samsarikkoo',
      'voice_tap_to_speak': 'Samsarikkan mic tap cheyyuka',
      'voice_listening': 'Kekkunnu...',
      'voice_stop_listening': 'Stop Cheyyuka',
      'voice_recognized_text': 'Recognized Words:',
      'voice_command_applied': 'Voice command execute cheythu',
      'voice_lang_switched': 'Language change cheythu',
      'voice_try_saying': 'Try cheyyuka: "Change to Malayalam", "Manglish aakkuka", "Open Astrology", "Go to Finance"',

      // Astrology
      'astrology_title': 'Jyothisha Hub',
      'astrology_hero_title': 'AVARA Jyothisham',
      'astrology_hero_tagline': 'Chodyangal Chodikkoo. Perspectives Nedoo.',
      'astrology_hero_sub': 'Life journey-kku nalla guidance',
      'astrology_tile_ask': 'Chodyam Chodikkoo',
      'astrology_tile_topics': 'Topics Explore Cheyyoo',
      'astrology_tile_astrologer': 'Astrologer-odu Samsarikkoo',
      'astrology_disclaimer': 'Astrology traditional interpretations nalkunnu, guaranteed outcomes alla.',
      'astrology_chat_title': 'AVARA Jyothisham',
      'astrology_chat_subtitle': 'Gemini Powered • Vedic Astrology',
      'astrology_input_hint': 'Jathakathe patti chodikkoo…',
      'astrology_birth_profile_title': 'Birth Profile & Kundali Evidence',
      'astrology_dob': 'Janana Theeyathi (DOB)',
      'astrology_tob': 'Janana Samayam (Time)',
      'astrology_pob': 'Janicha Sthalam (Place)',
      'astrology_pob_hint': 'City or Town (e.g. Kochi)',
      'astrology_ayanamsa': 'Ayanamsa',
      'astrology_generate_btn': 'Chart Calculate Cheyyuka',
      'astrology_calculating': 'Kundali calculate cheyyunnu…',

      // Finance
      'finance_title': 'Dhanakaryam (Finance)',
      'finance_total_spend': 'Aake Chilavu',
      'finance_this_month': 'Ee Masathe Chilavu',
      'finance_spending_cats': 'Chilavukalude Categories',
      'finance_recent_expenses': 'Recent Transactions',
      'finance_total_label': 'total',
      'finance_add_expense_btn': 'Chilavu Add Cheyyuka',
      'finance_amount': 'Thuka / Amount (₹)',
      'finance_amount_hint': 'e.g. 250',
      'finance_category': 'Category',
      'finance_payment_method': 'Payment Mode',
      'finance_description': 'Description',
      'finance_description_hint': 'Enthinaanu ee chilavu?',
      'finance_date': 'Date',

      // Health
      'health_title': 'Aarogyam & Wellness',
      'health_today_status': 'Innathe Status',
      'health_add_entry_btn': 'Innathe Log Cheyyuka',
      'health_streak': 'Streak',
      'health_days_logged': 'days logged',
      'health_avg_mood': 'Avg Mood',
      'health_avg_sleep': 'Avg Sleep',
      'health_activity_label': 'Activity',
      'health_checkin_history': 'Check-in History',
      'health_mood': 'Mood',
      'health_energy': 'Energy Level',
      'health_sleep': 'Urakkam (Hours)',
      'health_activity': 'Activity / Walk (Minutes)',
      'health_water': 'Vellam (Liters)',
      'health_notes': 'Notes',
      'health_notes_hint': 'Innu enganeyundarunnu?',

      // Habits
      'habits_title': 'Sheelangalum Goals-um',
      'habits_tab_today': 'Innu',
      'habits_tab_week': 'Ee Aazhcha',
      'habits_tab_goals': 'Goals',
      'habits_add_btn': 'Sheelam Add Cheyyuka',
      'habits_name': 'Sheelathinte Peru',
      'habits_name_hint': 'e.g. Ravile Walk / Meditation',
      'habits_frequency': 'Frequency',
      'habits_daily': 'Daily',
      'habits_weekly': 'Weekly',
      'habits_no_habits': 'Sheelangal onnum illa',
      'habits_empty_hint': '"Sheelam Add Cheyyuka" tap cheythu start cheyyoo.',

      // Profile
      'profile_title': 'Profile',
      'profile_personal_info': 'Personal Information',
      'profile_birth_details': 'Birth Details',
      'profile_preferences': 'Preferences & Language',
      'profile_history': 'Consultation History',
      'profile_my_data': 'Ente Data',
      'profile_help': 'Help & Support',
      'profile_privacy': 'Privacy & Security',

      // Login & Common UI
      'welcome_title': 'AVARA-yilekku Swagatham',
      'welcome_subtitle': 'Dhyanathinum nalla sheelhangalkkum aantharika valarchaykkumulla vazhikaatti',
      'login_email': 'Email',
      'login_password': 'Password',
      'login_btn': 'AVARA-yil Sign In cheyyoo',
      'login_guest_btn': 'Guest aayi continue cheyyoo (No typing)',
      'login_no_account': 'Account ille? Sign up cheyyoo',
      'explore_by_age': 'Age group anusarichu AVARA experience cheyyoo',
      'age_cohort_hint': '1-Tap-il age-adaptive graphics & themes anubhavikkoo:',
      'five_pillars_connected': '5 Pillars Connected: Jyothisham • Aarogyam • Sheelangal • Sambathikam • Insights',
      'vedic_wisdom_tag': 'Vedic Jnanam & Modern Self-Help',
      'five_pillars_title': 'Unified Life Ecosystem',
      'five_pillars_subtitle': '5 pillars connected as one seamless life flow',
      'flow_next_btn': 'Next Pillar-ilekku Pokuka ➔',
      'daily_growth_report': 'Daily Holistic Growth Report',
    },
  };
}
