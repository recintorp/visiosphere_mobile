import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuardianSettingsProvider extends ChangeNotifier {
  bool _pushEnabled = true;
  bool _isLoading = false;

  bool get pushEnabled => _pushEnabled;
  bool get isLoading => _isLoading;

  GuardianSettingsProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _pushEnabled = prefs.getBool('guardian_push_enabled') ?? true;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> togglePushNotifications(bool value) async {
    _pushEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guardian_push_enabled', value);
  }
}