import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../../../scenarios/scenario_providers.dart';
import '../../profile_providers.dart';

class ProfileStreakSection extends ConsumerWidget {
  const ProfileStreakSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak =
        ref.watch(dashboardNotifierProvider.select((s) => s.currentStreak));
    final bestStreak =
        ref.watch(profileNotifierProvider.select((s) => s.bestStreak));
    final accuracyRate =
        ref.watch(scenarioNotifierProvider.select((s) => s.accuracyRate));
    final totalDecisions =
        ref.watch(scenarioNotifierProvider.select((s) => s.totalDecisions));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StreakCard(
              current: currentStreak,
              best: bestStreak < currentStreak ? currentStreak : bestStreak,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AccuracyCard(
              rate: accuracyRate,
              total: totalDecisions,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int current;
  final int best;

  const _StreakCard({required this.current, required this.best});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Streak',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 2),
                child: Text(
                  ' now',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                'Best: $best',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FlameRow(current: current),
        ],
      ),
    );
  }
}

class _FlameRow extends StatelessWidget {
  final int current;

  const _FlameRow({required this.current});

  @override
  Widget build(BuildContext context) {
    const total = 7;
    return Row(
      children: List.generate(total, (i) {
        final active = i < current.clamp(0, total);
        return Padding(
          padding: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: active
                ? const Color(0xFFF59E0B)
                : const Color(0xFFE2E8F0),
          ),
        );
      }),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  final double rate;
  final int total;

  const _AccuracyCard({required this.rate, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).toInt();
    final color = rate >= 0.7
        ? const Color(0xFF059669)
        : rate >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.gps_fixed_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Accuracy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total == 0 ? 'No decisions yet' : '$total decisions made',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}