import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../../../shared/widgets/streak_counter.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardStatsRow extends ConsumerWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dashboardNotifierProvider.select((s) => s.currentStreak));
    final streakPulse = ref.watch(dashboardNotifierProvider.select((s) => s.streakPulse));
    final xp = ref.watch(dashboardNotifierProvider.select((s) => s.currentXP));
    final scenarios = ref.watch(dashboardNotifierProvider.select((s) => s.totalScenarios));

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'Streak',
            accentColor: AppColors.streakOrange,
            child: StreakCounter(streak: streak, pulse: streakPulse),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCell(
            label: 'Total XP',
            accentColor: AppColors.xpGold,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$xp',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.xpGold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCell(
            label: 'Scenarios',
            accentColor: AppColors.cyan,
            child: Text(
              '$scenarios',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final Widget child;
  final Color accentColor;

  const _StatCell({
    required this.label,
    required this.child,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withValues(alpha: 0.10),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}