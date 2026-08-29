import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken      = 'auth_token';
  static const _keyUserId     = 'user_id';
  static const _keyUserRole   = 'user_role';
  static const _keyUserName   = 'user_name';
  static const _keyProfilePic = 'profile_pic';
  // Which facility this session belongs to (GRACES | SAINT_ANTHONY), read off
  // the JWT's `facility` claim at login. Drives the house and camera lists so
  // the UI never offers a user something their facility does not own.
  static const _keyFacility   = 'facility';

  static Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userRole,
    required String userName,
    String? profilePic,
    String? facility,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken,    value: token),
      _storage.write(key: _keyUserId,   value: userId),
      _storage.write(key: _keyUserRole, value: userRole),
      _storage.write(key: _keyUserName, value: userName),
      _storage.write(key: _keyProfilePic, value: profilePic ?? ''),
      _storage.write(key: _keyFacility, value: facility ?? ''),
    ]);
  }

  /// Replace ONLY the access token, leaving identity and facility untouched.
  ///
  /// Used when the backend slides a session forward and hands back a renewed
  /// token in a response header. Rewriting the whole auth record here would
  /// risk clobbering fields the renewal knows nothing about.
  static Future<void> updateToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  /// Replace ONLY the stored display name, leaving the token and everything
  /// else untouched.
  ///
  /// Used when the user renames themselves in System Settings. Without this the
  /// name saved to the server and the name this app shows after the next
  /// restart would disagree, because loadSavedAuth() reads from here.
  static Future<void> updateUserName(String userName) =>
      _storage.write(key: _keyUserName, value: userName);

  static Future<String?> getToken()      => _storage.read(key: _keyToken);
  static Future<String?> getUserId()     => _storage.read(key: _keyUserId);
  static Future<String?> getUserRole()   => _storage.read(key: _keyUserRole);
  static Future<String?> getUserName()   => _storage.read(key: _keyUserName);
  static Future<String?> getProfilePic() => _storage.read(key: _keyProfilePic);
  static Future<String?> getFacility()   => _storage.read(key: _keyFacility);

  static Future<Map<String, String?>> getAllAuthData() async {
    final results = await Future.wait([
      _storage.read(key: _keyToken),
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserRole),
      _storage.read(key: _keyUserName),
      _storage.read(key: _keyProfilePic),
      _storage.read(key: _keyFacility),
    ]);
    return {
      'token':      results[0],
      'userId':     results[1],
      'userRole':   results[2],
      'userName':   results[3],
      'profilePic': results[4],
      'facility':   results[5],
    };
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserRole),
      _storage.delete(key: _keyUserName),
      _storage.delete(key: _keyProfilePic),
      _storage.delete(key: _keyFacility),
    ]);
  }
}