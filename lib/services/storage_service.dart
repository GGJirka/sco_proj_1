import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> init();
  Future<void> saveIdToken(String token);
  Future<String?> readIdToken();
  Future<void> saveLastLoginEmail(String email);
  Future<String?> readLastLoginEmail();
  Future<void> saveLocalSecret(String secret);
  Future<String?> readLocalSecret();
}

class InsecureStorageService implements StorageService {
  static const _idTokenKey = 'idToken';
  static const _emailKey = 'lastEmail';
  static const _localSecretKey = 'localSecret';

  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('SharedPreferences not initialized');
    }
    return _prefs!;
  }

  @override
  Future<void> saveIdToken(String token) async {
    // Intentionally insecure: tokens are stored in plain text for demo purposes.
    await _preferences.setString(_idTokenKey, token);
  }

  @override
  Future<String?> readIdToken() async => _preferences.getString(_idTokenKey);

  @override
  Future<void> saveLastLoginEmail(String email) async {
    await _preferences.setString(_emailKey, email);
  }

  @override
  Future<String?> readLastLoginEmail() async => _preferences.getString(_emailKey);

  @override
  Future<void> saveLocalSecret(String secret) async {
    await _preferences.setString(_localSecretKey, secret);
  }

  @override
  Future<String?> readLocalSecret() async => _preferences.getString(_localSecretKey);
}

class SecureStorageService implements StorageService {
  static const _idTokenKey = 'secureIdToken';
  static const _emailKey = 'secureLastEmail';
  static const _localSecretKey = 'secureLocalSecret';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> init() async {
    // FlutterSecureStorage uses the Android Keystore automatically.
  }

  @override
  Future<void> saveIdToken(String token) async {
    await _storage.write(key: _idTokenKey, value: token);
  }

  @override
  Future<String?> readIdToken() async => _storage.read(key: _idTokenKey);

  @override
  Future<void> saveLastLoginEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  @override
  Future<String?> readLastLoginEmail() async => _storage.read(key: _emailKey);

  @override
  Future<void> saveLocalSecret(String secret) async {
    await _storage.write(key: _localSecretKey, value: secret);
  }

  @override
  Future<String?> readLocalSecret() async => _storage.read(key: _localSecretKey);
}
