import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/auth/token_storage.dart';
import '../../data/dtos/progress_dto.dart';
import '../../data/repositories/mentor_api_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/scenario_api_repository.dart';
import 'application/auth_notifier.dart';
import 'application/progress_notifier.dart';
import 'domain/auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// The single Dio-backed client. Its 401 interceptor flips auth to
/// unauthenticated — the closure reads [authProvider] lazily (only when a 401
/// actually fires), so there is no provider init cycle.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.read(tokenStorageProvider),
    onUnauthorized: () => ref.read(authProvider.notifier).markUnauthenticated(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.read(apiClientProvider));
});

final scenarioApiRepositoryProvider = Provider<ScenarioApiRepository>((ref) {
  return ScenarioApiRepository(ref.read(apiClientProvider));
});

final mentorApiRepositoryProvider = Provider<MentorApiRepository>((ref) {
  return MentorApiRepository(ref.read(apiClientProvider));
});

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, ProgressDto>(ProgressNotifier.new);