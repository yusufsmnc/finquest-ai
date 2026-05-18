import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class ScenarioListScreen extends ConsumerWidget {
  const ScenarioListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenarioNotifierProvider.select((s) => s.filteredScenarios));
    final completedIds = ref.watch(scenarioNotifierProvider.select((s) => s.completedIds));
    final totalCount = ref.watch(scenarioNotifierProvider.select((s) => s.scenarios.length));
    final selectedCategory = ref.watch(scenarioNotifierProvider.select((s) => s.selectedCategory));
    final xpEarned = ref.watch(scenarioNotifierProvider.select((s) => s.xpEarned));
    final accuracyRate = ref.watch(scenarioNotifierProvider.select((s) => s.accuracyRate));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    final allCompleted = totalCount > 0 && completedIds.length >= totalCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Scenarios',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          const _StatsChip(),
          const SizedBox(width: 12),
        ],
      ),
      body: allCompleted
          ? _AllCompletedState(
              totalScenarios: totalCount,
              xpEarned: xpEarned,
              accuracyRate: accuracyRate,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryFilter(
                  selected: selectedCategory,
                  onSelected: dispatcher.onCategorySelected,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: scenarios.isEmpty
                      ? _EmptyState(
                          hasFilter: selectedCategory != null,
                          onClear: () => dispatcher.onCategorySelected(null),
                        )
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
        color: AppColors.xpGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 14),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.xpGold,
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
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow(0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
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
        return AppColors.primary;
      case 'Savings':
        return AppColors.cyan;
      default:
        return AppColors.success;
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isCompleted ? AppColors.success : catColor).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppColors.successGlow(0.12)
                    : catColor.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: isCompleted ? AppColors.success : catColor,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (isCompleted ? AppColors.success : catColor).withValues(alpha: 0.08),
                          AppColors.surface,
                        ],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 18, 18),
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: catColor.withValues(alpha: 0.2)),
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
                  color: AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '+${scenario.xpCorrect} XP for correct',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          ),    // Padding
        ),      // Container (gradient bg)
        ),      // Expanded
      ],        // Row children
    ),          // Row
    ),          // IntrinsicHeight
  ),            // ClipRRect
),              // outer Container
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
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow(0.15),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No scenarios here' : 'No scenarios yet',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'There are no scenarios in this category yet.'
                  : 'Scenarios will appear here once they are available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Show All Scenarios',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllCompletedState extends StatelessWidget {
  final int totalScenarios;
  final int xpEarned;
  final double accuracyRate;

  const _AllCompletedState({
    required this.totalScenarios,
    required this.xpEarned,
    required this.accuracyRate,
  });

  @override
  Widget build(BuildContext context) {
    final accuracyPct = (accuracyRate * 100).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.xpGoldDark, AppColors.warningLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xpGold.withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Scenarios Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve worked through every scenario.\nYour financial instinct is stronger for it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.xpGold.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xpGold.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: Icons.bolt_rounded,
                    color: AppColors.xpGold,
                    value: '$xpEarned',
                    label: 'XP Earned',
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _StatItem(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    value: '$totalScenarios',
                    label: 'Completed',
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _StatItem(
                    icon: Icons.track_changes_rounded,
                    color: AppColors.primary,
                    value: '$accuracyPct%',
                    label: 'Accuracy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.achievements),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.xpGoldDark, AppColors.xpGold],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.xpGold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'View Achievements',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.dashboard),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard_rounded,
                          color: AppColors.textSecondary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}