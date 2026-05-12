import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';

class ScenarioListScreen extends ConsumerWidget {
  const ScenarioListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenarioNotifierProvider.select((s) => s.filteredScenarios));
    final completedIds = ref.watch(scenarioNotifierProvider.select((s) => s.completedIds));
    final selectedCategory = ref.watch(scenarioNotifierProvider.select((s) => s.selectedCategory));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scenarios',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          const _StatsChip(),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryFilter(
            selected: selectedCategory,
            onSelected: dispatcher.onCategorySelected,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: scenarios.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: scenarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ScenarioCard(
                      scenario: scenarios[i],
                      isCompleted: completedIds.contains(scenarios[i].id),
                      onTap: () => dispatcher.onScenarioSelected(scenarios[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsChip extends ConsumerWidget {
  const _StatsChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(scenarioNotifierProvider.select((s) => s.xpEarned));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 14),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const categories = ['Investing', 'Savings', 'Budgeting'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(label: 'All', selected: selected == null, onTap: () => onSelected(null)),
          ...categories.map((c) => _FilterChip(
                label: c,
                selected: selected == c,
                onTap: () => onSelected(selected == c ? null : c),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.isCompleted,
    required this.onTap,
  });

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Investing':
        return const Color(0xFF2563EB);
      case 'Savings':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(scenario.category);

    return Semantics(
      button: true,
      label: '${scenario.title}, ${scenario.category}, ${scenario.riskLevel.label} risk',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scenario.category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const _CompletedBadge()
                  else
                    ScenarioRiskIndicator(riskLevel: scenario.riskLevel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                scenario.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                scenario.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '+${scenario.xpCorrect} XP for correct',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
          SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No scenarios in this category yet.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}