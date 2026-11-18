import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported display language modes for the AVARA app UI visuals.
enum AppLanguage {
  english,
  telugu,
  tanglish,
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
      'astrology_input_hint': 'Ask about your chart… (or tap mic)',
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
      'astrology_input_hint': 'మీ జాతకం గురించి అడగండి… (లేదా మైక్ నొక్కండి)',
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
      'astrology_input_hint': 'Mee chart gurinchi adagandi… (mic tap cheyandi)',
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
    },
  };
}
