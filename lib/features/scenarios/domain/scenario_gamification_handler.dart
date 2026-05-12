import '../../../core/events/game_event.dart';
import 'scenario_state.dart';

class ScenarioGamificationHandler {
  const ScenarioGamificationHandler._();

  static ScenarioState apply(ScenarioState state, GameEvent event) {
    switch (event.type) {
      case GameEventType.decisionMade:
        return state.copyWith(
          selectedOptionId: event.payload['optionId'] as String,
          totalDecisions: state.totalDecisions + 1,
        );

      case GameEventType.decisionCorrect:
        return state.copyWith(
          isCorrect: true,
          correctCount: state.correctCount + 1,
        );

      case GameEventType.decisionWrong:
        return state.copyWith(isCorrect: false);

      case GameEventType.xpGained:
        final amount = (event.payload['amount'] as int).clamp(0, 200);
        return state.copyWith(
          xpEarned: state.xpEarned + amount,
          lastXpGained: amount,
          showXpFloat: true,
        );

      case GameEventType.xpLost:
        final amount = (event.payload['amount'] as int).clamp(0, state.xpEarned);
        return state.copyWith(xpEarned: state.xpEarned - amount);

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int;
        return state.copyWith(
          currentStreak: streak,
          streakPulse: true,
        );

      case GameEventType.rewardUnlocked:
        return state.copyWith(showRewardToast: true);

      case GameEventType.levelUp:
        return state;
    }
  }
}