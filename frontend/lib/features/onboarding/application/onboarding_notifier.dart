import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/onboarding_gamification_handler.dart';
import '../domain/onboarding_state.dart';
import '../../../core/events/game_event.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';

/// OnboardingNotifier — the single state owner for onboarding.
///
/// Rules:
/// - State changes ONLY via applyEvent() or explicit lifecycle methods
/// - No direct mutation from UI
/// - Navigation is driven by state change (currentStep)
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  /// Apply a GameEvent through the gamification handler.
  void applyEvent(GameEvent event) {
    state = OnboardingGamificationHandler.apply(state, event);
  }

  /// Advance to the next step. Called by dispatcher — not by UI directly.
  void advanceStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        phase: OnboardingPhase.navigating,
        decisionMade: false,
      );
    }
  }

  /// Reset phase to idle after a screen transition completes.
  void onNavigationComplete() {
    state = state.copyWith(phase: OnboardingPhase.idle);
  }

  /// Mark onboarding complete and persist the flag so it never replays.
  Future<void> completeOnboarding() async {
    state = state.copyWith(
      onboardingComplete: true,
      phase: OnboardingPhase.complete,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompletedKey, true);
  }

  /// Dismiss XP float after animation finishes.
  void dismissXpFloat() {
    state = state.copyWith(showXpFloat: false);
  }

  /// Dismiss reward toast.
  void dismissRewardToast() {
    state = state.copyWith(showRewardToast: false);
  }

  /// Dismiss streak pulse.
  void dismissStreakPulse() {
    state = state.copyWith(streakPulse: false);
  }
}

/// Returns true if onboarding was already completed in a previous session.
Future<bool> loadOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingCompletedKey) ?? false;
}