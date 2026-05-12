import 'package:flutter/material.dart';

class DashboardChallenge {
  final String id;
  final String title;
  final String subtitle;
  final int progress;
  final int target;
  final int xpReward;
  final IconData icon;
  final Color color;

  const DashboardChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.icon,
    required this.color,
  });

  double get progressFraction => (progress / target).clamp(0.0, 1.0);
  bool get isComplete => progress >= target;

  DashboardChallenge copyWith({int? progress}) {
    return DashboardChallenge(
      id: id,
      title: title,
      subtitle: subtitle,
      progress: progress ?? this.progress,
      target: target,
      xpReward: xpReward,
      icon: icon,
      color: color,
    );
  }
}

class DashboardAchievement {
  final String id;
  final String label;
  final bool unlocked;

  const DashboardAchievement({
    required this.id,
    required this.label,
    required this.unlocked,
  });

  DashboardAchievement copyWith({bool? unlocked}) {
    return DashboardAchievement(
      id: id,
      label: label,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

class DashboardCategory {
  final String name;
  final double progress;
  final Color color;
  final IconData icon;

  const DashboardCategory({
    required this.name,
    required this.progress,
    required this.color,
    required this.icon,
  });
}

class DashboardPortfolio {
  final double value;
  final double changePercent;
  final List<double> sparkline;

  const DashboardPortfolio({
    required this.value,
    required this.changePercent,
    required this.sparkline,
  });

  bool get isPositive => changePercent >= 0;
}

class DashboardState {
  final int currentLevel;
  final int currentXP;
  final int xpToNextLevel;
  final int currentStreak;
  final int totalScenarios;
  final List<DashboardChallenge> challenges;
  final List<DashboardAchievement> achievements;
  final List<DashboardCategory> categories;
  final DashboardPortfolio portfolio;
  final String mentorInsight;
  final bool showXpFloat;
  final int lastXpGained;
  final bool streakPulse;

  const DashboardState({
    this.currentLevel = 2,
    this.currentXP = 60,
    this.xpToNextLevel = 100,
    this.currentStreak = 1,
    this.totalScenarios = 1,
    this.challenges = const [],
    this.achievements = const [],
    this.categories = const [],
    this.portfolio = const DashboardPortfolio(
      value: 1247.50,
      changePercent: 3.2,
      sparkline: [1180, 1195, 1210, 1198, 1225, 1235, 1247.5],
    ),
    this.mentorInsight =
        'Market downturns are normal — staying invested historically beats panic selling.',
    this.showXpFloat = false,
    this.lastXpGained = 0,
    this.streakPulse = false,
  });

  double get xpProgress => (currentXP / xpToNextLevel).clamp(0.0, 1.0);
  int get xpRemaining => xpToNextLevel - currentXP;

  DashboardState copyWith({
    int? currentLevel,
    int? currentXP,
    int? xpToNextLevel,
    int? currentStreak,
    int? totalScenarios,
    List<DashboardChallenge>? challenges,
    List<DashboardAchievement>? achievements,
    List<DashboardCategory>? categories,
    DashboardPortfolio? portfolio,
    String? mentorInsight,
    bool? showXpFloat,
    int? lastXpGained,
    bool? streakPulse,
  }) {
    return DashboardState(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXP: currentXP ?? this.currentXP,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      totalScenarios: totalScenarios ?? this.totalScenarios,
      challenges: challenges ?? this.challenges,
      achievements: achievements ?? this.achievements,
      categories: categories ?? this.categories,
      portfolio: portfolio ?? this.portfolio,
      mentorInsight: mentorInsight ?? this.mentorInsight,
      showXpFloat: showXpFloat ?? this.showXpFloat,
      lastXpGained: lastXpGained ?? this.lastXpGained,
      streakPulse: streakPulse ?? this.streakPulse,
    );
  }
}