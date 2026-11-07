import 'package:flutter/material.dart';

/// Central Color Palette matching Stitch Design System for Khidmati (خِدمتي)
/// with full dynamic Dark & Light mode color tokens.
class AppColors {
  AppColors._();

  static bool _isDark = false;

  /// Returns whether dark mode is currently active
  static bool get isDarkMode => _isDark;

  /// Sets dark mode state (invoked by ThemeController and KhadematyApp builder)
  static void setDarkMode(bool value) {
    _isDark = value;
  }

  // Primary Gold Brand Colors (Fixed across themes)
  static const Color primary = Color(0xFFFCC201);
  static const Color primaryDark = Color(0xFFC69320);
  static const Color primaryHover = Color(0xFFDBA514);
  static const Color primarySoft = Color(0xFFEEB609);

  // Champagne & Gold Accents
  static const Color champagne = Color(0xFFC8A96B);
  static const Color champagneLight = Color(0xFFF3EBDD);
  static const Color champagneDark = Color(0xFF9E7C42);
  static const Color goldYellow = Color(0xFFF8CA27);
  static const Color brandGold = Color(0xFFDE9B04);

  // Light Palette Base Constants
  static const Color lightBackground = Color(0xFFF1ECE3);
  static const Color lightSurface = Color(0xFFF7F3EC);
  static const Color lightSurfaceWarm = Color(0xFFFCF9F4);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceSection = Color(0xFFF1ECE3);

  static const Color lightTextPrimary = Color(0xFF2E2527);
  static const Color lightTextSecondary = Color(0xFF6F6265);
  static const Color lightTextTertiary = Color(0xFF968A8D);
  static const Color lightTextLight = Color(0xFFFFFFFF);

  static const Color lightBorderDefault = Color(0xFFE5DED4);
  static const Color lightBorderLight = Color(0xFFEEE8DF);
  static const Color lightBorderStrong = Color(0xFFD8CEC2);
  static const Color lightBorderChipSelected = Color(0xFFE5CED5);

  static const Color lightPrimaryLight = Color(0xFFF4E7EB);
  static const Color lightPrimaryVeryLight = Color(0xFFFAF3F5);

  // Dark Palette Base Constants
  static const Color darkBackground = Color(0xFF121215);
  static const Color darkSurface = Color(0xFF191820);
  static const Color darkSurfaceWarm = Color(0xFF1E1D26);
  static const Color darkSurfaceCard = Color(0xFF24222E);
  static const Color darkSurfaceSection = Color(0xFF16151D);

  static const Color darkTextPrimary = Color(0xFFF6F4F0);
  static const Color darkTextSecondary = Color(0xFFB5B0C0);
  static const Color darkTextTertiary = Color(0xFF7E7A8A);

  static const Color darkBorderDefault = Color(0xFF343042);
  static const Color darkBorderLight = Color(0xFF262432);
  static const Color darkBorderStrong = Color(0xFF403C52);
  static const Color darkBorderChipSelected = Color(0xFF524726);

  static const Color darkPrimaryLight = Color(0xFF332900);
  static const Color darkPrimaryVeryLight = Color(0xFF251E00);

  // Dynamic getters that adapt automatically according to the active theme mode
  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get surfaceWarm => _isDark ? darkSurfaceWarm : lightSurfaceWarm;
  static Color get surfaceCard => _isDark ? darkSurfaceCard : lightSurfaceCard;
  static Color get surfaceSection => _isDark ? darkSurfaceSection : lightSurfaceSection;

  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textTertiary => _isDark ? darkTextTertiary : lightTextTertiary;
  static Color get textLight => const Color(0xFFFFFFFF);

  static Color get borderDefault => _isDark ? darkBorderDefault : lightBorderDefault;
  static Color get borderLight => _isDark ? darkBorderLight : lightBorderLight;
  static Color get borderStrong => _isDark ? darkBorderStrong : lightBorderStrong;
  static Color get borderChipSelected => _isDark ? darkBorderChipSelected : lightBorderChipSelected;

  static Color get primaryLight => _isDark ? darkPrimaryLight : lightPrimaryLight;
  static Color get primaryVeryLight => _isDark ? darkPrimaryVeryLight : lightPrimaryVeryLight;

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color indicatorInactive = Color(0xFFD8CEC2);

  // Context-aware dynamic color getters
  static Color dynamicBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color dynamicSurfaceCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceCard
          : lightSurfaceCard;

  static Color dynamicSurfaceWarm(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceWarm
          : lightSurfaceWarm;

  static Color dynamicSurfaceSection(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceSection
          : lightSurfaceSection;

  static Color dynamicTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color dynamicTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color dynamicTextTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextTertiary
          : lightTextTertiary;

  static Color dynamicBorderDefault(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorderDefault
          : lightBorderDefault;

  static Color dynamicBorderLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorderLight
          : lightBorderLight;

  static Color dynamicPrimaryLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkPrimaryLight
          : lightPrimaryLight;

  static Color dynamicPrimaryVeryLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkPrimaryVeryLight
          : lightPrimaryVeryLight;
}

/// Extension on BuildContext for quick, clean, ergonomic dynamic theme color access:
/// e.g. context.surfaceCard, context.textPrimary, context.isDarkMode
extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor => AppColors.dynamicBackground(this);
  Color get surfaceCard => AppColors.dynamicSurfaceCard(this);
  Color get surfaceWarm => AppColors.dynamicSurfaceWarm(this);
  Color get surfaceSection => AppColors.dynamicSurfaceSection(this);

  Color get textPrimary => AppColors.dynamicTextPrimary(this);
  Color get textSecondary => AppColors.dynamicTextSecondary(this);
  Color get textTertiary => AppColors.dynamicTextTertiary(this);

  Color get borderDefault => AppColors.dynamicBorderDefault(this);
  Color get borderLight => AppColors.dynamicBorderLight(this);

  Color get primaryLight => AppColors.dynamicPrimaryLight(this);
  Color get primaryVeryLight => AppColors.dynamicPrimaryVeryLight(this);
}
