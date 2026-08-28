import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_providers.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/onboarding_xp_reveal_screen.dart';
import 'screens/onboarding_decision_screen.dart';
import 'screens/onboarding_result_screen.dart';
import 'screens/onboarding_level_up_screen.dart';
import '../../../shared/widgets/aurora_background.dart';

class OnboardingNavigator extends ConsumerWidget {
  const OnboardingNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep =
        ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));

    return Stack(
      children: [
        const Positioned.fill(child: AuroraBackground()),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            final reducedMotion = MediaQuery.of(context).disableAnimations;
            if (reducedMotion) return child;

            final isEntering = animation.status == AnimationStatus.forward ||
                animation.status == AnimationStatus.completed;

            final slideOffset = isEntering
                ? Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic),
                  )
                : Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic),
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
        ),
      ],
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
