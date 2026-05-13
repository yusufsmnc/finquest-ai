import '../../../core/events/game_event.dart';
import '../../achievements/application/achievements_notifier.dart';
import '../../gamification/application/gamification_overlay_notifier.dart';
import 'scenario_notifier.dart';

class ScenarioEventDispatcher {
  final ScenarioNotifier _notifier;
  final GamificationOverlayNotifier _overlayNotifier;
  final AchievementsNotifier _achievementsNotifier;

  const ScenarioEventDispatcher(
    this._notifier,
    this._overlayNotifier,
    this._achievementsNotifier,
  );

  void _dispatch(GameEvent event) {
    _notifier.applyEvent(event);
    _overlayNotifier.applyEvent(event);
    _achievementsNotifier.applyEvent(event);

    final unlocked = _achievementsNotifier.currentState.lastUnlocked;
    if (unlocked != null) {
      _overlayNotifier.triggerAchievementUnlock(unlocked.title);
      _achievementsNotifier.clearLastUnlocked();
    }
  }

  void onDecisionMade(String scenarioId, String optionId, bool isCorrect, int xpAmount) {
    _dispatch(GameEvent.decisionMade(optionId: optionId));

    if (isCorrect) {
      _dispatch(GameEvent.decisionCorrect(optionId: optionId));
    } else {
      _dispatch(GameEvent.decisionWrong(optionId: optionId));
    }

    _dispatch(GameEvent.xpGained(amount: xpAmount));

    final newStreak = isCorrect ? _notifier.currentState.currentStreak + 1 : 0;
    _dispatch(GameEvent.streakUpdated(streak: newStreak));

    final newCorrectCount = _notifier.currentState.correctCount;
    if (isCorrect && newCorrectCount % 3 == 0) {
      _dispatch(GameEvent.rewardUnlocked(rewardId: 'streak_reward'));
    }

    _notifier.markCompleted(scenarioId);
    _notifier.advanceToFeedback();
  }

  void onNextScenario() => _notifier.nextScenario();
  void onBackToList() => _notifier.backToList();
  void onScenarioSelected(String id) => _notifier.loadScenario(id);
  void onCategorySelected(String? category) => _notifier.setCategory(category);

  void onXpFloatDismissed() => _notifier.dismissXpFloat();
  void onRewardToastDismissed() => _notifier.dismissRewardToast();
  void onStreakPulseDismissed() => _notifier.dismissStreakPulse();
}