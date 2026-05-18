import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../achievements_providers.dart';
import '../../domain/achievement_model.dart';
import '../../../../core/theme/app_colors.dart';

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
          colors: [AppColors.primaryDark, AppColors.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.2),
            blurRadius: 48,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, AppColors.skyLight],
                  ).createShader(bounds),
                  child: Text(
                    '$unlocked / $total',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
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
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white24,
                      ),
                      FractionallySizedBox(
                        widthFactor: percent.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, AppColors.skyLight],
                            ),
                          ),
                        ),
                      ),
                    ],
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