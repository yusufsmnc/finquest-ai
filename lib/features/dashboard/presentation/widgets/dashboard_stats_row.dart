import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../../../shared/widgets/streak_counter.dart';

class DashboardStatsRow extends ConsumerWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dashboardNotifierProvider.select((s) => s.currentStreak));
    final streakPulse = ref.watch(dashboardNotifierProvider.select((s) => s.streakPulse));
    final xp = ref.watch(dashboardNotifierProvider.select((s) => s.currentXP));
    final scenarios = ref.watch(dashboardNotifierProvider.select((s) => s.totalScenarios));

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'Streak',
            child: StreakCounter(streak: streak, pulse: streakPulse),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCell(
            label: 'Total XP',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$xp',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCell(
            label: 'Scenarios',
            child: Text(
              '$scenarios',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}