import '../data/onboarding_constants.dart';

/// OnboardingPhase — the current activity phase of the onboarding flow.
enum OnboardingPhase {
  idle,
  animating,
  navigating,
  complete,
}

/// OnboardingState — immutable state for the onboarding feature.
/// All UI derives from this; no mutable fields exist.
class OnboardingState {
  final int currentStep; // 1–5
  final OnboardingPhase phase;
  final bool decisionMade;
  final String? selectedOptionId; // "A" | "B" | null
  final bool? isCorrect;
  final int xpEarned;
  final int currentLevel; // Updated by LEVEL_UP event
  final int currentStreak; // Updated by STREAK_UPDATED event
  final bool onboardingComplete;
  final bool showXpFloat;
  final bool showRewardToast;
  final bool streakPulse;

  const OnboardingState({
    this.currentStep = 1,
    this.phase = OnboardingPhase.idle,
    this.decisionMade = false,
    this.selectedOptionId,
    this.isCorrect,
    this.xpEarned = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.onboardingComplete = false,
    this.showXpFloat = false,
    this.showRewardToast = false,
    this.streakPulse = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    OnboardingPhase? phase,
    bool? decisionMade,
    String? selectedOptionId,
    bool? isCorrect,
    int? xpEarned,
    int? currentLevel,
    int? currentStreak,
    bool? onboardingComplete,
    bool? showXpFloat,
    bool? showRewardToast,
    bool? streakPulse,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      phase: phase ?? this.phase,
      decisionMade: decisionMade ?? this.decisionMade,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isCorrect: isCorrect ?? this.isCorrect,
      xpEarned: xpEarned ?? this.xpEarned,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      showXpFloat: showXpFloat ?? this.showXpFloat,
      showRewardToast: showRewardToast ?? this.showRewardToast,
      streakPulse: streakPulse ?? this.streakPulse,
    );
  }

  /// Returns true if the current step can advance.
  bool get canAdvance =>
      phase == OnboardingPhase.idle || phase == OnboardingPhase.complete;

  /// XP progress as a fraction (0.0–1.0) for XPProgressBar.
  /// Uses OnboardingConstants.xpForLevelUp as the denominator (100 XP = level 1).
  double get xpProgress {
    return (xpEarned / OnboardingConstants.xpForLevelUp).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'OnboardingState(step: $currentStep, phase: $phase, '
        'decision: $selectedOptionId, correct: $isCorrect, xp: $xpEarned, '
        'level: $currentLevel, streak: $currentStreak)';
  }
}