import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatcher = ref.read(onboardingDispatcherProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const OnboardingProgressDots(currentStep: 1),
                const Spacer(),
                const _HeroZone(),
                const SizedBox(height: 32),
                const _WelcomeText(),
                const Spacer(),
                const _BenefitsRow(),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Get Started',
                  onTap: () => dispatcher.onWelcomeContinued(),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Already have an account? Sign in',
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroZone extends StatefulWidget {
  const _HeroZone();

  @override
  State<_HeroZone> createState() => _HeroZoneState();
}

class _HeroZoneState extends State<_HeroZone> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _entryFade;
  late Animation<double> _entryScale;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _ring1Scale = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeIn),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _entryController.value = 1.0;
        } else {
          _entryController.forward();
          _pulseController.repeat();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: ScaleTransition(
        scale: _entryScale,
        child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Transform.scale(
              scale: _ring1Scale.value,
              child: Opacity(
                opacity: _ring1Opacity.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.4),
                        AppColors.cyan.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Inner pulse ring
            Transform.scale(
              scale: _ring2Scale.value,
              child: Opacity(
                opacity: _ring2Opacity.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        ),
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.purple, AppColors.cyan],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.25),
                blurRadius: 60,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
        ),    // AnimatedBuilder
      ),      // ScaleTransition
    );        // FadeTransition
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.cyanLight],
          ).createShader(bounds),
          child: const Text(
            'Welcome to\nFinQuest AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Learn to make smart financial decisions through '
          'real-world scenarios — guided by your personal AI mentor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _BenefitItem(
            value: '50+',
            label: 'Scenarios',
            icon: Icons.movie_filter_rounded,
            color: AppColors.primary,
          ),
          _Divider(),
          _BenefitItem(
            value: 'AI',
            label: 'Mentor',
            icon: Icons.psychology_rounded,
            color: AppColors.purple,
          ),
          _Divider(),
          _BenefitItem(
            value: '10K+',
            label: 'Learners',
            icon: Icons.people_rounded,
            color: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _BenefitItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}