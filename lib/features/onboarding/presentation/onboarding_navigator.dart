import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_providers.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/onboarding_xp_reveal_screen.dart';
import 'screens/onboarding_decision_screen.dart';
import 'screens/onboarding_result_screen.dart';
import 'screens/onboarding_level_up_screen.dart';

/// OnboardingNavigator — the top-level widget for the onboarding flow.
///
/// It watches ONLY currentStep from state and switches the visible screen.
/// Navigation is ENTIRELY state-driven — no imperative Navigator.push calls
/// from any screen (except the final "Go to Dashboard").
///
/// Screen transitions use FadeTransition + SlideTransition (easeOutCubic, 320ms).
class OnboardingNavigator extends ConsumerWidget {
  const OnboardingNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep =
        ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      // Spec:
      //   Enter: FadeIn + SlideDown (offset 0,0.1 → 0,0) 320ms easeOutCubic
      //   Exit:  FadeOut + SlideUp  (offset 0,0  → 0,-0.1) 320ms easeOutCubic
      // AnimatedSwitcher passes animation=0→1 for entering child and
      // animation=1→0 for exiting child (via layoutBuilder key-based routing).
      transitionBuilder: (child, animation) {
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        if (reducedMotion) return child;

        // Determine whether this child is entering (animation goes 0→1) or
        // exiting (animation goes 1→0) by checking the animation's status.
        // We use a conditional tween: entering slides from below, exiting slides up.
        final isEntering = animation.status == AnimationStatus.forward ||
            animation.status == AnimationStatus.completed;

        final slideOffset = isEntering
            ? Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              )
            : Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideOffset,
            child: child,
          ),
        );
      },
      child: _buildScreen(currentStep),
    );
  }

  Widget _buildScreen(int step) {
    switch (step) {
      case 1:
        return const OnboardingWelcomeScreen(
          key: ValueKey('onboarding_s1'),
        );
      case 2:
        return const OnboardingXpRevealScreen(
          key: ValueKey('onboarding_s2'),
        );
      case 3:
        return const OnboardingDecisionScreen(
          key: ValueKey('onboarding_s3'),
        );
      case 4:
        return const OnboardingResultScreen(
          key: ValueKey('onboarding_s4'),
        );
      case 5:
        return const OnboardingLevelUpScreen(
          key: ValueKey('onboarding_s5'),
        );
      default:
        return const OnboardingWelcomeScreen(
          key: ValueKey('onboarding_s1_default'),
        );
    }
  }
}