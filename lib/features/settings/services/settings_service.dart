import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings using shared_preferences.
class SettingsService {
  static const _themeKey = 'theme_mode';

  /// Loads the User's preferred ThemeMode from local storage.
  Future<ThemeMode> themeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      if (themeString == 'light') {
        return ThemeMode.light;
      } else if (themeString == 'dark') {
        return ThemeMode.dark;
      } else if (themeString == 'system') {
        return ThemeMode.system;
      }
    } catch (e) {
      // Fallback in case of storage read issues
      debugPrint('Error loading theme mode: $e');
    }
    return ThemeMode.system;
  }

  /// Persists the user's preferred ThemeMode to local storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
