import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

enum UserType { admin, nurse, guardian }

class AuthProvider extends ChangeNotifier {
  UserType _selectedUserType = UserType.guardian;

  UserType get selectedUserType => _selectedUserType;

  void setUserType(UserType userType) {
    _selectedUserType = userType;
    notifyListeners();
  }

  String _getRolePath() {
    switch (_selectedUserType) {
      case UserType.admin:
        return 'admin';
      case UserType.nurse:
        return 'nurses';
      case UserType.guardian:
        return 'guardians';
    }
  }

  Future<bool> sendOtp(String email) async {
    try {
      final String rolePath = _getRolePath();
      final String requestUrl = '${ApiConstants.baseUrl}/$rolePath/auth/request-otp';
      
      debugPrint('Sending request to $requestUrl');

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR in sendOtp: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    try {
      final String rolePath = _getRolePath();
      final String requestUrl = '${ApiConstants.baseUrl}/$rolePath/auth/verify-otp';

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otpCode': otpCode,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Verification failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otpCode, String newPassword, String confirmPassword) async {
    try {
      final String rolePath = _getRolePath();
      final String requestUrl = '${ApiConstants.baseUrl}/$rolePath/auth/reset-password';

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Password reset failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.'
      };
    }
  }

  Future<void> login({
    required String username,
    required String password,
    required UserType userType,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}