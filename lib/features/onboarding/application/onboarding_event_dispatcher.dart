import '../../../core/events/game_event.dart';
import '../data/onboarding_constants.dart';
import '../domain/onboarding_gamification_handler.dart';
import 'onboarding_notifier.dart';

class OnboardingEventDispatcher {
  final OnboardingNotifier _notifier;

  const OnboardingEventDispatcher(this._notifier);

  void dispatch(GameEvent event) {
    _notifier.applyEvent(event);
  }

  void onWelcomeContinued() {
    dispatch(GameEvent.decisionMade(optionId: 'welcome_continue'));
    _notifier.advanceStep();
  }

  void onXpRevealContinued() {
    dispatch(GameEvent.decisionMade(optionId: 'xp_reveal_continue'));
    _notifier.advanceStep();
  }

  void onDecisionMade(String optionId) {
    final isCorrect = OnboardingGamificationHandler.isDecisionCorrect(optionId);
    final xpAmount = OnboardingGamificationHandler.xpForDecision(isCorrect: isCorrect);

    dispatch(GameEvent.decisionMade(optionId: optionId));

    if (isCorrect) {
      dispatch(GameEvent.decisionCorrect(optionId: optionId));
    } else {
      dispatch(GameEvent.decisionWrong(optionId: optionId));
    }

    dispatch(GameEvent.xpGained(amount: xpAmount));
    dispatch(GameEvent.streakUpdated(streak: 1));
    // Step advance makes S3→S4 navigation state-driven — screens never call advanceStep directly.
    _notifier.advanceStep();
  }

  // LEVEL_UP always fires at S4→S5 regardless of decision — tutorial guarantee.
  void onResultContinued() {
    dispatch(GameEvent.levelUp(newLevel: OnboardingConstants.levelAfterOnboarding));
    dispatch(GameEvent.rewardUnlocked(rewardId: OnboardingConstants.rewardId));
    _notifier.advanceStep();
  }

  void onXpFloatDismissed() => _notifier.dismissXpFloat();
  void onRewardToastDismissed() => _notifier.dismissRewardToast();
  void onStreakPulseDismissed() => _notifier.dismissStreakPulse();
}