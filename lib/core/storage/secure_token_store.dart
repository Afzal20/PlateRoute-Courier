import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT token storage (MOB-C-01): access + refresh live ONLY in the OS
/// keystore — never in prefs, JSON files, or memory dumps of app state.
class SecureTokenStore {
  SecureTokenStore();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'plateroute.access';
  static const _refreshKey = 'plateroute.refresh';

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> save({required String access, required String refresh}) =>
      Future.wait([
        _storage.write(key: _accessKey, value: access),
        _storage.write(key: _refreshKey, value: refresh),
      ]).then((_) {});

  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<void> clear() => Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]).then((_) {});
}
