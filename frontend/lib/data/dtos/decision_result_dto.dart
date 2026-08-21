import 'progress_dto.dart';

/// Result of `POST /scenarios/{id}/decision`.
///
/// The backend owns the outcome: it echoes the [result], the authoritative
/// [xpDelta], the list of [events] it recognised, and the new [progress].
/// The frontend diffs old vs new [progress] to decide which animations fire.
class DecisionResultDto {
  final String result; // "DECISION_CORRECT" | "DECISION_WRONG"
  final int xpDelta;
  final List<String> events;
  final ProgressDto progress;
  final List<String> newAchievements; // codes unlocked by this decision

  const DecisionResultDto({
    required this.result,
    required this.xpDelta,
    required this.events,
    required this.progress,
    this.newAchievements = const [],
  });

  factory DecisionResultDto.fromJson(Map<String, dynamic> json) {
    return DecisionResultDto(
      result: json['result'] as String,
      xpDelta: json['xp_delta'] as int,
      events: (json['events'] as List<dynamic>).cast<String>(),
      progress:
          ProgressDto.fromJson(json['progress'] as Map<String, dynamic>),
      newAchievements:
          (json['new_achievements'] as List<dynamic>?)?.cast<String>() ??
              const [],
    );
  }

  bool get isCorrect => result == 'DECISION_CORRECT';
}