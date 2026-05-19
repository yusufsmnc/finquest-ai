import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      ),         // Scaffold
    );           // PopScope
  }
}

class _HeroZone extends StatefulWidget {
  const _HeroZone();

  @override
  State<_HeroZone> createState() => _HeroZoneState();
}

class _HeroZoneState extends State<_HeroZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<double> _entryScale;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entryController.value = 1.0;
      } else {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _entryController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: ScaleTransition(
        scale: _entryScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow halo behind the orb
            Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.24),
                    AppColors.cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Lottie orb
            RepaintBoundary(
              child: SizedBox(
                width: 370,
                height: 370,
                child: Lottie.asset(
                  'assets/animations/orb_anim.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Text overlaid on orb center
            SizedBox(
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.cyanLight],
                    ).createShader(bounds),
                    child: const Text(
                      'Welcome to\nFinQuest AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Learn smart financial decisions through real-world scenarios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),      // ScaleTransition
    );        // FadeTransition
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
