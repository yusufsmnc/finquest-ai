import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../scenario_providers.dart';
import '../domain/scenario_state.dart';
import 'screens/scenario_list_screen.dart';
import 'screens/scenario_decision_screen.dart';
import 'screens/scenario_feedback_screen.dart';
import 'widgets/scenario_xp_float_overlay.dart';
import 'widgets/scenario_reward_toast_overlay.dart';

class ScenarioFlow extends ConsumerStatefulWidget {
  const ScenarioFlow({super.key});

  @override
  ConsumerState<ScenarioFlow> createState() => _ScenarioFlowState();
}

class _ScenarioFlowState extends ConsumerState<ScenarioFlow> {
  bool _categoryApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoryApplied) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _categoryApplied = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(scenarioDispatcherProvider).onCategorySelected(args);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(scenarioNotifierProvider.select((s) => s.phase));
    final notifier = ref.read(scenarioNotifierProvider.notifier);

    ref.listen(scenarioNotifierProvider.select((s) => s.showXpFloat),
        (_, show) {
      if (show) {
        Future.delayed(
            const Duration(milliseconds: 800), () => notifier.dismissXpFloat());
      }
    });

    ref.listen(scenarioNotifierProvider.select((s) => s.streakPulse),
        (_, pulse) {
      if (pulse) {
        Future.delayed(const Duration(milliseconds: 600),
            () => notifier.dismissStreakPulse());
      }
    });

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _screenFor(phase),
        ),
        const ScenarioXpFloatOverlay(),
        const ScenarioRewardToastOverlay(),
      ],
    );
  }

  Widget _screenFor(ScenarioPhase phase) {
    switch (phase) {
      case ScenarioPhase.list:
        return const ScenarioListScreen(key: ValueKey('list'));
      case ScenarioPhase.active:
        return const ScenarioDecisionScreen(key: ValueKey('active'));
      case ScenarioPhase.feedback:
        return const ScenarioFeedbackScreen(key: ValueKey('feedback'));
    }
  }
}