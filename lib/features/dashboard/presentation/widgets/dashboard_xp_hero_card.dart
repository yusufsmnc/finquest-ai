import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../../../shared/widgets/xp_float_indicator.dart';

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
              colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Level',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $level',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  _LevelBadge(level: level),
                ],
              ),
              const SizedBox(height: 20),
              _WhiteXpBar(progress: progress, currentXP: xp, maxXP: xpMax),
              const SizedBox(height: 10),
              Text(
                '$remaining XP to Level ${level + 1}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        if (showFloat)
          Positioned(
            right: 24,
            top: -16,
            child: XPFloatIndicator(
              amount: lastXpGained,
              visible: showFloat,
            ),
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          Text(
            '$level',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
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

class _WhiteXpBar extends StatelessWidget {
  final double progress;
  final int currentXP;
  final int maxXP;

  const _WhiteXpBar({
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
            const Text(
              'XP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$currentXP / $maxXP',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 10,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 6,
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