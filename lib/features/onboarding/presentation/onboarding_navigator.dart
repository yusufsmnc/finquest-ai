import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/onboarding_xp_reveal_screen.dart';
import 'screens/onboarding_decision_screen.dart';
import 'screens/onboarding_result_screen.dart';
import 'screens/onboarding_level_up_screen.dart';

class OnboardingNavigator extends ConsumerStatefulWidget {
  const OnboardingNavigator({super.key});

  @override
  ConsumerState<OnboardingNavigator> createState() =>
      _OnboardingNavigatorState();
}

class _OnboardingNavigatorState extends ConsumerState<OnboardingNavigator>
    with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;

  late Animation<double> _b1Top;
  late Animation<double> _b1Left;
  late Animation<double> _b1Opacity;

  late Animation<double> _b2Bottom;
  late Animation<double> _b2Left;
  late Animation<double> _b2Opacity;

  late Animation<double> _b3Top;
  late Animation<double> _b3Right;
  late Animation<double> _b3Opacity;

  @override
  void initState() {
    super.initState();

    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: true);

    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 17),
    )..repeat(reverse: true);

    final c1 = CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut);
    final c2 = CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut);
    final c3 = CurvedAnimation(parent: _blob3Controller, curve: Curves.easeInOut);

    // Blob 1 — violet, top-center drifts right
    _b1Top     = Tween<double>(begin: -120, end: -80).animate(c1);
    _b1Left    = Tween<double>(begin: -60,  end:  40).animate(c1);
    _b1Opacity = Tween<double>(begin: 0.10, end: 0.20).animate(c1);

    // Blob 2 — cyan, bottom-left drifts up
    _b2Bottom  = Tween<double>(begin: -80,  end: -40).animate(c2);
    _b2Left    = Tween<double>(begin: -60,  end:  20).animate(c2);
    _b2Opacity = Tween<double>(begin: 0.08, end: 0.16).animate(c2);

    // Blob 3 — indigo, center-right drifts left
    _b3Top     = Tween<double>(begin: 80,   end: 140).animate(c3);
    _b3Right   = Tween<double>(begin: -80,  end: -20).animate(c3);
    _b3Opacity = Tween<double>(begin: 0.07, end: 0.14).animate(c3);
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep =
        ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));

    return Stack(
      children: [
        // Aurora background — persists across all steps
        Positioned.fill(
          child: ColoredBox(color: AppColors.background),
        ),
        AnimatedBuilder(
          animation: Listenable.merge(
              [_blob1Controller, _blob2Controller, _blob3Controller]),
          builder: (context, _) => Stack(
            children: [
              // Blob 1 — violet
              Positioned(
                top: _b1Top.value,
                left: _b1Left.value,
                child: _AuroraBlob(
                  size: 420,
                  color: AppColors.primary,
                  opacity: _b1Opacity.value,
                ),
              ),
              // Blob 2 — cyan
              Positioned(
                bottom: _b2Bottom.value,
                left: _b2Left.value,
                child: _AuroraBlob(
                  size: 360,
                  color: AppColors.cyan,
                  opacity: _b2Opacity.value,
                ),
              ),
              // Blob 3 — indigo
              Positioned(
                top: _b3Top.value,
                right: _b3Right.value,
                child: _AuroraBlob(
                  size: 300,
                  color: AppColors.indigoDark,
                  opacity: _b3Opacity.value,
                ),
              ),
            ],
          ),
        ),
        // Screen content
        AnimatedSwitcher(
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

class _AuroraBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _AuroraBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}