import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/xp_progress_bar.dart';
import '../../../../shared/widgets/level_indicator.dart';
import '../../../../core/theme/app_colors.dart';

/// S2 — XP Reveal Screen.
/// Introduces the XP & leveling system with an animated reveal.
class OnboardingXpRevealScreen extends ConsumerStatefulWidget {
  const OnboardingXpRevealScreen({super.key});

  @override
  ConsumerState<OnboardingXpRevealScreen> createState() =>
      _OnboardingXpRevealScreenState();
}

class _OnboardingXpRevealScreenState
    extends ConsumerState<OnboardingXpRevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _fadeIn;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0.12).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _revealController.value = 1;
        } else {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _revealController.forward();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const OnboardingProgressDots(currentStep: 2),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.xpGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.xpGold.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.xpGold.withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.xpGold,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Earn XP & Level Up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Every smart financial decision earns you Experience Points. '
                        'Grow your level, unlock new scenarios, and track your progress.',
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
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    return _XpPreviewCard(progress: _progressAnim.value);
                  },
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeIn,
                  child: const _XpEarnPreview(),
                ),
                const Spacer(),
                PrimaryButton(
                  label: "I'm Ready",
                  onTap: () => dispatcher.onXpRevealContinued(),
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

class _XpPreviewCard extends StatelessWidget {
  final double progress;

  const _XpPreviewCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final xp = (progress * 100).round();
    return CardContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LevelIndicator(level: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.xpGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          XPProgressBar(
            progress: progress,
            currentXP: xp,
            maxXP: 100,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Next: Level 2',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpEarnPreview extends StatelessWidget {
  const _XpEarnPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _EarnItem(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            label: 'Correct Decision',
            xp: '+50 XP',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _EarnItem(
            icon: Icons.info_rounded,
            color: AppColors.cyan,
            label: 'Participation',
            xp: '+10 XP',
          ),
        ),
      ],
    );
  }
}

class _EarnItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String xp;

  const _EarnItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            xp,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}