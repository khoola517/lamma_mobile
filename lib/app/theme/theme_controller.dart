import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

/// ThemeController manages the current ThemeMode (Light, Dark, or System)
/// and persists the user preference across app sessions using SharedPreferences.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static const String _prefKey = 'khadematy_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeController({ThemeMode initialMode = ThemeMode.light})
      : _themeMode = initialMode {
    WidgetsBinding.instance.addObserver(this);
    _initTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Returns true if the active theme is currently dark (either explicitly or via system)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  /// Arabic human-readable label of the active theme mode
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'الوضع الداكن';
      case ThemeMode.light:
        return 'الوضع الفاتح';
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
    }
  }

  Future<void> _initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (saved == 'light') {
        _themeMode = ThemeMode.light;
      } else if (saved == 'system') {
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('ThemeController: Could not load theme preference ($e)');
    } finally {
      _isInitialized = true;
      _syncColors();
      notifyListeners();
    }
  }

  /// Sets the theme mode to light, dark, or system and persists the choice
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    _syncColors();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system';
      await prefs.setString(_prefKey, value);
    } catch (e) {
      debugPrint('ThemeController: Could not save theme preference ($e)');
    }
  }

  /// Convenience toggle between Dark and Light mode
  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void _syncColors() {
    AppColors.setDarkMode(isDarkMode);
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      _syncColors();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

