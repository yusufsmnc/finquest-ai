import 'package:flutter/material.dart';
import '../../domain/achievement_model.dart';
import '../../../../core/theme/app_colors.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarity = achievement.rarity;
    final unlocked = achievement.unlocked;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked
              ? rarity.color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? rarity.color.withValues(alpha: 0.35)
                : AppColors.border,
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
            if (unlocked)
              BoxShadow(
                color: rarity.color.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AchievementIcon(
                  icon: achievement.icon,
                  rarity: rarity,
                  unlocked: unlocked,
                ),
                const Spacer(),
                _RarityBadge(rarity: rarity, unlocked: unlocked),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            _ProgressRow(achievement: achievement),
          ],
        ),
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final IconData icon;
  final AchievementRarity rarity;
  final bool unlocked;

  const _AchievementIcon({
    required this.icon,
    required this.rarity,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: unlocked
            ? rarity.color.withValues(alpha: 0.15)
            : AppColors.surfaceUp,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: unlocked ? rarity.color : AppColors.textMuted,
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final bool unlocked;

  const _RarityBadge({required this.rarity, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: unlocked
            ? rarity.color.withValues(alpha: 0.12)
            : AppColors.surfaceUp,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: unlocked ? rarity.color : AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final Achievement achievement;

  const _ProgressRow({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final fraction = achievement.progressFraction;

    if (unlocked) {
      return Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 12, color: achievement.rarity.color),
          const SizedBox(width: 4),
          Text(
            'Unlocked',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: achievement.rarity.color,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${achievement.currentProgress} / ${achievement.requiredValue}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}