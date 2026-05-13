import '../../../core/events/game_event.dart';
import '../../achievements/application/achievements_notifier.dart';
import '../../ai_mentor/application/ai_mentor_notifier.dart';
import '../../gamification/application/gamification_overlay_notifier.dart';
import 'dashboard_notifier.dart';

class DashboardEventDispatcher {
  final DashboardNotifier _notifier;
  final GamificationOverlayNotifier _overlayNotifier;
  final AchievementsNotifier _achievementsNotifier;
  final AiMentorNotifier _mentorNotifier;

  const DashboardEventDispatcher(
    this._notifier,
    this._overlayNotifier,
    this._achievementsNotifier,
    this._mentorNotifier,
  );

  void _dispatch(GameEvent event) {
    _notifier.applyEvent(event);
    _overlayNotifier.applyEvent(event);
    _achievementsNotifier.applyEvent(event);
    _mentorNotifier.applyEvent(event);

    final unlocked = _achievementsNotifier.currentState.lastUnlocked;
    if (unlocked != null) {
      _overlayNotifier.triggerAchievementUnlock(unlocked.title);
      _achievementsNotifier.clearLastUnlocked();
    }
  }

  void onScenarioCompleted({required bool isCorrect}) {
    _dispatch(
        GameEvent.decisionMade(optionId: isCorrect ? 'correct' : 'wrong'));
    if (isCorrect) {
      _dispatch(GameEvent.decisionCorrect(optionId: 'correct'));
      _dispatch(GameEvent.xpGained(amount: 50));
    } else {
      _dispatch(GameEvent.decisionWrong(optionId: 'wrong'));
      _dispatch(GameEvent.xpGained(amount: 10));
    }
  }

  void onStreakUpdated(int streak) {
    _dispatch(GameEvent.streakUpdated(streak: streak));
  }

  void onRewardUnlocked(String rewardId) {
    _dispatch(GameEvent.rewardUnlocked(rewardId: rewardId));
  }

  void onXpFloatDismissed() => _notifier.dismissXpFloat();
  void onStreakPulseDismissed() => _notifier.dismissStreakPulse();
}