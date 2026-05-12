import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/onboarding_notifier.dart';
import 'application/onboarding_event_dispatcher.dart';
import 'domain/onboarding_state.dart';

/// onboardingNotifierProvider — owns the OnboardingState.
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

/// onboardingDispatcherProvider — the event intake point for the UI.
final onboardingDispatcherProvider = Provider<OnboardingEventDispatcher>((ref) {
  final notifier = ref.read(onboardingNotifierProvider.notifier);
  return OnboardingEventDispatcher(notifier);
});