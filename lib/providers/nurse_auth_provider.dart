import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NurseAuthProvider extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  bool _isFirstLogin = false;
  String? _nurseId;
  String? _tempToken;
  String? _token;
  Map<String, dynamic>? _nurseData;
  String? _errorMessage;
  bool _isPasswordSet = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isFirstLogin => _isFirstLogin;
  String? get nurseId => _nurseId;
  String? get tempToken => _tempToken;
  String? get token => _token;
  Map<String, dynamic>? get nurseData => _nurseData;
  String? get errorMessage => _errorMessage;
  bool get isPasswordSet => _isPasswordSet;
  bool get isLoggedIn => _token != null;

  // ==========================================
  // 1. LOGIN (No Password Provided - First Time)
  // ==========================================
  Future<void> login(String nurseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Call API with only Nurse ID
    final result = await ApiService.loginNurse(nurseId: nurseId);

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _nurseId = data['nurseId'] ?? nurseId; 
      _nurseData = data['nurse'];

      if (_isFirstLogin) {
        // Backend flagged this as a first login (New Nurse)
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
        print('🔄 [NURSE LOGIN] First login detected. Setup needed.');
      } else {
        // Normal successful login (Shouldn't happen without password, but handled safely)
        _token = data['token'];
        _isPasswordSet = true;
      }
    } else {
      _errorMessage = result['message'] ?? 'Login failed';
      print('❌ [NURSE LOGIN FAILED] Error: $_errorMessage');
    }

    notifyListeners();
  }

  // ============================================
  // 2. LOGIN WITH PASSWORD (Normal Login)
  // ============================================
  Future<void> loginWithPassword(String nurseId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.loginNurse(
      nurseId: nurseId,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _nurseId = data['nurseId'] ?? nurseId;
      _nurseData = data['nurse'];

      if (_isFirstLogin) {
        // Even if they typed a password, backend says they need to set a permanent one
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
        print('🔄 [NURSE LOGIN] First login detected despite password input.');
      } else {
        // Normal successful login
        _token = data['token'];
        _isPasswordSet = true;
        print('✅ [NURSE LOGIN SUCCESS] Nurse logged in.');
      }
    } else {
      _errorMessage = result['message'] ?? 'Invalid credentials';
      print('❌ [NURSE LOGIN FAILED] Error: $_errorMessage');
    }

    notifyListeners();
  }

  // ==========================================
  // 3. SET PASSWORD
  // ==========================================
  Future<bool> setPassword(
    String nurseId,
    String newPassword,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.setNursePassword(
      nurseId: nurseId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    _isLoading = false;

    if (result['success']) {
      _isPasswordSet = true;
      _isFirstLogin = false;
      
      // Clear token to force them to log in with their fresh credentials
      _token = null; 

      print('✅ [NURSE SET PASSWORD SUCCESS] Nurse: $nurseId updated.');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to set password';
      print('❌ [NURSE SET PASSWORD FAILED] Error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // UTILITIES
  // ==========================================
  void logout() {
    _isLoading = false;
    _isFirstLogin = false;
    _nurseId = null;
    _tempToken = null;
    _token = null;
    _nurseData = null;
    _errorMessage = null;
    _isPasswordSet = false;
    notifyListeners();

    print('🔓 [NURSE LOGOUT] All auth data cleared');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}