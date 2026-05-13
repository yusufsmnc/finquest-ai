import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../achievements_providers.dart';
import '../../domain/achievement_model.dart';

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
            color: const Color(0xFF2563EB),
            onTap: () => notifier.setFilter(null),
          ),
          ...categories.map(
            (cat) => _FilterChip(
              label: cat.label,
              icon: cat.icon,
              selected: filter == cat,
              color: cat == AchievementCategory.streak
                  ? const Color(0xFFF59E0B)
                  : cat == AchievementCategory.xp
                      ? const Color(0xFF7C3AED)
                      : cat == AchievementCategory.decisions
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF059669),
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
          color: selected ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}