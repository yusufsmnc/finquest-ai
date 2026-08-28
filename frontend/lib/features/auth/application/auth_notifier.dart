import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_reset.dart';
import '../auth_providers.dart';
import '../domain/auth_state.dart';

/// Owns the auth session. On startup it validates any stored token against the
/// backend; explicit login/register/logout drive the rest.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.read();
    if (token == null || token.isEmpty) {
      return const AuthState.unauthenticated();
    }

    // Validate the token by hitting a protected endpoint.
    try {
      await ref.read(progressRepositoryProvider).getProgress();
      return const AuthState.authenticated();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await storage.clear();
        return const AuthState.unauthenticated();
      }
      // Network/other error: keep the token, stay logged in; the progress
      // screen surfaces its own error + retry.
      return const AuthState.authenticated();
    }
  }

  Future<void> login(String email, String password) async {
    // Retain the previous value so the gate keeps showing the login screen
    // (with its inline spinner) instead of flashing the startup splash.
    state = const AsyncValue<AuthState>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(email, password);
      ref.invalidate(progressProvider);
      return AuthState.authenticated(email: email);
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue<AuthState>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(email, password);
      ref.invalidate(progressProvider);
      return AuthState.authenticated(email: email);
    });
  }

  /// Ends the session. Nothing is revoked server-side: the JWT is stateless,
  /// so signing out means dropping the token and everything derived from it.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    resetSessionState(ref);
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// Called by the API client's 401 interceptor (token already cleared there).
  /// Takes the same path as an explicit sign-out, so an expired token cannot
  /// leave one user's XP on screen for the next one.
  Future<void> markUnauthenticated() async {
    resetSessionState(ref);
    state = const AsyncData(AuthState.unauthenticated());
  }
}
