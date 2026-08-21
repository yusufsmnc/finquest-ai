import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../../../data/dtos/progress_dto.dart';
import '../../auth/auth_providers.dart';
import '../achievements_providers.dart';
import '../data/achievements_repository.dart';
import '../domain/achievement_model.dart';
import '../domain/achievements_state.dart';

/// Achievements are backend-owned. This notifier only *renders* them:
/// - unlocked state comes from [unlockedAchievementCodesProvider] (the backend)
///   plus any codes unlocked during the current session ([addUnlockedCodes]);
/// - progress bars for still-locked achievements are derived from the
///   authoritative [progressProvider] metrics (xp/level/streak/decisions).
///
/// There is NO unlock computation here — the backend decides unlocks.
class AchievementsNotifier extends Notifier<AchievementsState> {
  AchievementCategory? _filter;
  final Set<String> _sessionUnlocked = {};

  // Cached build inputs so mutation methods can recompose WITHOUT calling
  // ref.read (which throws if a watched dependency changed pre-rebuild).
  Set<String> _remoteUnlocked = const {};
  ProgressDto _progress = ProgressDto.empty;

  @override
  AchievementsState build() {
    final authed =
        ref.watch(authProvider).valueOrNull?.isAuthenticated ?? false;
    if (!authed) {
      // Session boundary: never leak one user's unlocks into another's.
      _sessionUnlocked.clear();
    }
    _remoteUnlocked =
        ref.watch(unlockedAchievementCodesProvider).valueOrNull ??
            const <String>{};
    _progress = ref.watch(progressProvider).valueOrNull ?? ProgressDto.empty;
    return _compose();
  }

  AchievementsState _compose() {
    final unlocked = {..._remoteUnlocked, ..._sessionUnlocked};
    final list = AchievementsRepository.all().map((a) {
      final isUnlocked = unlocked.contains(a.id);
      final metric = _metricFor(a.category, _progress);
      return a.copyWith(
        unlocked: isUnlocked,
        currentProgress:
            isUnlocked ? a.requiredValue : metric.clamp(0, a.requiredValue),
      );
    }).toList();
    return AchievementsState(achievements: list, filterCategory: _filter);
  }

  static int _metricFor(AchievementCategory category, ProgressDto p) {
    switch (category) {
      case AchievementCategory.streak:
        return p.streakCount;
      case AchievementCategory.xp:
        return p.xp;
      case AchievementCategory.level:
        return p.level;
      case AchievementCategory.decisions:
        return p.decisionsMade;
    }
  }

  /// Record codes the backend just unlocked (from a decision response) so the
  /// UI reflects them immediately, before the next full re-fetch.
  void addUnlockedCodes(Iterable<String> codes) {
    final before = _sessionUnlocked.length;
    _sessionUnlocked.addAll(codes);
    if (_sessionUnlocked.length != before) {
      state = _compose();
    }
  }

  void setFilter(AchievementCategory? category) {
    _filter = category;
    state = _compose();
  }

  /// Kept for event-dispatcher compatibility. Achievements are derived from the
  /// backend, so gamification events no longer mutate unlock state here.
  void applyEvent(GameEvent event) {}

  void clearLastUnlocked() {}

  AchievementsState get currentState => state;
}
