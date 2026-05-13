import 'package:flutter/material.dart';

class GamificationToastData {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const GamificationToastData({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class GamificationOverlayState {
  final bool showLevelUp;
  final int levelUpValue;
  final bool showXpLost;
  final int xpLostAmount;
  final bool showStreakFeedback;
  final int streakValue;
  final bool showAchievementUnlock;
  final String achievementName;
  final List<GamificationToastData> toastQueue;
  final int trackedXp;
  final int trackedLevel;

  const GamificationOverlayState({
    this.showLevelUp = false,
    this.levelUpValue = 1,
    this.showXpLost = false,
    this.xpLostAmount = 0,
    this.showStreakFeedback = false,
    this.streakValue = 0,
    this.showAchievementUnlock = false,
    this.achievementName = '',
    this.toastQueue = const [],
    this.trackedXp = 0,
    this.trackedLevel = 1,
  });

  static int levelForXp(int xp) => (xp ~/ 200) + 1;

  GamificationOverlayState copyWith({
    bool? showLevelUp,
    int? levelUpValue,
    bool? showXpLost,
    int? xpLostAmount,
    bool? showStreakFeedback,
    int? streakValue,
    bool? showAchievementUnlock,
    String? achievementName,
    List<GamificationToastData>? toastQueue,
    int? trackedXp,
    int? trackedLevel,
  }) {
    return GamificationOverlayState(
      showLevelUp: showLevelUp ?? this.showLevelUp,
      levelUpValue: levelUpValue ?? this.levelUpValue,
      showXpLost: showXpLost ?? this.showXpLost,
      xpLostAmount: xpLostAmount ?? this.xpLostAmount,
      showStreakFeedback: showStreakFeedback ?? this.showStreakFeedback,
      streakValue: streakValue ?? this.streakValue,
      showAchievementUnlock: showAchievementUnlock ?? this.showAchievementUnlock,
      achievementName: achievementName ?? this.achievementName,
      toastQueue: toastQueue ?? this.toastQueue,
      trackedXp: trackedXp ?? this.trackedXp,
      trackedLevel: trackedLevel ?? this.trackedLevel,
    );
  }
}