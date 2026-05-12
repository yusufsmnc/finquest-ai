import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../domain/dashboard_state.dart';

class DashboardAchievementsSection extends ConsumerWidget {
  const DashboardAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements =
        ref.watch(dashboardNotifierProvider.select((s) => s.achievements));

    return SizedBox(
      height: 100,
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
    final goldColor = const Color(0xFFF59E0B);
    final lockedColor = const Color(0xFFCBD5E1);

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? goldColor.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? goldColor.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unlocked ? _icon(achievement.id) : Icons.lock_rounded,
            color: unlocked ? goldColor : lockedColor,
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
              color: unlocked ? const Color(0xFF0F172A) : lockedColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}