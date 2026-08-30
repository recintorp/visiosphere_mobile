import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _userId;
  String? _userName;
  String? _userRole;
  String? _profilePicBase64;
  String? _facility;
  bool _isFirstLogin = false;
  bool _requires2FA = false;
  Map<String, dynamic>? _tempAuthData;

  /// True when the LAST login attempt was turned down by the server, as opposed
  /// to never reaching it.
  ///
  /// login() returns false for a rejected password, a malformed id, a timeout
  /// and a dead network alike, and the sign-in screen's attempt counter must
  /// not treat them the same: locking someone out of a nurses' station for
  /// having poor signal is worse than the guessing it was meant to stop. Only a
  /// response that actually came back from the backend sets this.
  bool _credentialsRejected = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get profilePicBase64 => _profilePicBase64;
  /// 'GRACES' | 'SAINT_ANTHONY' — read off the JWT's `facility` claim at
  /// login. Drives which houses and cameras this user is offered.
  String? get facility => _facility;
  bool get isFirstLogin => _isFirstLogin;
  bool get requires2FA => _requires2FA;
  bool get credentialsRejected => _credentialsRejected;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String loginId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _credentialsRejected = false;
    notifyListeners();

    final checkId = loginId.trim();
    // Role comes from the id PREFIX, and the prefix varies per facility:
    // Grace's uses A-/N-/G-, Saint Anthony uses STA-/STN-/STG-. A hardcoded
    // startsWith('A-') here is what rejected every Saint Anthony account with
    // "Invalid format or credentials provided" before the request was even
    // sent. Facilities.roleOf() reads the same prefix table the backend does.
    final role = Facilities.roleOf(checkId);
    final isNurse = role == 'nurse';
    final isAdmin = role == 'admin';
    final isGuardian = role == 'guardian';
    final isEmail = Facilities.isEmail(checkId);

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
        payload = {'nurseId': checkId, 'password': password};
      } else if (isGuardian) {
        rolePath = 'guardians';
        payload = {'guardianId': checkId, 'password': password};
      }

      Response response = await _makeLoginRequest(rolePath, payload);

      if (isEmail && response.statusCode != 200) {
        rolePath = 'nurses';
        payload = {'nurseId': checkId, 'password': password};
        response = await _makeLoginRequest(rolePath, payload);

        if (response.statusCode != 200) {
          rolePath = 'guardians';
          payload = {'guardianId': checkId, 'password': password};
          response = await _makeLoginRequest(rolePath, payload);
        }
      }

      if (response.statusCode != 200) {
        final msg = response.data?['message'];
        _errorMessage = (msg is String && msg.isNotEmpty)
            ? msg
            : 'Invalid credentials. Please try again.';
        // The backend answered and said no — this one counts against the
        // attempt limit on the sign-in screen.
        _credentialsRejected = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['isFirstLogin'] == true) {
        _isFirstLogin = true;
        _tempAuthData = data;
        _errorMessage =
            'First-time login detected. Please use the Account Setup option.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (data['requires2FA'] == true) {
        _requires2FA = true;
        _tempAuthData = data;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await _saveAuthData(data, rolePath);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data?['message'] ??
          'Account not found or invalid credentials.';
      // A DioException with a response is a rejection; without one it is a
      // timeout or a dead network, which must not cost the user an attempt.
      _credentialsRejected = e.response != null;
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

  /// The name to PRINT for a person the API returned.
  ///
  /// PUBLIC on purpose: the settings screen and the dashboard need exactly the
  /// same answer, and three private copies of this rule is how the web ended up
  /// with four subtly different ones and mobile with none.
  ///
  /// `profileName` is resolved server-side (backend/models/Nurse.js) so that
  /// web and mobile can never drift apart on what someone is called. The
  /// fallbacks below are ordered the same way the server resolves it, purely so
  /// this build still behaves against a backend deployed before profileName
  /// existed — delete them once every environment is on the new backend.
  static String resolveName(Map<dynamic, dynamic> person) {
    final resolved = (person['profileName'] as String?)?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;

    final chosen = (person['displayName'] as String?)?.trim();
    if (chosen != null && chosen.isNotEmpty) return chosen;

    final legal = [person['firstName'], person['lastName']]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (legal.isNotEmpty) return legal;

    return (person['name'] as String?)?.trim() ?? '';
  }

  Future<void> _saveAuthData(Map<String, dynamic> data, String rolePath) async {
    final prefs = await SharedPreferences.getInstance();

    _token = data['token'] as String?;

    if (rolePath == 'admin') {
      final admin = data['admin'] ?? data['user'] ?? {};
      _userId = admin['customId'];
      _userName = admin['name'];
      _userRole = admin['role'] ?? 'Facility Admin';
      _profilePicBase64 = admin['profilePic'];
    } else if (rolePath == 'nurses') {
      final nurse = data['nurse'] ?? data['user'] ?? {};
      _userId = nurse['nurseId'];
      // profileName, NOT firstName + lastName. A nurse who renames herself in
      // System Settings has that name stored in `displayName`, and this line
      // used to throw it away on every sign-in — so the change survived exactly
      // until she signed out. The server resolves the two into profileName; the
      // fallbacks keep this build working against a backend deployed before it.
      _userName = resolveName(nurse);
      _userRole = 'Nurse';
      _profilePicBase64 = nurse['profilePic'];
    } else {
      final guardian = data['guardian'] ?? data['user'] ?? {};
      _userId = guardian['guardianId'];
      _userName = resolveName(guardian);
      _userRole = 'Guardian';
      _profilePicBase64 = guardian['profilePic'];
    }

    if (_token == null ||
        _token!.isEmpty ||
        _userId == null ||
        _userId!.isEmpty) {
      _token = null;
      _userId = null;
      _userName = null;
      _userRole = null;
      _profilePicBase64 = null;
      _facility = null;
      throw Exception('Auth data incomplete — aborting save.');
    }

    // The login RESPONSE body carries no facility; the TOKEN does. Fall back to
    // the id prefix only if the claim is missing — a token minted before
    // facility separation has none, and the backend 401s those anyway.
    _facility = Facilities.facilityFromToken(_token) ?? Facilities.facilityOf(_userId);

    await SecureStorageService.saveAuthData(
      token: _token!,
      userId: _userId!,
      userRole: _userRole ?? '',
      userName: _userName ?? '',
      profilePic: _profilePicBase64,
      facility: _facility,
    );

    await prefs.setString('userRole', _userRole ?? '');
    await prefs.setString('userName', _userName ?? '');
  }

  Future<bool> verify2FA(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool isNurse2FA =
          _tempAuthData?.containsKey('nurse') == true &&
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
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
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

  /// Adopt a new display name after it has been saved in System Settings.
  ///
  /// WHAT THIS FIXES
  ///
  /// The dashboard greeting reads `auth.userName`, which was only ever written
  /// at sign-in. Saving a new Display Name updated AdminSettingsProvider and the
  /// server, but nothing told AuthProvider — so the header kept greeting the old
  /// name until the user signed out and back in. That is the whole of "Display
  /// Name changes are not reflected on the Dashboard profile after saving".
  ///
  /// Writes through to secure storage as well as memory, so the new name also
  /// survives a restart (loadSavedAuth reads from there, not from the server).
  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _userName) return;

    _userName = trimmed;
    await SecureStorageService.updateUserName(trimmed);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', trimmed);

    notifyListeners();
  }

  /// Re-read this signed-in user's OWN profile from the server and adopt the
  /// name it comes back with.
  ///
  /// WHY THIS EXISTS
  ///
  /// Web and mobile already store the name in the same place — the account
  /// record on the server. What they disagreed about was WHEN each side looks.
  /// Mobile read the name once, at sign-in, and never again, so renaming
  /// yourself on the web left this phone greeting the old name until the next
  /// logout. This is the read that closes that gap: call it when the app comes
  /// back to the foreground and a rename made ANYWHERE shows up here without a
  /// re-login. No push channel is needed for this — the server is already the
  /// single source of truth, mobile just had to look again.
  ///
  /// Deliberately SILENT on failure. It runs on resume, on a phone that may
  /// have just come back from a dead spot in the building; a refresh that could
  /// not reach the server must leave the cached name exactly as it was, not
  /// blank the header and not bounce a nurse to the sign-in screen mid-shift.
  ///
  /// Facility scope is untouched: this re-reads the user's OWN record, over the
  /// same token, through the same facility-scoped endpoints every other screen
  /// uses. It cannot see across a facility boundary.
  Future<void> refreshIdentity() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    if (_token == null || _token!.isEmpty) return;

    try {
      final String path;
      if (Facilities.isNurseId(id)) {
        path = '${ApiConstants.nurseBase}/$id';
      } else if (Facilities.isGuardianId(id)) {
        path = '${ApiConstants.guardianBase}/$id';
      } else {
        path = '${ApiConstants.adminBase}/$id';
      }

      final response = await DioClient.instance.get(
        path,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 200) return;

      final body = response.data;
      if (body is! Map) return;

      // Some of these endpoints answer with the record itself and some wrap it.
      // Unwrap the same way AdminSettingsProvider.fetchSettings does, so the two
      // can never disagree about which object holds the name.
      final person = body['nurse'] ?? body['guardian'] ?? body['admin'] ?? body['adminData'] ?? body;
      if (person is! Map) return;

      final name = resolveName(person);
      // An empty answer is a malformed response, not a rename to "". Keeping the
      // old name is strictly better than showing a blank greeting.
      if (name.isEmpty || name == _userName) return;

      _userName = name;
      await SecureStorageService.updateUserName(name);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);

      notifyListeners();
    } catch (_) {
      // Offline, timeout, 401 on a stale token — keep what we already had.
    }
  }

  Future<void> loadSavedAuth() async {
    final data = await SecureStorageService.getAllAuthData();
    _token = data['token'];
    _userId = data['userId'];
    _userRole = data['userRole'];
    _userName = data['userName'];
    _profilePicBase64 = data['profilePic'];
    _facility = (data['facility']?.isNotEmpty ?? false)
        ? data['facility']
        : Facilities.facilityFromToken(_token) ?? Facilities.facilityOf(_userId);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await SecureStorageService.clearAuthData();

    // Clear by name rather than prefs.clear(). A blanket clear also wiped the
    // first-run-tour flag and the remembered sign-in id, so every sign-out sent
    // the user back through onboarding and forgot who they were.
    for (final key in prefs.getKeys().toList()) {
      if (AppPreferences.preserveAcrossLogout.contains(key)) continue;
      await prefs.remove(key);
    }

    DioClient.reset();

    _token = null;
    _userId = null;
    _userName = null;
    _userRole = null;
    _profilePicBase64 = null;
    _facility = null;
    _isFirstLogin = false;
    _requires2FA = false;
    _tempAuthData = null;

    notifyListeners();
  }
}
