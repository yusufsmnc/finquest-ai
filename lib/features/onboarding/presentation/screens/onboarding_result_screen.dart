import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../../data/onboarding_constants.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/mentor_chat_bubble.dart';
import '../../../../shared/widgets/xp_progress_bar.dart';
import '../../../../shared/widgets/xp_float_indicator.dart';
import '../../../../shared/widgets/streak_counter.dart';
import '../../../../core/theme/app_colors.dart';

/// S4 — Result Screen.
/// Shows mentor feedback, XP earned, and streak.
class OnboardingResultScreen extends ConsumerStatefulWidget {
  const OnboardingResultScreen({super.key});

  @override
  ConsumerState<OnboardingResultScreen> createState() =>
      _OnboardingResultScreenState();
}

class _OnboardingResultScreenState
    extends ConsumerState<OnboardingResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _xpFloatShown = false;
  double _xpBarProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startRevealAnimation();
      _startXpFloat();
    });
  }

  void _startRevealAnimation() {
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) {
      _revealController.value = 1;
      setState(() =>
          _xpBarProgress = ref.read(onboardingNotifierProvider).xpProgress);
    } else {
      _revealController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() =>
              _xpBarProgress = ref.read(onboardingNotifierProvider).xpProgress);
        }
      });
    }
  }

  void _startXpFloat() {
    setState(() => _xpFloatShown = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) ref.read(onboardingDispatcherProvider).onXpFloatDismissed();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = ref.watch(
            onboardingNotifierProvider.select((s) => s.isCorrect)) ??
        false;
    final xpEarned = ref
        .watch(onboardingNotifierProvider.select((s) => s.xpEarned));
    final currentStreak = ref
        .watch(onboardingNotifierProvider.select((s) => s.currentStreak));
    final showXpFloat = ref
        .watch(onboardingNotifierProvider.select((s) => s.showXpFloat));
    final streakPulse = ref
        .watch(onboardingNotifierProvider.select((s) => s.streakPulse));
    final dispatcher = ref.read(onboardingDispatcherProvider);

    final mentorMessage = isCorrect
        ? OnboardingConstants.mentorCorrectFeedback
        : OnboardingConstants.mentorWrongFeedback;

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: FadeTransition(
                opacity: _opacity,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const OnboardingProgressDots(currentStep: 4),
                        const SizedBox(height: 32),
                        _ResultHeader(isCorrect: isCorrect),
                        const SizedBox(height: 24),
                        MentorChatBubble(
                          message: mentorMessage,
                          isCorrect: isCorrect,
                        ),
                        const SizedBox(height: 24),
                        _XpEarnedCard(
                          xpEarned: xpEarned,
                          isCorrect: isCorrect,
                          progress: _xpBarProgress,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Daily streak: ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            StreakCounter(
                              streak: currentStreak,
                              pulse: streakPulse,
                            ),
                          ],
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: isCorrect
                              ? 'See Your Reward!'
                              : 'See What You Learned',
                          onTap: () => dispatcher.onResultContinued(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_xpFloatShown)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.38,
              child: Center(
                child: XPFloatIndicator(
                  amount: xpEarned,
                  visible: showXpFloat,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final bool isCorrect;

  const _ResultHeader({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.cyan;
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.info_rounded;
    final headline = isCorrect ? 'Great Choice!' : 'Good Try!';
    final subline = isCorrect
        ? 'You made the smart financial decision.'
        : 'Every decision is a learning opportunity.';

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          headline,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _XpEarnedCard extends StatelessWidget {
  final int xpEarned;
  final bool isCorrect;
  final double progress;

  const _XpEarnedCard({
    required this.xpEarned,
    required this.isCorrect,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP Earned',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.xpGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$xpEarned XP',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xpGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          XPProgressBar(
            progress: progress,
            currentXP: xpEarned,
            maxXP: 100,
          ),
          if (isCorrect) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Bonus: Correct Answer +50 XP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}