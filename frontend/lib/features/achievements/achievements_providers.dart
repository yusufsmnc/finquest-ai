import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import 'application/achievements_notifier.dart';
import 'domain/achievements_state.dart';

/// Authoritative set of unlocked achievement codes from the backend.
/// Re-fetches whenever the auth session changes (login/logout).
final unlockedAchievementCodesProvider =
    FutureProvider<Set<String>>((ref) async {
  final auth = ref.watch(authProvider).valueOrNull;
  if (!(auth?.isAuthenticated ?? false)) return <String>{};
  final list = await ref.read(progressRepositoryProvider).getAchievements();
  return list.map((a) => a.code).toSet();
});

final achievementsNotifierProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
  AchievementsNotifier.new,
);
