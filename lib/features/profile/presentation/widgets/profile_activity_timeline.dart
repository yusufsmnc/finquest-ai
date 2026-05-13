import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../achievements/achievements_providers.dart';
import '../../../achievements/domain/achievement_model.dart';

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
              color: Color(0xFF0F172A),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 28, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'No activity yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Complete scenarios to start your journey',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFFCBD5E1),
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
                    color: rarity.backgroundColor,
                    border: Border.all(
                      color: rarity.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child:
                      Icon(achievement.icon, size: 15, color: rarity.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE2E8F0),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              color: Color(0xFF0F172A),
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
                        color: Color(0xFF94A3B8),
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