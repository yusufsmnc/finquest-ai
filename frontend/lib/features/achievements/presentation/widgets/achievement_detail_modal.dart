import 'package:flutter/material.dart';
import '../../domain/achievement_model.dart';
import '../../../../core/theme/app_colors.dart';

class AchievementDetailModal extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailModal({super.key, required this.achievement});

  static Future<void> show(BuildContext context, Achievement achievement) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AchievementDetailModal(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rarity = achievement.rarity;
    final unlocked = achievement.unlocked;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceUp,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _HeroSection(achievement: achievement, rarity: rarity, unlocked: unlocked),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _InfoRow(
                  dotColor: rarity.color,
                  label: 'Rarity',
                  value: rarity.label,
                  valueColor: rarity.color,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  dotColor: AppColors.textSecondary,
                  label: 'Category',
                  value: achievement.category.label,
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 12),
                _ProgressSection(achievement: achievement, rarity: rarity),
                if (unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    dotColor: AppColors.success,
                    label: 'Unlocked',
                    value: _formatDate(achievement.unlockedAt!),
                    valueColor: AppColors.success,
                  ),
                ],
                const SizedBox(height: 20),
                _RewardPreview(
                  description: achievement.rewardDescription,
                  rarity: rarity,
                  unlocked: unlocked,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _HeroSection extends StatelessWidget {
  final Achievement achievement;
  final AchievementRarity rarity;
  final bool unlocked;

  const _HeroSection({
    required this.achievement,
    required this.rarity,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? rarity.color.withValues(alpha: 0.12)
                : AppColors.surfaceHigh,
            border: Border.all(
              color: unlocked
                  ? rarity.color.withValues(alpha: 0.35)
                  : AppColors.border,
              width: 2,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: rarity.color.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            achievement.icon,
            size: 36,
            color: unlocked ? rarity.color : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          achievement.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Achievement achievement;
  final AchievementRarity rarity;

  const _ProgressSection({required this.achievement, required this.rarity});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final fraction = achievement.progressFraction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                unlocked
                    ? 'Complete!'
                    : '${achievement.currentProgress} / ${achievement.requiredValue}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? rarity.color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? rarity.color : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPreview extends StatelessWidget {
  final String description;
  final AchievementRarity rarity;
  final bool unlocked;

  const _RewardPreview({
    required this.description,
    required this.rarity,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? rarity.color.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? rarity.color.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unlocked ? Icons.format_quote_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: unlocked ? rarity.color : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unlocked ? description : 'Complete to unlock mentor insight.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                height: 1.5,
                fontStyle: unlocked ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}