// GLOBAL EVENT CONTRACT — IMMUTABLE
// All events in the system must come from this file.
// No custom events are allowed anywhere in the codebase.

enum GameEventType {
  // User Events
  decisionMade,
  decisionCorrect,
  decisionWrong,

  // Gamification Events
  xpGained,
  xpLost,
  levelUp,
  streakUpdated,
  rewardUnlocked,
}

class GameEvent {
  final GameEventType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const GameEvent({
    required this.type,
    this.payload = const {},
    required this.timestamp,
  });

  factory GameEvent.decisionMade({required String optionId}) {
    return GameEvent(
      type: GameEventType.decisionMade,
      payload: {'optionId': optionId},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.decisionCorrect({required String optionId}) {
    return GameEvent(
      type: GameEventType.decisionCorrect,
      payload: {'optionId': optionId},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.decisionWrong({required String optionId}) {
    return GameEvent(
      type: GameEventType.decisionWrong,
      payload: {'optionId': optionId},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.xpGained({required int amount}) {
    return GameEvent(
      type: GameEventType.xpGained,
      payload: {'amount': amount},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.xpLost({required int amount}) {
    return GameEvent(
      type: GameEventType.xpLost,
      payload: {'amount': amount},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.levelUp({required int newLevel}) {
    return GameEvent(
      type: GameEventType.levelUp,
      payload: {'newLevel': newLevel},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.streakUpdated({required int streak}) {
    return GameEvent(
      type: GameEventType.streakUpdated,
      payload: {'streak': streak},
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.rewardUnlocked({required String rewardId}) {
    return GameEvent(
      type: GameEventType.rewardUnlocked,
      payload: {'rewardId': rewardId},
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() => 'GameEvent(type: $type, payload: $payload)';
}