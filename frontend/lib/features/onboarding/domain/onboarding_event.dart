/// OnboardingEvent — all UI-layer events for the onboarding flow.
/// These map directly to user actions. The event dispatcher
/// translates them into GameEvents (global contract).
sealed class OnboardingEvent {
  const OnboardingEvent();
}

/// User tapped "Get Started" on the welcome screen (S1).
class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

/// User tapped "Continue" after seeing the XP reveal screen (S2).
class OnboardingXpRevealContinued extends OnboardingEvent {
  const OnboardingXpRevealContinued();
}

/// User selected a decision option on the scenario screen (S3).
class OnboardingDecisionSelected extends OnboardingEvent {
  final String optionId;
  const OnboardingDecisionSelected({required this.optionId});
}

/// User tapped "Continue" on the result screen (S4).
class OnboardingResultContinued extends OnboardingEvent {
  const OnboardingResultContinued();
}

/// User tapped "Go to Dashboard" on the level-up screen (S5).
class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}