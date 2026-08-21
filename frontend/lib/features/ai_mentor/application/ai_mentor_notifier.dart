import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../data/mentor_repository.dart';
import '../domain/ai_mentor_state.dart';
import '../domain/mentor_message.dart';

class AiMentorNotifier extends Notifier<AiMentorState> {
  @override
  AiMentorState build() => const AiMentorState();

  void applyEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.xpGained:
        final amount = event.payload['amount'] as int? ?? 0;
        final newXp = state.trackedXp + amount;
        final newLevel = (newXp ~/ 200) + 1;
        final didLevelUp = newLevel > state.trackedLevel;
        state = state.copyWith(trackedXp: newXp, trackedLevel: newLevel);
        if (didLevelUp) {
          _showMessage(MentorContext.levelUp, MentorMood.excited);
        }

      case GameEventType.decisionCorrect:
        _showMessage(MentorContext.decisionCorrect, MentorMood.happy);

      case GameEventType.decisionWrong:
        _showMessage(MentorContext.decisionWrong, MentorMood.encouraging);

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int? ?? 0;
        if (streak >= 3) {
          _showMessage(MentorContext.streakMilestone, MentorMood.proud);
        }

      case GameEventType.rewardUnlocked:
        _showMessage(MentorContext.achievementUnlock, MentorMood.proud);

      case GameEventType.levelUp:
        _showMessage(MentorContext.levelUp, MentorMood.excited);

      case GameEventType.decisionMade:
      case GameEventType.xpLost:
        break;
    }
  }

  void setCategoryGuidance(String category) {
    final context = MentorContextExt.fromCategory(category);
    final text = MentorRepository.pickMessage(context, state.messageSelectIndex);
    state = state.copyWith(
      categoryGuidanceText: text,
      messageSelectIndex: state.messageSelectIndex + 1,
    );
  }

  void dismissNotification() {
    state = state.copyWith(showNotification: false);
  }

  void clearCurrentMessage() {
    state = state.copyWith(clearCurrentMessage: true, showNotification: false);
  }

  AiMentorState get currentState => state;

  void _showMessage(MentorContext context, MentorMood mood) {
    final text = MentorRepository.pickMessage(context, state.messageSelectIndex);
    final message = MentorMessage(
      id: '${context.name}_${state.messageSelectIndex}',
      text: text,
      mood: mood,
      context: context,
      timestamp: DateTime.now(),
    );
    final updatedHistory =
        [message, ...state.messageHistory].take(20).toList();
    state = state.copyWith(
      currentMessage: message,
      currentMood: mood,
      messageHistory: updatedHistory,
      showNotification: true,
      messageSelectIndex: state.messageSelectIndex + 1,
    );
  }
}