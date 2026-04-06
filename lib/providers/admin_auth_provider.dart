import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isFirstLogin = false;
  bool _requires2FA = false;
  String? _adminId;
  String? _tempToken;
  String? _token;
  Map<String, dynamic>? _adminData;
  String? _errorMessage;
  bool _isPasswordSet = false;

  bool get isLoading => _isLoading;
  bool get isFirstLogin => _isFirstLogin;
  bool get requires2FA => _requires2FA;
  String? get adminId => _adminId;
  String? get tempToken => _tempToken;
  String? get token => _token;
  Map<String, dynamic>? get adminData => _adminData;
  String? get errorMessage => _errorMessage;
  bool get isPasswordSet => _isPasswordSet;
  bool get isLoggedIn => _token != null;

  Future<void> login(String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.loginAdmin(adminId: adminId);

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _requires2FA = data['requires2FA'] ?? false;
      _adminId = data['customId'] ?? adminId; 
      _adminData = data['admin'];

      if (_isFirstLogin) {
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
      } else if (_requires2FA) {
        _isPasswordSet = true;
      } else {
        _token = data['token'];
        _isPasswordSet = true;
      }
    } else {
      _errorMessage = result['message'] ?? 'Login failed';
    }

    notifyListeners();
  }

  Future<void> loginWithPassword(String adminId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.loginAdmin(
      adminId: adminId,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _requires2FA = data['requires2FA'] ?? false;
      _adminId = data['customId'] ?? adminId;
      _adminData = data['admin'];

      if (_isFirstLogin) {
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
      } else if (_requires2FA) {
        _isPasswordSet = true;
      } else {
        _token = data['token'];
        _isPasswordSet = true;
      }
    } else {
      _errorMessage = result['message'] ?? 'Invalid credentials';
    }

    notifyListeners();
  }

  Future<void> verify2FA(String adminId, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.verifyAdmin2FA(
      adminId: adminId,
      pin: pin,
    );

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      _token = data['token'];
      _requires2FA = false;
      _adminData = data['admin'] ?? _adminData;
    } else {
      _errorMessage = result['message'] ?? 'Invalid PIN';
    }

    notifyListeners();
  }

  Future<bool> toggle2FA(String adminId, bool enable, {String? pin}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.toggleAdmin2FA(
      adminId: adminId,
      enable: enable,
      pin: pin,
    );

    _isLoading = false;

    if (result['success']) {
      if (_adminData != null) {
        _adminData!['is2FAEnabled'] = enable;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to toggle 2FA';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPassword(
    String adminId,
    String newPassword,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.setAdminPassword(
      adminId: adminId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    _isLoading = false;

    if (result['success']) {
      _isPasswordSet = true;
      _isFirstLogin = false;
      _token = null; 
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to set password';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isLoading = false;
    _isFirstLogin = false;
    _requires2FA = false;
    _adminId = null;
    _tempToken = null;
    _token = null;
    _adminData = null;
    _errorMessage = null;
    _isPasswordSet = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void cancel2FA() {
    _requires2FA = false;
    _adminId = null;
    _adminData = null;
    notifyListeners();
  }
}