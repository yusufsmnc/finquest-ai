/// Authoritative progress as returned by the backend (`GET /me/progress`).
///
/// XP / level / streak are computed by the backend — the frontend never
/// derives them. `level` here is the source of truth; the UI only formats it.
class ProgressDto {
  final int xp;
  final int level;
  final int streakCount;

  /// Highest streak ever reached. Stored server-side, so it survives the
  /// current streak resetting to zero on a wrong answer.
  final int bestStreak;

  final DateTime? lastActive;

  // Derived counts (backend-computed from scenario_history) that drive
  // mission/achievement progress bars — the UI never counts these itself.
  final int decisionsMade;
  final int decisionsToday;
  final int correctDecisions;

  /// correctDecisions / decisionsMade, already guarded against division by
  /// zero on the server. A rate, not a percentage: 0.75, not 75.
  final double accuracy;

  /// Gross XP ever earned. Deliberately not [xp], which is the net balance
  /// after wrong answers deduct from it and is floored at zero.
  final int xpEarnedTotal;

  const ProgressDto({
    required this.xp,
    required this.level,
    required this.streakCount,
    this.bestStreak = 0,
    this.lastActive,
    this.decisionsMade = 0,
    this.decisionsToday = 0,
    this.correctDecisions = 0,
    this.accuracy = 0.0,
    this.xpEarnedTotal = 0,
  });

  factory ProgressDto.fromJson(Map<String, dynamic> json) {
    final rawLastActive = json['last_active'] as String?;
    return ProgressDto(
      xp: json['xp'] as int,
      level: json['level'] as int,
      streakCount: json['streak_count'] as int,
      bestStreak: json['best_streak'] as int? ?? 0,
      lastActive:
          rawLastActive == null ? null : DateTime.tryParse(rawLastActive),
      decisionsMade: json['decisions_made'] as int? ?? 0,
      decisionsToday: json['decisions_today'] as int? ?? 0,
      correctDecisions: json['correct_decisions'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      xpEarnedTotal: json['xp_earned_total'] as int? ?? 0,
    );
  }

  /// XP needed to reach the next level, derived from the backend's own curve
  /// of 100 XP per level. Derived, not counted: [xp] is the only input.
  int get xpForNextLevel => level * 100;

  /// How much of the current level is done, 0..1.
  double get levelProgress => ((xp % 100) / 100).clamp(0.0, 1.0);

  /// XP still to earn before the next level.
  int get xpToNextLevel => 100 - (xp % 100);

  /// Empty/default progress used before the first load completes.
  static const ProgressDto empty = ProgressDto(xp: 0, level: 1, streakCount: 0);
}
