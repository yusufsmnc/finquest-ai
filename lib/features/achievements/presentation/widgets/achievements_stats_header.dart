import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../achievements_providers.dart';
import '../../domain/achievement_model.dart';

class AchievementsStatsHeader extends ConsumerWidget {
  const AchievementsStatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsNotifierProvider);
    final unlocked = state.unlockedCount;
    final total = state.totalCount;
    final percent = state.completionPercent;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / $total',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Achievements Unlocked',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(percent * 100).toInt()}% complete',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _CategoryBreakdown(achievements: state.achievements),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Achievement> achievements;

  const _CategoryBreakdown({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final categories = AchievementCategory.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: categories.map((cat) {
        final total =
            achievements.where((a) => a.category == cat).length;
        final unlocked = achievements
            .where((a) => a.category == cat && a.unlocked)
            .length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cat.icon, size: 12, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                '$unlocked/$total',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}