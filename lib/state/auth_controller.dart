import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth.dart';
import 'app_providers.dart';

/// Session state: null = logged out. Restored from the secure keystore on
/// cold start so a rider never re-types credentials mid-day (MOB-C-01).
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.read(authRepositoryProvider).tryRestoreSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading<AppUser?>();
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      if (user.role != 'courier') {
        // First courier login: attach the role (FR-AUTH-07), then re-read.
        await ref.read(authRepositoryProvider).onboardCourierRole();
        state = AsyncData<AppUser?>(await ref.read(authRepositoryProvider).profile());
      } else {
        state = AsyncData<AppUser?>(user);
      }
    } on Object catch (e, st) {
      state = AsyncError<AppUser?>(e, st);
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading<AppUser?>();
    try {
      await ref.read(authRepositoryProvider).register(email, password);
      final user = await ref.read(authRepositoryProvider).login(email, password);
      await ref.read(authRepositoryProvider).onboardCourierRole();
      state = AsyncData<AppUser?>(user);
    } on Object catch (e, st) {
      state = AsyncError<AppUser?>(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData<AppUser?>(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
