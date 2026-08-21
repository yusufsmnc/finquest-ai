import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../achievements/achievements_providers.dart';
import '../../../achievements/domain/achievement_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileActivityTimeline extends ConsumerWidget {
  const ProfileActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(
      achievementsNotifierProvider.select((s) => s.achievements),
    );
    final unlocked = achievements
        .where((a) => a.unlocked && a.unlockedAt != null)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (unlocked.isEmpty)
            _EmptyTimeline()
          else
            ...() {
              final recentSix = unlocked.take(6).toList();
              return recentSix.asMap().entries.map((entry) => _TimelineItem(
                    achievement: entry.value,
                    isLast: entry.key == recentSix.length - 1,
                  ));
            }(),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: AppColors.cyan, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your journey starts here',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete scenarios to start building\nyour activity history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Achievement achievement;
  final bool isLast;

  const _TimelineItem({required this.achievement, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final rarity = achievement.rarity;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rarity.color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: rarity.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(achievement.icon, size: 15, color: rarity.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Achievement unlocked · ${rarity.label}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: rarity.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(achievement.unlockedAt!),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}