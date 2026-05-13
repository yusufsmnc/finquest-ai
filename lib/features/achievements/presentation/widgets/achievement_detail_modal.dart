import 'package:flutter/material.dart';
import '../../domain/achievement_model.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
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
                  dotColor: const Color(0xFF64748B),
                  label: 'Category',
                  value: achievement.category.label,
                  valueColor: const Color(0xFF0F172A),
                ),
                const SizedBox(height: 12),
                _ProgressSection(achievement: achievement, rarity: rarity),
                if (unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    dotColor: const Color(0xFF059669),
                    label: 'Unlocked',
                    value: _formatDate(achievement.unlockedAt!),
                    valueColor: const Color(0xFF059669),
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
                : const Color(0xFFF1F5F9),
            border: Border.all(
              color: unlocked
                  ? rarity.color.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Icon(
            achievement.icon,
            size: 36,
            color: unlocked ? rarity.color : const Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          achievement.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
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
              color: Color(0xFF64748B),
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
            color: Color(0xFF64748B),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: Color(0xFF64748B),
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
                  color: unlocked ? rarity.color : const Color(0xFF64748B),
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
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? rarity.color : const Color(0xFF94A3B8),
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
            ? rarity.backgroundColor
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? rarity.color.withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unlocked ? Icons.format_quote_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: unlocked ? rarity.color : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unlocked ? description : 'Complete to unlock mentor insight.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: unlocked
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
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