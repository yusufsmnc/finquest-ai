import 'package:flutter/material.dart';
import '../../domain/achievement_model.dart';

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
          color: unlocked ? rarity.backgroundColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? rarity.color.withValues(alpha: 0.35)
                : const Color(0xFFE2E8F0),
            width: unlocked ? 1.5 : 1,
          ),
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
                color: unlocked
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
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
                color: unlocked
                    ? const Color(0xFF64748B)
                    : const Color(0xFFCBD5E1),
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
            : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: unlocked ? rarity.color : const Color(0xFFCBD5E1),
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
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: unlocked ? rarity.color : const Color(0xFFCBD5E1),
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
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${achievement.currentProgress} / ${achievement.requiredValue}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}