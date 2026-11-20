import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User survey response record for personalizing self-help guidance.
class UserSurveyProfile {
  const UserSurveyProfile({
    required this.ageGroup,
    required this.primaryFocus,
    required this.habitChallenge,
    required this.guidanceStyle,
    required this.completedAt,
  });

  final AgeGroup ageGroup;
  final String primaryFocus;
  final String habitChallenge;
  final String guidanceStyle;
  final DateTime completedAt;
}

/// Service managing the onboarding self-help survey.
class SurveyService extends ChangeNotifier {
  SurveyService._();
  static final SurveyService instance = SurveyService._();

  static const String _keyCompleted = 'avara_survey_completed';
  static const String _keyFocus = 'avara_survey_focus';
  static const String _keyChallenge = 'avara_survey_challenge';
  static const String _keyStyle = 'avara_survey_style';

  bool _isCompleted = false;
  UserSurveyProfile? _profile;

  bool get isCompleted => _isCompleted;
  UserSurveyProfile? get profile => _profile;

  Future<void> loadSurveyState() async {
    final prefs = await SharedPreferences.getInstance();
    _isCompleted = prefs.getBool(_keyCompleted) ?? false;
    if (_isCompleted) {
      await AgeProfileService.instance.loadPreferences();
      _profile = UserSurveyProfile(
        ageGroup: AgeProfileService.instance.ageGroup,
        primaryFocus: prefs.getString(_keyFocus) ?? 'Inner Peace',
        habitChallenge: prefs.getString(_keyChallenge) ?? 'Inconsistent Routine',
        guidanceStyle: prefs.getString(_keyStyle) ?? 'Practical & Actionable',
        completedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<void> saveSurveyResponse({
    required AgeGroup ageGroup,
    required String primaryFocus,
    required String habitChallenge,
    required String guidanceStyle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
    await prefs.setString(_keyFocus, primaryFocus);
    await prefs.setString(_keyChallenge, habitChallenge);
    await prefs.setString(_keyStyle, guidanceStyle);

    // Synchronize age group to AgeProfileService for dynamic app graphics
    await AgeProfileService.instance.setAgeGroup(ageGroup);

    _isCompleted = true;
    _profile = UserSurveyProfile(
      ageGroup: ageGroup,
      primaryFocus: primaryFocus,
      habitChallenge: habitChallenge,
      guidanceStyle: guidanceStyle,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> resetSurvey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompleted);
    _isCompleted = false;
    _profile = null;
    notifyListeners();
  }
}
