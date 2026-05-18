import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../../../shared/widgets/xp_float_indicator.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardXpHeroCard extends ConsumerWidget {
  const DashboardXpHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(dashboardNotifierProvider.select((s) => s.currentLevel));
    final xp = ref.watch(dashboardNotifierProvider.select((s) => s.currentXP));
    final xpMax = ref.watch(dashboardNotifierProvider.select((s) => s.xpToNextLevel));
    final progress = ref.watch(dashboardNotifierProvider.select((s) => s.xpProgress));
    final remaining = ref.watch(dashboardNotifierProvider.select((s) => s.xpRemaining));
    final showFloat = ref.watch(dashboardNotifierProvider.select((s) => s.showXpFloat));
    final lastXpGained = ref.watch(dashboardNotifierProvider.select((s) => s.lastXpGained));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.indigoDeep,
                AppColors.purpleDark,
                AppColors.cyanDark,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative watermark circle top-right
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR LEVEL',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, AppColors.skyLight],
                            ).createShader(bounds),
                            child: Text(
                              'Level $level',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _LevelBadge(level: level),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlowXpBar(progress: progress, currentXP: xp, maxXP: xpMax),
                  const SizedBox(height: 10),
                  Text(
                    '$remaining XP to Level ${level + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showFloat)
          Positioned(
            right: 24,
            top: -16,
            child: XPFloatIndicator(amount: lastXpGained, visible: showFloat),
          ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          Text(
            '$level',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowXpBar extends StatelessWidget {
  final double progress;
  final int currentXP;
  final int maxXP;

  const _GlowXpBar({
    required this.progress,
    required this.currentXP,
    required this.maxXP,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$currentXP / $maxXP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 12,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, AppColors.skyLight],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}