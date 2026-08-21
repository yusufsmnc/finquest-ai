import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../data/achievements_repository.dart';
import '../domain/achievement_model.dart';
import '../domain/achievements_state.dart';

class AchievementsNotifier extends Notifier<AchievementsState> {
  @override
  AchievementsState build() {
    return AchievementsState(achievements: AchievementsRepository.all());
  }

  void applyEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.xpGained:
        final amount = event.payload['amount'] as int? ?? 0;
        final newXp = state.trackedXp + amount;
        final derivedLevel = (newXp ~/ 200) + 1;
        final didLevelUp = derivedLevel > state.trackedLevel;
        state = state.copyWith(
          trackedXp: newXp,
          trackedLevel: didLevelUp ? derivedLevel : null,
        );
        _updateXpProgress(newXp);
        _checkXpAchievements(newXp);
        if (didLevelUp) _checkLevelAchievements(derivedLevel);

      case GameEventType.levelUp:
        final level = event.payload['newLevel'] as int? ?? state.trackedLevel;
        if (level > state.trackedLevel) {
          state = state.copyWith(trackedLevel: level);
          _checkLevelAchievements(level);
        }

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int? ?? 0;
        if (streak > state.trackedStreak) {
          state = state.copyWith(trackedStreak: streak);
          _updateStreakProgress(streak);
          _checkStreakAchievements(streak);
        } else if (streak == 0) {
          state = state.copyWith(trackedStreak: 0);
        }

      case GameEventType.decisionCorrect:
        final newCount = state.trackedCorrectDecisions + 1;
        state = state.copyWith(trackedCorrectDecisions: newCount);
        _updateDecisionProgress(newCount);
        _checkDecisionAchievements(newCount);

      case GameEventType.decisionMade:
      case GameEventType.decisionWrong:
      case GameEventType.xpLost:
      case GameEventType.rewardUnlocked:
        break;
    }
  }

  void setFilter(AchievementCategory? category) {
    if (category == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  void clearLastUnlocked() {
    state = state.copyWith(clearLastUnlocked: true);
  }

  AchievementsState get currentState => state;

  void _checkStreakAchievements(int streak) {
    final ids = <String>[];
    if (streak >= 1) ids.add('streak_first');
    if (streak >= 3) ids.add('streak_3');
    if (streak >= 5) ids.add('streak_5');
    if (streak >= 10) ids.add('streak_10');
    _unlockAll(ids);
  }

  void _checkXpAchievements(int xp) {
    final ids = <String>[];
    if (xp >= 100) ids.add('xp_100');
    if (xp >= 500) ids.add('xp_500');
    if (xp >= 1000) ids.add('xp_1000');
    if (xp >= 2000) ids.add('xp_2000');
    _unlockAll(ids);
  }

  void _checkDecisionAchievements(int count) {
    final ids = <String>[];
    if (count >= 5) ids.add('decisions_5');
    if (count >= 25) ids.add('decisions_25');
    if (count >= 100) ids.add('decisions_100');
    _unlockAll(ids);
  }

  void _checkLevelAchievements(int level) {
    final ids = <String>[];
    if (level >= 2) ids.add('level_2');
    if (level >= 5) ids.add('level_5');
    if (level >= 10) ids.add('level_10');
    _unlockAll(ids);
  }

  // Progress updates for locked achievements so progress bars animate
  void _updateXpProgress(int xp) {
    _setProgress(
      ['xp_100', 'xp_500', 'xp_1000', 'xp_2000'],
      xp,
    );
  }

  void _updateStreakProgress(int streak) {
    _setProgress(
      ['streak_first', 'streak_3', 'streak_5', 'streak_10'],
      streak,
    );
  }

  void _updateDecisionProgress(int count) {
    _setProgress(
      ['decisions_5', 'decisions_25', 'decisions_100'],
      count,
    );
  }

  void _setProgress(List<String> ids, int value) {
    var updated = state.achievements.toList();
    bool changed = false;
    for (final id in ids) {
      final idx = updated.indexWhere((a) => a.id == id);
      if (idx == -1) continue;
      final a = updated[idx];
      if (a.unlocked) continue;
      final clamped = value.clamp(0, a.requiredValue);
      if (clamped != a.currentProgress) {
        updated[idx] = a.copyWith(currentProgress: clamped);
        changed = true;
      }
    }
    if (changed) state = state.copyWith(achievements: updated);
  }

  void _unlockAll(List<String> ids) {
    Achievement? lastNewUnlock;
    var updated = state.achievements.toList();

    for (final id in ids) {
      final idx = updated.indexWhere((a) => a.id == id);
      if (idx == -1) continue;
      final achievement = updated[idx];
      if (achievement.unlocked) continue;
      updated[idx] = achievement.copyWith(
        unlocked: true,
        currentProgress: achievement.requiredValue,
        unlockedAt: DateTime.now(),
      );
      lastNewUnlock = updated[idx];
    }

    if (lastNewUnlock != null) {
      state = state.copyWith(achievements: updated, lastUnlocked: lastNewUnlock);
    } else {
      state = state.copyWith(achievements: updated);
    }
  }
}