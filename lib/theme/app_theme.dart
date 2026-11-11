import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AVARA's global Material 3 light theme.
///
/// Applied at the root [MaterialApp]. It drives the text theme from Google
/// Fonts (Inter) with high-contrast deep-navy text, flat deep-navy rounded
/// buttons, and a near-white scaffold background.
class AppTheme {
  AppTheme._();

  /// Shared corner radius for buttons.
  static const double buttonRadius = 100; // pill shape — matches Figma "Get Started" button

  /// Standard height for full-width action buttons.
  static const double buttonHeight = 54;

  /// Shared corner radius for cards.
  static const double cardRadius = 16;

  /// The single light theme used across the app.
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.deepNavy,
        secondary: AppColors.blue,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSurface: AppColors.deepNavy,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  /// Builds a high-contrast Inter text theme, keeping the default Material 3
  /// type scale but recoloring it with the AVARA navy/secondary-text tokens.
  static TextTheme _buildTextTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      displayLarge: inter.displayLarge
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
      displayMedium: inter.displayMedium
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
      displaySmall: inter.displaySmall
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
      headlineLarge: inter.headlineLarge
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
      headlineMedium: inter.headlineMedium
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      headlineSmall: inter.headlineSmall
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      titleLarge:
          inter.titleLarge?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      titleMedium: inter.titleMedium
          ?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      titleSmall:
          inter.titleSmall?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(color: AppColors.deepNavy),
      bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.deepNavy),
      bodySmall: inter.bodySmall?.copyWith(color: AppColors.secondaryText),
      labelLarge:
          inter.labelLarge?.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      labelMedium: inter.labelMedium
          ?.copyWith(color: AppColors.secondaryText, fontWeight: FontWeight.w600),
      labelSmall: inter.labelSmall
          ?.copyWith(color: AppColors.secondaryText, fontWeight: FontWeight.w500),
    );
  }
}
