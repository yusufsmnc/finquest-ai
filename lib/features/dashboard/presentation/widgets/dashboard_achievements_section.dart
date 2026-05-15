import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../domain/dashboard_state.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardAchievementsSection extends ConsumerWidget {
  const DashboardAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements =
        ref.watch(dashboardNotifierProvider.select((s) => s.achievements));

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            _AchievementChip(achievement: achievements[i]),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final DashboardAchievement achievement;
  const _AchievementChip({required this.achievement});

  IconData _icon(String id) {
    switch (id) {
      case 'badge_novice':
        return Icons.military_tech_rounded;
      case 'badge_investor':
        return Icons.trending_up_rounded;
      case 'badge_expert':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;

    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.xpGold.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppColors.xpGold.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.xpGold.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unlocked ? _icon(achievement.id) : Icons.lock_rounded,
            color: unlocked ? AppColors.xpGold : AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            achievement.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}