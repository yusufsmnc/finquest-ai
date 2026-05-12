import '../../../core/events/game_event.dart';
import '../data/dashboard_constants.dart';
import 'dashboard_state.dart';

class DashboardGamificationHandler {
  const DashboardGamificationHandler._();

  static DashboardState apply(DashboardState state, GameEvent event) {
    switch (event.type) {
      case GameEventType.xpGained:
        final amount = (event.payload['amount'] as int)
            .clamp(0, DashboardConstants.xpPerLevel);
        final newXP = state.currentXP + amount;
        final leveledUp = newXP >= state.xpToNextLevel;
        return state.copyWith(
          currentXP: leveledUp ? newXP - state.xpToNextLevel : newXP,
          currentLevel: leveledUp ? state.currentLevel + 1 : state.currentLevel,
          showXpFloat: true,
          lastXpGained: amount,
        );

      case GameEventType.xpLost:
        final amount = (event.payload['amount'] as int).clamp(0, state.currentXP);
        return state.copyWith(
          currentXP: state.currentXP - amount,
        );

      case GameEventType.levelUp:
        final newLevel = event.payload['newLevel'] as int;
        return state.copyWith(currentLevel: newLevel);

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int;
        return state.copyWith(
          currentStreak: streak,
          streakPulse: true,
        );

      case GameEventType.rewardUnlocked:
        final rewardId = event.payload['rewardId'] as String;
        final updated = state.achievements.map((a) {
          return a.id == rewardId ? a.copyWith(unlocked: true) : a;
        }).toList();
        return state.copyWith(achievements: updated);

      case GameEventType.decisionMade:
        return state.copyWith(
          totalScenarios: state.totalScenarios + 1,
        );

      case GameEventType.decisionCorrect:
      case GameEventType.decisionWrong:
        return state;
    }
  }
}