/// Authoritative progress as returned by the backend (`GET /me/progress`).
///
/// XP / level / streak are computed by the backend — the frontend never
/// derives them. `level` here is the source of truth; the UI only formats it.
class ProgressDto {
  final int xp;
  final int level;
  final int streakCount;
  final DateTime? lastActive;
  // Derived counts (backend-computed from scenario_history) that drive
  // mission/achievement progress bars — the UI never counts these itself.
  final int decisionsMade;
  final int decisionsToday;

  const ProgressDto({
    required this.xp,
    required this.level,
    required this.streakCount,
    this.lastActive,
    this.decisionsMade = 0,
    this.decisionsToday = 0,
  });

  factory ProgressDto.fromJson(Map<String, dynamic> json) {
    final rawLastActive = json['last_active'] as String?;
    return ProgressDto(
      xp: json['xp'] as int,
      level: json['level'] as int,
      streakCount: json['streak_count'] as int,
      lastActive:
          rawLastActive == null ? null : DateTime.tryParse(rawLastActive),
      decisionsMade: json['decisions_made'] as int? ?? 0,
      decisionsToday: json['decisions_today'] as int? ?? 0,
    );
  }

  /// Empty/default progress used before the first load completes.
  static const ProgressDto empty =
      ProgressDto(xp: 0, level: 1, streakCount: 0);
}