import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _userId;
  String? _userName;
  String? _userRole;
  String? _profilePicBase64;
  bool _isFirstLogin = false;
  bool _requires2FA = false;
  Map<String, dynamic>? _tempAuthData;

  bool get isLoading           => _isLoading;
  String? get errorMessage     => _errorMessage;
  String? get token            => _token;
  String? get userId           => _userId;
  String? get userName         => _userName;
  String? get userRole         => _userRole;
  String? get profilePicBase64 => _profilePicBase64;
  bool get isFirstLogin        => _isFirstLogin;
  bool get requires2FA         => _requires2FA;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String loginId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final checkId    = loginId.trim();
    final isNurse    = checkId.toUpperCase().startsWith('N-');
    final isAdmin    = checkId.toUpperCase().startsWith('A-');
    final isGuardian = checkId.toUpperCase().startsWith('G-');
    final isEmail    = checkId.contains('@');

    if (!isNurse && !isAdmin && !isGuardian && !isEmail) {
      _errorMessage = 'Invalid format or credentials provided.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      String rolePath = 'admin';
      Map<String, String> payload = {'customId': checkId, 'password': password};

      if (isNurse) {
        rolePath = 'nurses';
        payload  = {'nurseId': checkId, 'password': password};
      } else if (isGuardian) {
        rolePath = 'guardians';
        payload  = {'guardianId': checkId, 'password': password};
      }

      Response response = await _makeLoginRequest(rolePath, payload);

      if (isEmail && response.statusCode != 200) {
        rolePath = 'nurses';
        payload  = {'nurseId': checkId, 'password': password};
        response = await _makeLoginRequest(rolePath, payload);

        if (response.statusCode != 200) {
          rolePath = 'guardians';
          payload  = {'guardianId': checkId, 'password': password};
          response = await _makeLoginRequest(rolePath, payload);
        }
      }

      if (response.statusCode != 200) {
        final msg = response.data?['message'];
        _errorMessage = (msg is String && msg.isNotEmpty)
            ? msg
            : 'Invalid credentials. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['isFirstLogin'] == true) {
        _isFirstLogin  = true;
        _tempAuthData  = data;
        _errorMessage  = 'First-time login detected. Please use the Account Setup option.';
        _isLoading     = false;
        notifyListeners();
        return false;
      }

      if (data['requires2FA'] == true) {
        _requires2FA  = true;
        _tempAuthData = data;
        _isLoading    = false;
        notifyListeners();
        return true;
      }

      await _saveAuthData(data, rolePath);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Account not found or invalid credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = 'Connection error. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Response> _makeLoginRequest(
    String rolePath,
    Map<String, dynamic> payload,
  ) async {
    final String path = rolePath == 'admin'
        ? ApiConstants.adminLogin
        : '/$rolePath/auth/login';

    return await DioClient.instance.post(
      path,
      data: payload,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<void> _saveAuthData(
    Map<String, dynamic> data,
    String rolePath,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    _token = data['token'] as String?;

    if (rolePath == 'admin') {
      final admin       = data['admin'] ?? data['user'] ?? {};
      _userId           = admin['customId'];
      _userName         = admin['name'];
      _userRole         = admin['role'] ?? 'Facility Admin';
      _profilePicBase64 = admin['profilePic'];
    } else if (rolePath == 'nurses') {
      final nurse       = data['nurse'] ?? data['user'] ?? {};
      _userId           = nurse['nurseId'];
      _userName         = '${nurse['firstName']} ${nurse['lastName']}';
      _userRole         = 'Nurse';
      _profilePicBase64 = nurse['profilePic'];
    } else {
      final guardian    = data['guardian'] ?? data['user'] ?? {};
      _userId           = guardian['guardianId'];
      _userName         = '${guardian['firstName']} ${guardian['lastName']}';
      _userRole         = 'Guardian';
      _profilePicBase64 = guardian['profilePic'];
    }

    if (_token == null || _token!.isEmpty || _userId == null || _userId!.isEmpty) {
      _token = null;
      _userId = null;
      _userName = null;
      _userRole = null;
      _profilePicBase64 = null;
      throw Exception('Auth data incomplete — aborting save.');
    }

    await SecureStorageService.saveAuthData(
      token:      _token!,
      userId:     _userId!,
      userRole:   _userRole ?? '',
      userName:   _userName ?? '',
      profilePic: _profilePicBase64,
    );

    await prefs.setString('userRole', _userRole ?? '');
    await prefs.setString('userName', _userName ?? '');
  }

  Future<bool> verify2FA(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool isNurse2FA = _tempAuthData?.containsKey('nurse') == true &&
          !(_tempAuthData?.containsKey('admin') == true);

      late Response response;

      if (isNurse2FA) {
        final String nurseId = _tempAuthData?['nurse']?['nurseId'] ?? '';
        response = await DioClient.instance.post(
          '/nurses/auth/verify-2fa',
          data: {'nurseId': nurseId, 'pin': pin},
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
      } else {
        final String customId = _tempAuthData?['admin']?['customId'] ?? '';
        response = await DioClient.instance.post(
          ApiConstants.adminVerify2FA,
          data: {'customId': customId, 'pin': pin},
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
      }

      final data = response.data as Map<String, dynamic>;

      if (response.statusCode == 200) {
        _requires2FA = false;

        String rolePathToSave = isNurse2FA ? 'nurses' : 'admin';
        final dataToSave = data.containsKey('token') ? data : _tempAuthData!;
        if (dataToSave.containsKey('guardian')) rolePathToSave = 'guardians';

        await _saveAuthData(dataToSave, rolePathToSave);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = data['message'] ?? 'Invalid PIN.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Invalid PIN.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Connection error.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String email, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String path = role.toLowerCase() == 'admin'
          ? ApiConstants.adminRequestOtp
          : '/${role.toLowerCase()}s/auth/request-otp';

      final response = await DioClient.instance.post(
        path,
        data: {'email': email},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.data?['message'] ?? 'Failed to send OTP.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otpCode, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String path = role.toLowerCase() == 'admin'
          ? ApiConstants.adminVerifyOtp
          : '/${role.toLowerCase()}s/auth/verify-otp';

      final response = await DioClient.instance.post(
        path,
        data: {'email': email, 'otpCode': otpCode},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.data?['message'] ?? 'Invalid OTP code.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String otpCode,
    String newPassword,
    String confirmPassword,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String path = role.toLowerCase() == 'admin'
          ? ApiConstants.adminResetPassword
          : '/${role.toLowerCase()}s/auth/reset-password';

      final response = await DioClient.instance.post(
        path,
        data: {
          'email':           email,
          'otpCode':         otpCode,
          'newPassword':     newPassword,
          'confirmPassword': confirmPassword,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.data?['message'] ?? 'Failed to reset password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Network error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSavedAuth() async {
    final data        = await SecureStorageService.getAllAuthData();
    _token            = data['token'];
    _userId           = data['userId'];
    _userRole         = data['userRole'];
    _userName         = data['userName'];
    _profilePicBase64 = data['profilePic'];
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await SecureStorageService.clearAuthData();
    await prefs.clear();

    DioClient.reset();
    DioClient.setUnauthorizedCallback(() {
      throw UnimplementedError('Unauthorized callback not set after logout');
    });

    _token            = null;
    _userId           = null;
    _userName         = null;
    _userRole         = null;
    _profilePicBase64 = null;
    _isFirstLogin     = false;
    _requires2FA      = false;
    _tempAuthData     = null;

    notifyListeners();
  }
}