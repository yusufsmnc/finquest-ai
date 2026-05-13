import 'achievement_model.dart';

class AchievementsState {
  final List<Achievement> achievements;
  final int trackedXp;
  final int trackedStreak;
  final int trackedCorrectDecisions;
  final int trackedLevel;
  final AchievementCategory? filterCategory;
  final Achievement? lastUnlocked;

  const AchievementsState({
    this.achievements = const [],
    this.trackedXp = 0,
    this.trackedStreak = 0,
    this.trackedCorrectDecisions = 0,
    this.trackedLevel = 1,
    this.filterCategory,
    this.lastUnlocked,
  });

  List<Achievement> get filteredAchievements {
    if (filterCategory == null) return achievements;
    return achievements.where((a) => a.category == filterCategory).toList();
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
  int get totalCount => achievements.length;
  double get completionPercent =>
      totalCount == 0 ? 0.0 : (unlockedCount / totalCount).clamp(0.0, 1.0);

  AchievementsState copyWith({
    List<Achievement>? achievements,
    int? trackedXp,
    int? trackedStreak,
    int? trackedCorrectDecisions,
    int? trackedLevel,
    AchievementCategory? filterCategory,
    bool clearFilter = false,
    Achievement? lastUnlocked,
    bool clearLastUnlocked = false,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      trackedXp: trackedXp ?? this.trackedXp,
      trackedStreak: trackedStreak ?? this.trackedStreak,
      trackedCorrectDecisions:
          trackedCorrectDecisions ?? this.trackedCorrectDecisions,
      trackedLevel: trackedLevel ?? this.trackedLevel,
      filterCategory:
          clearFilter ? null : (filterCategory ?? this.filterCategory),
      lastUnlocked:
          clearLastUnlocked ? null : (lastUnlocked ?? this.lastUnlocked),
    );
  }
}