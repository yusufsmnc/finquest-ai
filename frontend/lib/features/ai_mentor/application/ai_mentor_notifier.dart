import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../../../data/dtos/mentor_dto.dart';
import '../../auth/auth_providers.dart';
import '../data/mentor_repository.dart';
import '../domain/ai_mentor_state.dart';
import '../domain/mentor_message.dart';

/// Renders mentor messages. It never generates them.
///
/// Two layers, by design:
/// 1. Events paint a local pre-seeded message immediately, so feedback stays
///    under the 150ms perception budget (CLAUDE.md) and the UI is never blank.
/// 2. Exactly ONE `POST /mentor` call per decision then replaces that text with
///    the backend's answer (LLM, or the backend's own static fallback).
///
/// Micro-events never trigger a call — a single decision can emit
/// DECISION_CORRECT + XP_GAINED + LEVEL_UP + REWARD_UNLOCKED, and that must
/// cost one request, not four. [requestForDecision] is the only entry point,
/// and the dispatcher calls it once after the event burst has settled.
class AiMentorNotifier extends Notifier<AiMentorState> {
  @override
  AiMentorState build() => const AiMentorState();

  /// Highest-priority context wins when one decision triggers several events.
  static const _contextPriority = <MentorContext>[
    MentorContext.achievementUnlock,
    MentorContext.levelUp,
    MentorContext.streakMilestone,
    MentorContext.decisionWrong,
    MentorContext.decisionCorrect,
  ];

  void applyEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.xpGained:
        // Tracked only for display; XP/level are authoritative on the backend.
        final amount = event.payload['amount'] as int? ?? 0;
        state = state.copyWith(trackedXp: state.trackedXp + amount);

      case GameEventType.decisionCorrect:
        _showLocalMessage(MentorContext.decisionCorrect, MentorMood.happy);

      case GameEventType.decisionWrong:
        _showLocalMessage(MentorContext.decisionWrong, MentorMood.encouraging);

      case GameEventType.streakUpdated:
        final streak = event.payload['streak'] as int? ?? 0;
        if (streak >= 3) {
          _showLocalMessage(MentorContext.streakMilestone, MentorMood.proud);
        }

      case GameEventType.rewardUnlocked:
        _showLocalMessage(MentorContext.achievementUnlock, MentorMood.proud);

      case GameEventType.levelUp:
        final level = event.payload['newLevel'] as int? ?? state.trackedLevel;
        state = state.copyWith(trackedLevel: level);
        _showLocalMessage(MentorContext.levelUp, MentorMood.excited);

      case GameEventType.decisionMade:
      case GameEventType.xpLost:
        break;
    }
  }

  /// One backend call for the decision that just finished.
  ///
  /// Never throws and never leaves the UI empty: the placeholder painted by
  /// [applyEvent] simply stays if the request fails. The backend answers 200
  /// with a static message even when the LLM is down, so a failure here means
  /// our own backend was unreachable.
  Future<void> requestForDecision({
    required bool isCorrect,
    required String scenarioId,
    String? category,
    required int xp,
    required int level,
    required int streak,
    bool leveledUp = false,
    bool unlockedAchievement = false,
  }) async {
    final context = _contextFor(
      isCorrect: isCorrect,
      streak: streak,
      leveledUp: leveledUp,
      unlockedAchievement: unlockedAchievement,
    );

    state = state.copyWith(isMentorLoading: true);
    try {
      final response = await ref.read(mentorApiRepositoryProvider).fetchMessage(
            MentorRequestDto(
              context: context.wireName,
              xp: xp,
              level: level,
              streak: streak,
              messageIndex: state.messageSelectIndex,
              recentDecisions: [
                MentorDecisionDto(
                  scenarioId: scenarioId,
                  isCorrect: isCorrect,
                  category: category,
                ),
              ],
            ),
          );
      _replaceCurrentMessage(response.message, context);
    } catch (_) {
      // Backend unreachable — keep the local placeholder. Nothing to surface:
      // the user already has a sensible message on screen.
    } finally {
      state = state.copyWith(isMentorLoading: false);
    }
  }

  static MentorContext _contextFor({
    required bool isCorrect,
    required int streak,
    required bool leveledUp,
    required bool unlockedAchievement,
  }) {
    final candidates = <MentorContext>{
      if (unlockedAchievement) MentorContext.achievementUnlock,
      if (leveledUp) MentorContext.levelUp,
      if (streak >= 3) MentorContext.streakMilestone,
      isCorrect ? MentorContext.decisionCorrect : MentorContext.decisionWrong,
    };
    return _contextPriority.firstWhere(candidates.contains);
  }

  /// Category tips stay local: they are generic per-category copy, not
  /// personalised guidance, so they are not worth an LLM call.
  void setCategoryGuidance(String category) {
    final context = MentorContextExt.fromCategory(category);
    final text =
        MentorRepository.pickMessage(context, state.messageSelectIndex);
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

  /// Instant, offline-safe placeholder from the bundled pool.
  void _showLocalMessage(MentorContext context, MentorMood mood) {
    final text =
        MentorRepository.pickMessage(context, state.messageSelectIndex);
    _publish(
      MentorMessage(
        id: '${context.name}_${state.messageSelectIndex}',
        text: text,
        mood: mood,
        context: context,
        timestamp: DateTime.now(),
      ),
      mood,
    );
  }

  /// Swap the placeholder for the backend's message, keeping the same mood so
  /// the avatar does not flicker between the two.
  void _replaceCurrentMessage(String text, MentorContext context) {
    final mood = state.currentMessage?.mood ?? MentorMood.calm;
    _publish(
      MentorMessage(
        id: '${context.name}_${state.messageSelectIndex}_remote',
        text: text,
        mood: mood,
        context: context,
        timestamp: DateTime.now(),
      ),
      mood,
      replaceHead: true,
    );
  }

  void _publish(MentorMessage message, MentorMood mood,
      {bool replaceHead = false}) {
    final history = replaceHead && state.messageHistory.isNotEmpty
        ? [message, ...state.messageHistory.skip(1)]
        : [message, ...state.messageHistory];
    state = state.copyWith(
      currentMessage: message,
      currentMood: mood,
      messageHistory: history.take(20).toList(),
      showNotification: true,
      messageSelectIndex: state.messageSelectIndex + 1,
    );
  }
}
