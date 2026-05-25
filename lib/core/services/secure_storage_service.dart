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

  static Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userRole,
    required String userName,
    String? profilePic,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken,    value: token),
      _storage.write(key: _keyUserId,   value: userId),
      _storage.write(key: _keyUserRole, value: userRole),
      _storage.write(key: _keyUserName, value: userName),
      _storage.write(key: _keyProfilePic, value: profilePic ?? ''),
    ]);
  }

  static Future<String?> getToken()      => _storage.read(key: _keyToken);
  static Future<String?> getUserId()     => _storage.read(key: _keyUserId);
  static Future<String?> getUserRole()   => _storage.read(key: _keyUserRole);
  static Future<String?> getUserName()   => _storage.read(key: _keyUserName);
  static Future<String?> getProfilePic() => _storage.read(key: _keyProfilePic);

  static Future<Map<String, String?>> getAllAuthData() async {
    final results = await Future.wait([
      _storage.read(key: _keyToken),
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserRole),
      _storage.read(key: _keyUserName),
      _storage.read(key: _keyProfilePic),
    ]);
    return {
      'token':      results[0],
      'userId':     results[1],
      'userRole':   results[2],
      'userName':   results[3],
      'profilePic': results[4],
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
    ]);
  }
}