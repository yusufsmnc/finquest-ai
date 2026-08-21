import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/gamification_overlay_state.dart';

class GamificationOverlayNotifier
    extends Notifier<GamificationOverlayState> {
  @override
  GamificationOverlayState build() => const GamificationOverlayState();

  void applyEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.xpGained:
        final amount = event.payload['amount'] as int;
        final newXp = state.trackedXp + amount;
        final newLevel = GamificationOverlayState.levelForXp(newXp);
        final didLevelUp = newLevel > state.trackedLevel;
        state = state.copyWith(
          trackedXp: newXp,
          trackedLevel: newLevel,
          showLevelUp: didLevelUp ? true : state.showLevelUp,
          levelUpValue: didLevelUp ? newLevel : state.levelUpValue,
        );

      case GameEventType.xpLost:
        final amount = event.payload['amount'] as int;
        if (amount > 0) {
          state = state.copyWith(showXpLost: true, xpLostAmount: amount);
        }

      case GameEventType.levelUp:
        final level = event.payload['newLevel'] as int;
        state = state.copyWith(showLevelUp: true, levelUpValue: level);

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int;
        if (streak > 1) {
          state = state.copyWith(showStreakFeedback: true, streakValue: streak);
        }

      case GameEventType.rewardUnlocked:
        final rewardId = event.payload['rewardId'] as String;
        final toast = _buildToast(rewardId);
        final updated = List<GamificationToastData>.from(state.toastQueue)
          ..add(toast);
        state = state.copyWith(toastQueue: updated);

      case GameEventType.decisionMade:
      case GameEventType.decisionCorrect:
      case GameEventType.decisionWrong:
        break;
    }
  }

  void triggerAchievementUnlock(String name) {
    state = state.copyWith(showAchievementUnlock: true, achievementName: name);
  }

  void dismissLevelUp() => state = state.copyWith(showLevelUp: false);
  void dismissXpLost() => state = state.copyWith(showXpLost: false);
  void dismissStreakFeedback() =>
      state = state.copyWith(showStreakFeedback: false);
  void dismissAchievementUnlock() =>
      state = state.copyWith(showAchievementUnlock: false);

  void advanceToastQueue() {
    if (state.toastQueue.isEmpty) return;
    state = state.copyWith(toastQueue: state.toastQueue.sublist(1));
  }

  GamificationToastData _buildToast(String rewardId) {
    return GamificationToastData(
      id: rewardId,
      title: 'Reward Unlocked!',
      message: _labelForReward(rewardId),
      icon: Icons.card_giftcard_rounded,
      color: AppColors.xpGold,
    );
  }

  String _labelForReward(String rewardId) {
    switch (rewardId) {
      case 'streak_reward':
        return '3 correct decisions streak!';
      default:
        return 'Keep up the great work!';
    }
  }
}