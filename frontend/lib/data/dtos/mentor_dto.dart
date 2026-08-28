/// DTOs for `POST /mentor`.
///
/// The mentor message is generated entirely in the backend (LLM call plus its
/// static fallback). The frontend only sends context and renders the reply —
/// it holds no prompt, no model name, and no API key.
library;

/// One recent decision, in the wire shape the backend validates.
class MentorDecisionDto {
  const MentorDecisionDto({
    required this.scenarioId,
    required this.isCorrect,
    this.category,
  });

  final String scenarioId;
  final bool isCorrect;
  final String? category;

  Map<String, dynamic> toJson() => {
        'scenario_id': scenarioId,
        // Mirrors the immutable event contract.
        'result': isCorrect ? 'DECISION_CORRECT' : 'DECISION_WRONG',
        if (category != null) 'category': category,
      };
}

class MentorRequestDto {
  const MentorRequestDto({
    required this.context,
    required this.xp,
    required this.level,
    required this.streak,
    this.recentDecisions = const [],
    this.messageIndex = 0,
  });

  /// snake_case name of the frontend's `MentorContext` (e.g. `decision_correct`).
  final String context;
  final int xp;
  final int level;
  final int streak;
  final List<MentorDecisionDto> recentDecisions;
  final int messageIndex;

  Map<String, dynamic> toJson() => {
        'context': context,
        'xp': xp,
        'level': level,
        'streak': streak,
        'recent_decisions': recentDecisions.map((d) => d.toJson()).toList(),
        'message_index': messageIndex,
      };
}

class MentorResponseDto {
  const MentorResponseDto({
    required this.message,
    required this.context,
    required this.source,
  });

  final String message;
  final String context;

  /// `ai` | `fallback` | `cache` — diagnostic only; the UI renders all three
  /// identically, so a fallback is invisible to the user.
  final String source;

  factory MentorResponseDto.fromJson(Map<String, dynamic> json) {
    return MentorResponseDto(
      message: json['message'] as String,
      context: json['context'] as String? ?? 'idle',
      source: json['source'] as String? ?? 'fallback',
    );
  }
}
