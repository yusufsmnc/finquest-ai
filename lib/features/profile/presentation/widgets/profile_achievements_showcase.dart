import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../achievements/achievements_providers.dart';
import '../../../achievements/domain/achievement_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileAchievementsShowcase extends ConsumerWidget {
  const ProfileAchievementsShowcase({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(
      achievementsNotifierProvider.select((s) => s.achievements),
    );
    final unlocked = achievements.where((a) => a.unlocked).toList()
      ..sort((a, b) => (b.unlockedAt ?? DateTime(0))
          .compareTo(a.unlockedAt ?? DateTime(0)));
    final unlockedCount = unlocked.length;
    final totalCount = achievements.length;
    final recent = unlocked.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.achievements),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$unlockedCount of $totalCount unlocked',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            _EmptyShowcase()
          else
            Row(
              children: [
                ...recent.map((a) => _AchievementBubble(achievement: a)).toList(),
                if (unlockedCount > 4)
                  _MoreBubble(count: unlockedCount - 4),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.xpGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.xpGold.withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: AppColors.xpGold, size: 22),
          ),
          const SizedBox(height: 10),
          const Text(
            'No achievements yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Complete scenarios to earn your first badge',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _AchievementBubble extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBubble({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final rarity = achievement.rarity;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: achievement.title,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rarity.color.withValues(alpha: 0.1),
            border: Border.all(
              color: rarity.color.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: rarity.color.withValues(alpha: 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(achievement.icon, size: 22, color: rarity.color),
        ),
      ),
    );
  }
}

class _MoreBubble extends StatelessWidget {
  final int count;

  const _MoreBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceUp,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}