import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../achievements_providers.dart';
import '../../domain/achievement_model.dart';
import '../../../../core/theme/app_colors.dart';

class AchievementsFilterBar extends ConsumerWidget {
  const AchievementsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter =
        ref.watch(achievementsNotifierProvider.select((s) => s.filterCategory));
    final notifier = ref.read(achievementsNotifierProvider.notifier);

    final categories = AchievementCategory.values;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: filter == null,
            color: AppColors.primary,
            onTap: () => notifier.setFilter(null),
          ),
          ...categories.map(
            (cat) => _FilterChip(
              label: cat.label,
              icon: cat.icon,
              selected: filter == cat,
              color: cat == AchievementCategory.streak
                  ? AppColors.xpGold
                  : cat == AchievementCategory.xp
                      ? AppColors.purple
                      : cat == AchievementCategory.decisions
                          ? AppColors.primary
                          : AppColors.success,
              onTap: () => notifier.setFilter(cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}