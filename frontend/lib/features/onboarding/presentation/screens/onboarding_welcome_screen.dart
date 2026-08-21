import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../shared/widgets/animated_button.dart';
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
                const SizedBox(height: 20),
                const OnboardingProgressDots(currentStep: 1),
                const Expanded(child: Center(child: _HeroZone())),
                const _FeatureCards(),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Get Started',
                  onTap: () => dispatcher.onWelcomeContinued(),
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Zone ──────────────────────────────────────────────────────────────────

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
            // Glow halo
            Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    AppColors.cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Lottie orb
            RepaintBoundary(
              child: SizedBox(
                width: 380,
                height: 380,
                child: Lottie.asset(
                  'assets/animations/orb_anim.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Text overlay
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
      ),
    );
  }
}

// ── Feature Cards ──────────────────────────────────────────────────────────────

class _FeatureDef {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _FeatureDef(this.icon, this.title, this.description, this.color);
}

const _kFeatures = [
  _FeatureDef(
    Icons.psychology_alt_rounded,
    'Real-World Scenarios',
    'Practice financial decisions in simulated real situations',
    AppColors.primary,
  ),
  _FeatureDef(
    Icons.auto_awesome_rounded,
    'AI Mentor',
    'Get personalized guidance and feedback on every choice',
    AppColors.purple,
  ),
  _FeatureDef(
    Icons.emoji_events_rounded,
    'Earn & Level Up',
    'Unlock achievements and track your financial progress',
    AppColors.xpGold,
  ),
];

class _FeatureCards extends StatefulWidget {
  const _FeatureCards();

  @override
  State<_FeatureCards> createState() => _FeatureCardsState();
}

class _FeatureCardsState extends State<_FeatureCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anims = List.generate(_kFeatures.length, (i) {
      final delay = i * 0.18;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          delay,
          delay + 0.5,
          curve: Curves.easeOutCubic,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _ctrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_kFeatures.length, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (context, child) => Opacity(
            opacity: _anims[i].value,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - _anims[i].value)),
              child: child,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: i < _kFeatures.length - 1 ? 10 : 0,
            ),
            child: _FeatureCard(feature: _kFeatures[i]),
          ),
        );
      }),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureDef feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: feature.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: feature.color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feature.color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
