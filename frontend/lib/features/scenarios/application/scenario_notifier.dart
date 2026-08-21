import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../data/scenario_repository.dart';
import '../domain/scenario_gamification_handler.dart';
import '../domain/scenario_state.dart';

class ScenarioNotifier extends Notifier<ScenarioState> {
  @override
  ScenarioState build() {
    return ScenarioState(scenarios: ScenarioRepository.all());
  }

  void applyEvent(GameEvent event) {
    state = ScenarioGamificationHandler.apply(state, event);
  }

  void loadScenario(String scenarioId) {
    state = state.copyWith(
      activeScenarioId: scenarioId,
      phase: ScenarioPhase.active,
      clearSelectedOption: true,
      clearIsCorrect: true,
    );
  }

  void advanceToFeedback() {
    state = state.copyWith(phase: ScenarioPhase.feedback);
  }

  void markCompleted(String scenarioId) {
    final updated = Set<String>.from(state.completedIds)..add(scenarioId);
    state = state.copyWith(completedIds: updated);
  }

  void nextScenario() {
    final current = state.activeScenarioId;
    final allIds = state.scenarios.map((s) => s.id).toList();
    final idx = allIds.indexOf(current ?? '');
    final next = idx >= 0 && idx < allIds.length - 1 ? allIds[idx + 1] : null;

    if (next != null) {
      loadScenario(next);
    } else {
      backToList();
    }
  }

  void backToList() {
    state = state.copyWith(
      phase: ScenarioPhase.list,
      clearActiveScenario: true,
      clearSelectedOption: true,
      clearIsCorrect: true,
    );
  }

  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
  }

  void dismissXpFloat() => state = state.copyWith(showXpFloat: false);
  void dismissRewardToast() => state = state.copyWith(showRewardToast: false);
  void dismissStreakPulse() => state = state.copyWith(streakPulse: false);

  ScenarioState get currentState => state;
}