import '../../../core/events/game_event.dart';
import '../data/onboarding_constants.dart';
import 'onboarding_state.dart';

/// OnboardingGamificationHandler — pure function layer.
/// Receives a state + incoming game event and returns the new state.
/// No side effects. No UI. No async.
///
/// This is the only place gamification rules are applied to state.
class OnboardingGamificationHandler {
  const OnboardingGamificationHandler._();

  /// Apply a GameEvent to the current state and return the updated state.
  static OnboardingState apply(
    OnboardingState state,
    GameEvent event,
  ) {
    switch (event.type) {
      case GameEventType.decisionMade:
        final optionId = event.payload['optionId'] as String;
        return state.copyWith(
          decisionMade: true,
          selectedOptionId: optionId,
          phase: OnboardingPhase.animating,
        );

      case GameEventType.decisionCorrect:
        return state.copyWith(
          isCorrect: true,
          phase: OnboardingPhase.animating,
        );

      case GameEventType.decisionWrong:
        return state.copyWith(
          isCorrect: false,
          phase: OnboardingPhase.animating,
        );

      case GameEventType.xpGained:
        final raw = event.payload['amount'] as int;
        // Anti-exploit: clamp each individual XP gain to [0, xpMax].
        final amount = raw.clamp(0, OnboardingConstants.xpMax);
        return state.copyWith(
          xpEarned: state.xpEarned + amount,
          showXpFloat: true,
          phase: OnboardingPhase.animating,
        );

      case GameEventType.xpLost:
        // XP_LOST not used in onboarding (no punishing)
        return state;

      case GameEventType.levelUp:
        final newLevel = event.payload['newLevel'] as int;
        // Only update level + phase — step navigation is the dispatcher's responsibility.
        return state.copyWith(
          currentLevel: newLevel,
          phase: OnboardingPhase.navigating,
        );

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int;
        return state.copyWith(
          currentStreak: streak,
          streakPulse: true,
          phase: OnboardingPhase.animating,
        );

      case GameEventType.rewardUnlocked:
        return state.copyWith(
          showRewardToast: true,
          phase: OnboardingPhase.animating,
        );
    }
  }

  /// Determine whether a decision is correct given an optionId.
  static bool isDecisionCorrect(String optionId) {
    return optionId == OnboardingConstants.optionAId;
  }

  /// Returns the XP amount earned for a given correctness.
  static int xpForDecision({required bool isCorrect}) {
    return isCorrect
        ? OnboardingConstants.xpCorrect
        : OnboardingConstants.xpWrong;
  }
}