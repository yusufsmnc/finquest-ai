import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';

/// OnboardingStepGate — wraps a screen and only renders it
/// when currentStep matches the expected step.
/// Prevents stale renders during navigation transitions.
class OnboardingStepGate extends ConsumerWidget {
  final int step;
  final Widget child;

  const OnboardingStepGate({
    super.key,
    required this.step,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep =
        ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));
    if (currentStep != step) return const SizedBox.shrink();
    return child;
  }
}