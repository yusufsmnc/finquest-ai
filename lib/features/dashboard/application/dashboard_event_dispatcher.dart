import '../../../core/events/game_event.dart';
import 'dashboard_notifier.dart';

class DashboardEventDispatcher {
  final DashboardNotifier _notifier;

  const DashboardEventDispatcher(this._notifier);

  void _dispatch(GameEvent event) => _notifier.applyEvent(event);

  void onScenarioCompleted({required bool isCorrect}) {
    _dispatch(GameEvent.decisionMade(optionId: isCorrect ? 'correct' : 'wrong'));
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