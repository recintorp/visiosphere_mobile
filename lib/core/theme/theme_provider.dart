import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'appTheme';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? 'default';
    _themeMode = _parseThemeMode(savedTheme);
    notifyListeners();
  }

  Future<void> setTheme(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeString);
    
    _themeMode = _parseThemeMode(themeString);
    notifyListeners();
  }

  Future<void> syncWithDbTheme(String dbTheme) async {
    String localThemeStr = 'default';
    if (dbTheme.toLowerCase() == 'light') localThemeStr = 'light';
    if (dbTheme.toLowerCase() == 'dark') localThemeStr = 'dark';
    
    await setTheme(localThemeStr);
  }

  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'auto':
      case 'default':
      default:
        return ThemeMode.system;
    }
  }
}