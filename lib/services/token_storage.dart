import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'username';
  static const _userIdKey = 'user_id';
  static const _adminName = 'administrator';
  static const _storage = FlutterSecureStorage();

  static Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> read() => _storage.read(key: _tokenKey);

  static Future<void> saveUsername(String username) =>
      _storage.write(key: _userKey, value: username.trim());

  static Future<String?> readUsername() => _storage.read(key: _userKey);

  static Future<void> saveUserId(String id) =>
      _storage.write(key: _userIdKey, value: id);

  static Future<String?> readUserId() => _storage.read(key: _userIdKey);

  static Future<bool> isAdmin() async {
    final user = await readUsername();
    return user != null && user.trim().toLowerCase() == _adminName;
  }

  /// Logout: remove token, username and user id.
  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _userIdKey);
  }
}