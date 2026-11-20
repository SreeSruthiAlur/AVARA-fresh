import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User age classification to dynamically tailor graphics, UX tone, and content.
enum AgeGroup {
  youth, // Under 22: energetic, neon/vibrant accents, gamified study & career exploration
  adult, // 22 - 45: modern, sleek executive, mindfulness, work-life balance, wealth
  senior, // 45+: warm saffron/gold/sage, high-contrast, sacred lotus/geometry, peace & wellness
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
          cardBackground: Color(0xFFF3F0FF),
          badgeColor: Color(0xFFFF7675),
          iconData: Icons.bolt_rounded,
          textScaleFactor: 1.0,
          graphicStyleDescription: 'Constellation particle waves & XP energy rings',
        );
      case AgeGroup.adult:
        return const AgeThemeConfig(
          group: AgeGroup.adult,
          displayName: 'Achiever & Mindful Professional (22 - 45)',
          tagline: 'Sleek, executive clarity, financial mindfulness & balance',
          primaryAccent: Color(0xFF1E3A8A), // Deep Navy
          secondaryAccent: Color(0xFF0D9488), // Ocean Teal
          cardBackground: Color(0xFFEFF6FF),
          badgeColor: Color(0xFF3B82F6),
          iconData: Icons.self_improvement_rounded,
          textScaleFactor: 1.05,
          graphicStyleDescription: 'Minimalist geometric mandalas & circadian sine curves',
        );
      case AgeGroup.senior:
        return const AgeThemeConfig(
          group: AgeGroup.senior,
          displayName: 'Grace & Serenity (45+)',
          tagline: 'Calming, sacred saffron & sandalwood, peace & daily health',
          primaryAccent: Color(0xFFB45309), // Warm Temple Amber / Saffron
          secondaryAccent: Color(0xFF047857), // Deep Sage
          cardBackground: Color(0xFFFFFBEB),
          badgeColor: Color(0xFFD97706),
          iconData: Icons.spa_rounded,
          textScaleFactor: 1.15,
          graphicStyleDescription: 'Sacred blooming lotus & traditional high-contrast geometry',
        );
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
