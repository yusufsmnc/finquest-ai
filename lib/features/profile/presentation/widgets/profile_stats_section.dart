import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/dashboard_providers.dart';

class ProfileStatsSection extends ConsumerWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(dashboardNotifierProvider.select((s) => s.categories));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Progress',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: categories.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final isLast = i == categories.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: _CategoryRow(
                    icon: cat.icon,
                    name: cat.name,
                    progress: cat.progress,
                    color: cat.color,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final double progress;
  final Color color;

  const _CategoryRow({
    required this.icon,
    required this.name,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}