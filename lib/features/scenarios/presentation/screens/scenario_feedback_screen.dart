import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../application/scenario_event_dispatcher.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';
import '../widgets/scenario_xp_summary.dart';

class ScenarioFeedbackScreen extends ConsumerWidget {
  const ScenarioFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenario = ref.watch(scenarioNotifierProvider.select((s) => s.activeScenario));
    final selectedOptionId = ref.watch(scenarioNotifierProvider.select((s) => s.selectedOptionId));
    final isCorrect = ref.watch(scenarioNotifierProvider.select((s) => s.isCorrect ?? false));
    final lastXpGained = ref.watch(scenarioNotifierProvider.select((s) => s.lastXpGained));
    final streak = ref.watch(scenarioNotifierProvider.select((s) => s.currentStreak));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    if (scenario == null || selectedOptionId == null) return const SizedBox.shrink();

    final selectedOption = scenario.options.where((o) => o.id == selectedOptionId).firstOrNull;
    final correctOption = scenario.correctOption;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Decision Result',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultBanner(isCorrect: isCorrect),
            const SizedBox(height: 16),
            if (lastXpGained > 0) ...[
              ScenarioXpSummary(
                xpGained: lastXpGained,
                isCorrect: isCorrect,
                streak: streak,
              ),
              const SizedBox(height: 16),
            ],
            if (selectedOption != null)
              _FeedbackCard(
                title: 'Your Choice',
                text: selectedOption.feedbackText,
                isCorrect: isCorrect,
              ),
            if (!isCorrect && correctOption != null) ...[
              const SizedBox(height: 12),
              _FeedbackCard(
                title: 'Better Answer',
                text: correctOption.feedbackText,
                isCorrect: true,
                isBestAnswer: true,
              ),
            ],
            const SizedBox(height: 16),
            _MentorCard(explanation: scenario.mentorExplanation),
            const SizedBox(height: 16),
            _RiskContextRow(riskLevel: scenario.riskLevel),
            const SizedBox(height: 28),
            _ActionButtons(
              dispatcher: dispatcher,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool isCorrect;
  const _ResultBanner({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
            : const Color(0xFFDC2626).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF16A34A).withValues(alpha: 0.25)
              : const Color(0xFFDC2626).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                  : const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect ? 'Excellent Decision!' : 'Not the Best Choice',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              Text(
                isCorrect ? 'You chose wisely.' : 'Learn from the feedback below.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isCorrect
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String title;
  final String text;
  final bool isCorrect;
  final bool isBestAnswer;

  const _FeedbackCard({
    required this.title,
    required this.text,
    required this.isCorrect,
    this.isBestAnswer = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBestAnswer ? Icons.lightbulb_rounded : Icons.chat_bubble_outline_rounded,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final String explanation;
  const _MentorCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7C3AED),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Mentor',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            explanation,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskContextRow extends StatelessWidget {
  final RiskLevel riskLevel;
  const _RiskContextRow({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return ScenarioRiskIndicator(riskLevel: riskLevel, large: true);
  }
}

class _ActionButtons extends StatelessWidget {
  final ScenarioEventDispatcher dispatcher;
  const _ActionButtons({required this.dispatcher});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => dispatcher.onNextScenario(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Next Scenario',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => dispatcher.onBackToList(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Back to Scenarios',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}