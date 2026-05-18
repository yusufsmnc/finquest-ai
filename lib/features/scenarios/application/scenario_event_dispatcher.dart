import '../../../core/events/game_event.dart';
import '../../achievements/application/achievements_notifier.dart';
import '../../ai_mentor/application/ai_mentor_notifier.dart';
import '../../gamification/application/gamification_overlay_notifier.dart';
import '../../market_events/application/market_events_notifier.dart';
import 'scenario_notifier.dart';

class ScenarioEventDispatcher {
  final ScenarioNotifier _notifier;
  final GamificationOverlayNotifier _overlayNotifier;
  final AchievementsNotifier _achievementsNotifier;
  final AiMentorNotifier _mentorNotifier;
  final MarketEventsNotifier _marketEventsNotifier;

  bool _disposed = false;

  ScenarioEventDispatcher(
    this._notifier,
    this._overlayNotifier,
    this._achievementsNotifier,
    this._mentorNotifier,
    this._marketEventsNotifier,
  );

  void dispose() => _disposed = true;

  void _dispatch(GameEvent event) {
    _notifier.applyEvent(event);
    _overlayNotifier.applyEvent(event);
    _achievementsNotifier.applyEvent(event);
    _mentorNotifier.applyEvent(event);
    _marketEventsNotifier.applyEvent(event);

    final unlocked = _achievementsNotifier.currentState.lastUnlocked;
    if (unlocked != null) {
      _overlayNotifier.triggerAchievementUnlock(unlocked.title);
      _achievementsNotifier.clearLastUnlocked();
    }
  }

  Future<void> onDecisionMade(
      String scenarioId, String optionId, bool isCorrect, int xpAmount) async {
    _dispatch(GameEvent.decisionMade(optionId: optionId));

    if (isCorrect) {
      _dispatch(GameEvent.decisionCorrect(optionId: optionId));
    } else {
      _dispatch(GameEvent.decisionWrong(optionId: optionId));
    }

    _dispatch(GameEvent.xpGained(amount: xpAmount));

    final newStreak =
        isCorrect ? _notifier.currentState.currentStreak + 1 : 0;
    _dispatch(GameEvent.streakUpdated(streak: newStreak));

    final newCorrectCount = _notifier.currentState.correctCount;
    if (isCorrect && newCorrectCount % 3 == 0) {
      _dispatch(GameEvent.rewardUnlocked(rewardId: 'streak_reward'));
    }

    _notifier.markCompleted(scenarioId);

    // Wait for answer animation to play before advancing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_disposed) return;
    _notifier.advanceToFeedback();
  }

  void onScenarioSelected(String id) {
    _notifier.loadScenario(id);
    final category = _notifier.currentState.activeScenario?.category;
    if (category != null) {
      _mentorNotifier.setCategoryGuidance(category);
    }
  }

  void onNextScenario() => _notifier.nextScenario();
  void onBackToList() => _notifier.backToList();
  void onCategorySelected(String? category) {
    _notifier.setCategory(category);
    if (category != null) {
      _mentorNotifier.setCategoryGuidance(category);
    }
  }

  void onXpFloatDismissed() => _notifier.dismissXpFloat();
  void onRewardToastDismissed() => _notifier.dismissRewardToast();
  void onStreakPulseDismissed() => _notifier.dismissStreakPulse();
}