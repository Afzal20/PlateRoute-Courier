import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_token_store.dart';
import '../models/auth.dart';

/// Auth flows against `/api/auth/` (login, refresh handled by the client,
/// role onboarding, session profile).
class AuthRepository {
  AuthRepository({required this._api, required this._tokens});

  final ApiClient _api;
  final SecureTokenStore _tokens;

  AppUser? _cachedUser;
  AppUser? get cachedUser => _cachedUser;

  Future<AppUser?> tryRestoreSession() async {
    final access = await _tokens.readAccess();
    final refresh = await _tokens.readRefresh();
    if (access == null || refresh == null) return null;
    try {
      return await profile();
    } on ApiException {
      return null;
    }
  }

  Future<AppUser> login(String email, String password) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.post('/api/auth/login/', data: {'email': email, 'password': password}),
    );
    await _tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    _cachedUser =
        AppUser.fromJson((data['user'] as Map).cast<String, Object?>());
    return _cachedUser!;
  }

  /// FR-AUTH-07: attach the courier role to a fresh account.
  Future<void> onboardCourierRole() async {
    await _api.send<void>(
      (dio) => dio.post('/api/auth/role/', data: {'role': 'courier'}),
    );
  }

  Future<AppUser> profile() async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.get('/api/auth/profile/'),
    );
    _cachedUser = AppUser.fromJson(data);
    return _cachedUser!;
  }

  Future<void> register(String email, String password) async {
    await _api.send<void>(
      (dio) => dio.post('/api/auth/register/', data: {'email': email, 'password': password}),
    );
  }

  Future<void> logout() async {
    try {
      await _api.send<void>((dio) => dio.post('/api/auth/logout/'));
    } on ApiException {
      // Backend logout is best-effort; local session death is authoritative.
    }
    await _tokens.clear();
    _cachedUser = null;
  }
}
