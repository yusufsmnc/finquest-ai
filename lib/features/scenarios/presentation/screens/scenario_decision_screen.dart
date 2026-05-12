import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';

class ScenarioDecisionScreen extends ConsumerWidget {
  const ScenarioDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenario = ref.watch(scenarioNotifierProvider.select((s) => s.activeScenario));
    final selectedOptionId = ref.watch(scenarioNotifierProvider.select((s) => s.selectedOptionId));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    if (scenario == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => dispatcher.onBackToList(),
        ),
        title: Text(
          scenario.category,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScenarioRiskIndicator(riskLevel: scenario.riskLevel, large: true),
            const SizedBox(height: 20),
            _ScenarioEventCard(scenario: scenario),
            const SizedBox(height: 24),
            const Text(
              'What would you do?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...scenario.options.asMap().entries.map((entry) => _OptionCard(
                  option: entry.value,
                  index: entry.key,
                  isSelected: selectedOptionId == entry.value.id,
                  isLocked: selectedOptionId != null,
                  onTap: selectedOptionId == null
                      ? () => dispatcher.onDecisionMade(
                            scenario.id,
                            entry.value.id,
                            entry.value.isCorrect,
                            entry.value.isCorrect ? scenario.xpCorrect : scenario.xpParticipation,
                          )
                      : null,
                )),
          ],
        ),
      ),
    );
  }
}

class _ScenarioEventCard extends StatelessWidget {
  final Scenario scenario;
  const _ScenarioEventCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Financial Scenario',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            scenario.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scenario.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final ScenarioOption option;
  final int index;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.index,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final label = index < _labels.length ? _labels[index] : '${index + 1}';

    Color borderColor;
    Color bgColor;
    Color labelBg;
    Color labelFg;

    if (!isLocked) {
      borderColor = const Color(0xFFE2E8F0);
      bgColor = Colors.white;
      labelBg = const Color(0xFFF1F5F9);
      labelFg = const Color(0xFF64748B);
    } else if (isSelected) {
      borderColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFF2563EB).withValues(alpha: 0.04);
      labelBg = const Color(0xFF2563EB);
      labelFg = Colors.white;
    } else {
      borderColor = const Color(0xFFE2E8F0);
      bgColor = Colors.white;
      labelBg = const Color(0xFFF1F5F9);
      labelFg = const Color(0xFFCBD5E1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: 'Option $label: ${option.text}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLocked ? 0.02 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: labelBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelFg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isLocked && !isSelected
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF0F172A),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}