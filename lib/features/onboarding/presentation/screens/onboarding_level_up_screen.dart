import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../../data/onboarding_constants.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/achievement_badge.dart';
import '../../../../shared/widgets/xp_progress_bar.dart';
import '../../../../shared/widgets/reward_toast.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/app_colors.dart';

/// S5 — Level Up Screen.
/// Full celebration: confetti, glow, badge reveal, reward toast.
class OnboardingLevelUpScreen extends ConsumerStatefulWidget {
  const OnboardingLevelUpScreen({super.key});

  @override
  ConsumerState<OnboardingLevelUpScreen> createState() =>
      _OnboardingLevelUpScreenState();
}

class _OnboardingLevelUpScreenState
    extends ConsumerState<OnboardingLevelUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _glowScaleInController;
  late AnimationController _glowPulseController;
  late AnimationController _contentController;
  late AnimationController _titleController;
  late Animation<double> _glowScaleIn;
  late Animation<double> _glowPulse;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _titleFade;
  late Animation<double> _titleScale;

  double _xpBarProgress = 0.0;
  int _glowPulseCycles = 0;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _glowScaleInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowScaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _glowScaleInController, curve: Curves.easeOutCubic),
    );

    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.06), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.06, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );
    _glowPulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowPulseCycles++;
        if (_glowPulseCycles < 4 && mounted) {
          _glowPulseController.forward(from: 0);
        }
      }
    });

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MediaQuery.of(context).disableAnimations;
      if (reduced) {
        _confettiController.value = 1;
        _glowScaleInController.value = 1;
        _titleController.value = 1;
        _contentController.value = 1;
        setState(() => _xpBarProgress = _actualXpProgress());
        return;
      }

      _confettiController.forward();
      _contentController.forward();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _titleController.forward();
      });

      _glowScaleInController.forward().whenComplete(() {
        if (mounted) _glowPulseController.forward();
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _xpBarProgress = 1.0);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => _xpBarProgress = _actualXpProgress());
        });
      });
    });
  }

  double _actualXpProgress() {
    final state = ref.read(onboardingNotifierProvider);
    return state.xpProgress;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowScaleInController.dispose();
    _glowPulseController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onDashboardTap() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpEarned =
        ref.watch(onboardingNotifierProvider.select((s) => s.xpEarned));
    final showRewardToast =
        ref.watch(onboardingNotifierProvider.select((s) => s.showRewardToast));
    final dispatcher = ref.read(onboardingDispatcherProvider);

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const OnboardingProgressDots(currentStep: 5),
                        const SizedBox(height: 32),
                        _GlowBadgeSection(
                          glowScaleIn: _glowScaleIn,
                          glowPulse: _glowPulse,
                        ),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _titleController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _titleFade.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _titleScale.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                'Level ${OnboardingConstants.levelAfterOnboarding} Reached!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You\'ve completed the tutorial. Your financial\njourney is just beginning!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _XpLevelCard(
                          xpProgress: _xpBarProgress,
                          xpEarned: xpEarned,
                        ),
                        const SizedBox(height: 20),
                        const _UnlockedRewardsSection(),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Go to Dashboard',
                          onTap: _onDashboardTap,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _ConfettiOverlay(controller: _confettiController),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: RewardToast(
              rewardId: OnboardingConstants.rewardId,
              label: OnboardingConstants.rewardLabel,
              visible: showRewardToast,
              onDismiss: () => dispatcher.onRewardToastDismissed(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBadgeSection extends StatelessWidget {
  final Animation<double> glowScaleIn;
  final Animation<double> glowPulse;

  const _GlowBadgeSection({
    required this.glowScaleIn,
    required this.glowPulse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([glowScaleIn, glowPulse]),
            builder: (context, _) {
              final combinedScale = glowScaleIn.value * glowPulse.value;
              return Transform.scale(
                scale: combinedScale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGlow(0.2),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const AchievementBadge(
            badgeId: OnboardingConstants.rewardId,
            label: 'Novice Investor',
            size: 140,
            animate: true,
          ),
        ],
      ),
    );
  }
}

class _XpLevelCard extends StatelessWidget {
  final double xpProgress;
  final int xpEarned;

  const _XpLevelCard({
    required this.xpProgress,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Level 2',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Level 3',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$xpEarned / 100 XP',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          XPProgressBar(
            progress: xpProgress,
            currentXP: xpEarned,
            maxXP: 100,
            showLabel: false,
          ),
        ],
      ),
    );
  }
}

class _UnlockedRewardsSection extends StatelessWidget {
  const _UnlockedRewardsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unlocked',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...OnboardingConstants.unlockedRewards.map(
          (reward) => _UnlockedRewardRow(reward: reward),
        ),
      ],
    );
  }
}

class _UnlockedRewardRow extends StatelessWidget {
  final Map<String, String> reward;

  const _UnlockedRewardRow({required this.reward});

  IconData get _icon {
    switch (reward['icon']) {
      case 'dashboard':
        return Icons.dashboard_rounded;
      case 'scenario':
        return Icons.movie_filter_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward['label'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (reward['sublabel'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      reward['sublabel']!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confetti System ──────────────────────────────────────────────────────────

class _ConfettiOverlay extends StatelessWidget {
  final AnimationController controller;

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.cyan,
    AppColors.xpGold,
    AppColors.success,
    Colors.white,
  ];

  static const int _particleCount = 60;

  const _ConfettiOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _ConfettiPainter(
            progress: controller.value,
            colors: _colors,
            count: _particleCount,
            screenSize: size,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final int count;
  final Size screenSize;

  static final List<_ParticleData> _particles = [];
  static bool _initialized = false;

  _ConfettiPainter({
    required this.progress,
    required this.colors,
    required this.count,
    required this.screenSize,
  }) {
    if (!_initialized) {
      _initParticles();
      _initialized = true;
    }
  }

  void _initParticles() {
    final rng = math.Random(42);
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(_ParticleData(
        startX: rng.nextDouble(),
        speedX: (rng.nextDouble() - 0.5) * 0.6,
        speedY: 0.3 + rng.nextDouble() * 0.7,
        size: 4 + rng.nextDouble() * 7,
        color: colors[i % colors.length],
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final t = progress;
    for (final p in _particles) {
      final x = (p.startX + p.speedX * t) * size.width;
      final y = (p.speedY * t * 1.2 - 0.1) * size.height;

      final opacity = t < 0.1
          ? t / 0.1
          : t > 0.8
              ? 1.0 - (t - 0.8) / 0.2
              : 1.0;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t * math.pi * 4);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticleData {
  final double startX;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  const _ParticleData({
    required this.startX,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}