import 'package:flutter/material.dart';
import 'dart:io'; // <-- ADDED THIS
import '../services/api_service.dart';

class GuardianAuthProvider extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  bool _isFirstLogin = false;
  String? _guardianId;
  String? _tempToken;
  String? _token;
  Map<String, dynamic>? _guardianData;
  String? _errorMessage;
  bool _isPasswordSet = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isFirstLogin => _isFirstLogin;
  String? get guardianId => _guardianId;
  String? get tempToken => _tempToken;
  String? get token => _token;
  Map<String, dynamic>? get guardianData => _guardianData;
  String? get errorMessage => _errorMessage;
  bool get isPasswordSet => _isPasswordSet;
  bool get isLoggedIn => _token != null;

  // ==========================================
  // 1. LOGIN (No Password Provided)
  // ==========================================
  Future<void> login(String guardianId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Call API with only Guardian ID
    final result = await ApiService.loginGuardian(guardianId: guardianId);

    _isLoading = false;

    if (result['success']) {
      final data = result['data']; // The parsed JSON from backend
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _guardianId = guardianId;
      _guardianData = data['guardian'];

      if (_isFirstLogin) {
        // Backend flagged this as a first login!
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
        print('🔄 [LOGIN] First login detected. Setup needed.');
      } else {
        // This shouldn't typically happen if password is empty and it's not first login,
        // because backend would return a 400 Error. Handled just in case.
        _token = data['token'];
        _isPasswordSet = true;
      }
    } else {
      _errorMessage = result['message'] ?? 'Login failed';
      print('❌ [LOGIN FAILED] Error: $_errorMessage');
    }

    notifyListeners();
  }

  // ==========================================
  // 2. LOGIN WITH PASSWORD (Subsequent Logins)
  // ==========================================
  Future<void> loginWithPassword(String guardianId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.loginGuardian(
      guardianId: guardianId,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      final data = result['data'];
      
      _isFirstLogin = data['isFirstLogin'] ?? false;
      _guardianId = guardianId;
      _guardianData = data['guardian'];

      if (_isFirstLogin) {
        // Even if they typed a password, backend says they need to set a permanent one
        _tempToken = data['tempToken'];
        _isPasswordSet = false;
        print('🔄 [LOGIN] First login detected despite password input.');
      } else {
        // Normal successful login
        _token = data['token'];
        _isPasswordSet = true;
        print('✅ [LOGIN SUCCESS] Guardian logged in.');
      }
    } else {
      _errorMessage = result['message'] ?? 'Invalid credentials';
      print('❌ [LOGIN FAILED] Error: $_errorMessage');
    }

    notifyListeners();
  }

  // ==========================================
  // 3. SET PASSWORD
  // ==========================================
  Future<bool> setPassword(
    String guardianId,
    String newPassword,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.setPassword(
      guardianId: guardianId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    _isLoading = false;

    if (result['success']) {
      _isPasswordSet = true;
      _isFirstLogin = false;
      
      // FIXED: Do NOT look for a token here. Our secure backend requires 
      // them to log in again after setting a new password.
      _token = null; 

      print('✅ [SET PASSWORD SUCCESS] Guardian: $guardianId updated.');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to set password';
      print('❌ [SET PASSWORD FAILED] Error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 4. UPDATE PROFILE DATA 
  // ==========================================
  Future<bool> updateProfile(Map<String, dynamic> updatedFields) async {
    if (_guardianId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.updateGuardian(_guardianId!, updatedFields);

    _isLoading = false;

    if (result['success']) {
      // Merge the new data into our existing state so the UI updates instantly
      _guardianData = {
        ...?_guardianData,
        ...updatedFields,
      };
      print('✅ [GUARDIAN UPDATE SUCCESS] Profile updated locally and on DB.');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to update profile';
      print('❌ [GUARDIAN UPDATE FAILED] Error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 5. UPLOAD PROFILE PHOTO (NEW!)
  // ==========================================
  Future<bool> uploadPhoto(File imageFile) async {
    if (_guardianId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.uploadProfilePhoto(_guardianId!, imageFile);

    _isLoading = false;

    if (result['success']) {
      // The backend returns the fully updated guardian object, so we overwrite our local data
      _guardianData = result['data']['guardian'];
      print('✅ [GUARDIAN UPLOAD SUCCESS] Profile photo updated.');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to upload photo';
      print('❌ [GUARDIAN UPLOAD FAILED] Error: $_errorMessage');
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
    _guardianId = null;
    _tempToken = null;
    _token = null;
    _guardianData = null;
    _errorMessage = null;
    _isPasswordSet = false;
    notifyListeners();

    print('🔓 [LOGOUT] All auth data cleared');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}