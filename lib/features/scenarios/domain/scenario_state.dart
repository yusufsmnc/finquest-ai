import 'scenario_model.dart';

enum ScenarioPhase { list, active, feedback }

class ScenarioState {
  final List<Scenario> scenarios;
  final String? activeScenarioId;
  final Set<String> completedIds;
  final ScenarioPhase phase;
  final String? selectedOptionId;
  final bool? isCorrect;
  final int xpEarned;
  final int lastXpGained;
  final int currentStreak;
  final int correctCount;
  final int totalDecisions;
  final bool showXpFloat;
  final bool showRewardToast;
  final bool streakPulse;
  final String? selectedCategory;

  const ScenarioState({
    this.scenarios = const [],
    this.activeScenarioId,
    this.completedIds = const {},
    this.phase = ScenarioPhase.list,
    this.selectedOptionId,
    this.isCorrect,
    this.xpEarned = 0,
    this.lastXpGained = 0,
    this.currentStreak = 0,
    this.correctCount = 0,
    this.totalDecisions = 0,
    this.showXpFloat = false,
    this.showRewardToast = false,
    this.streakPulse = false,
    this.selectedCategory,
  });

  Scenario? get activeScenario => activeScenarioId == null
      ? null
      : scenarios.where((s) => s.id == activeScenarioId).firstOrNull;

  List<Scenario> get filteredScenarios => selectedCategory == null
      ? scenarios
      : scenarios.where((s) => s.category == selectedCategory).toList();

  double get accuracyRate =>
      totalDecisions == 0 ? 0 : correctCount / totalDecisions;

  ScenarioState copyWith({
    List<Scenario>? scenarios,
    String? activeScenarioId,
    Set<String>? completedIds,
    ScenarioPhase? phase,
    String? selectedOptionId,
    bool? isCorrect,
    int? xpEarned,
    int? lastXpGained,
    int? currentStreak,
    int? correctCount,
    int? totalDecisions,
    bool? showXpFloat,
    bool? showRewardToast,
    bool? streakPulse,
    String? selectedCategory,
    bool clearActiveScenario = false,
    bool clearSelectedOption = false,
    bool clearIsCorrect = false,
    bool clearCategory = false,
  }) {
    return ScenarioState(
      scenarios: scenarios ?? this.scenarios,
      activeScenarioId:
          clearActiveScenario ? null : activeScenarioId ?? this.activeScenarioId,
      completedIds: completedIds ?? this.completedIds,
      phase: phase ?? this.phase,
      selectedOptionId: clearSelectedOption
          ? null
          : selectedOptionId ?? this.selectedOptionId,
      isCorrect: clearIsCorrect ? null : isCorrect ?? this.isCorrect,
      xpEarned: xpEarned ?? this.xpEarned,
      lastXpGained: lastXpGained ?? this.lastXpGained,
      currentStreak: currentStreak ?? this.currentStreak,
      correctCount: correctCount ?? this.correctCount,
      totalDecisions: totalDecisions ?? this.totalDecisions,
      showXpFloat: showXpFloat ?? this.showXpFloat,
      showRewardToast: showRewardToast ?? this.showRewardToast,
      streakPulse: streakPulse ?? this.streakPulse,
      selectedCategory:
          clearCategory ? null : selectedCategory ?? this.selectedCategory,
    );
  }
}