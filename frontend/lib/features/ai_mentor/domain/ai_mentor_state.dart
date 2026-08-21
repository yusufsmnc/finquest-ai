import 'mentor_message.dart';

class AiMentorState {
  final MentorMessage? currentMessage;
  final MentorMood currentMood;
  final List<MentorMessage> messageHistory;
  final bool showNotification;
  final String? categoryGuidanceText;
  final int trackedXp;
  final int trackedLevel;
  final int messageSelectIndex;

  const AiMentorState({
    this.currentMessage,
    this.currentMood = MentorMood.calm,
    this.messageHistory = const [],
    this.showNotification = false,
    this.categoryGuidanceText,
    this.trackedXp = 0,
    this.trackedLevel = 1,
    this.messageSelectIndex = 0,
  });

  AiMentorState copyWith({
    MentorMessage? currentMessage,
    bool clearCurrentMessage = false,
    MentorMood? currentMood,
    List<MentorMessage>? messageHistory,
    bool? showNotification,
    String? categoryGuidanceText,
    bool clearCategoryGuidance = false,
    int? trackedXp,
    int? trackedLevel,
    int? messageSelectIndex,
  }) {
    return AiMentorState(
      currentMessage: clearCurrentMessage
          ? null
          : currentMessage ?? this.currentMessage,
      currentMood: currentMood ?? this.currentMood,
      messageHistory: messageHistory ?? this.messageHistory,
      showNotification: showNotification ?? this.showNotification,
      categoryGuidanceText: clearCategoryGuidance
          ? null
          : categoryGuidanceText ?? this.categoryGuidanceText,
      trackedXp: trackedXp ?? this.trackedXp,
      trackedLevel: trackedLevel ?? this.trackedLevel,
      messageSelectIndex: messageSelectIndex ?? this.messageSelectIndex,
    );
  }
}