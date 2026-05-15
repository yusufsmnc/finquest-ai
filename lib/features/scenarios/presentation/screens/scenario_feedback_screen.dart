import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../application/scenario_event_dispatcher.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';
import '../widgets/scenario_xp_summary.dart';
import '../../../../core/theme/app_colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Decision Result',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultBanner(isCorrect: isCorrect, streak: streak),
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
            _ActionButtons(dispatcher: dispatcher),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool isCorrect;
  final int streak;
  const _ResultBanner({required this.isCorrect, required this.streak});

  String get _headline {
    if (!isCorrect) return 'Not the Best Choice';
    if (streak >= 5) return '🔥🔥 On Fire! $streak in a row!';
    if (streak >= 3) return '🔥 Hot Streak! $streak correct!';
    if (streak == 2) return '2 in a Row!';
    return 'Excellent Decision!';
  }

  String get _subline {
    if (!isCorrect) return 'Learn from the feedback below.';
    if (streak >= 3) return 'You\'re on a roll — keep going!';
    if (streak == 2) return 'Two smart decisions in a row!';
    return 'You chose wisely.';
  }

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headline,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                _subline,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: color.withValues(alpha: 0.7),
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
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
              color: AppColors.textSecondary,
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
        color: AppColors.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.purple,
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
                  color: AppColors.purple,
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
              color: AppColors.textSecondary,
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.purple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
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
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Back to Scenarios',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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