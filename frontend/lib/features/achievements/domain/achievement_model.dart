import 'package:flutter/material.dart';

enum AchievementRarity { common, rare, epic, legendary }

enum AchievementCategory { streak, xp, decisions, level }

extension AchievementRarityExt on AchievementRarity {
  String get label {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFF64748B);
      case AchievementRarity.rare:
        return const Color(0xFF2563EB);
      case AchievementRarity.epic:
        return const Color(0xFF7C3AED);
      case AchievementRarity.legendary:
        return const Color(0xFFF59E0B);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFFF1F5F9);
      case AchievementRarity.rare:
        return const Color(0xFFEFF6FF);
      case AchievementRarity.epic:
        return const Color(0xFFF5F3FF);
      case AchievementRarity.legendary:
        return const Color(0xFFFFFBEB);
    }
  }
}

extension AchievementCategoryExt on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.xp:
        return 'XP';
      case AchievementCategory.decisions:
        return 'Decisions';
      case AchievementCategory.level:
        return 'Level';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.streak:
        return Icons.local_fire_department_rounded;
      case AchievementCategory.xp:
        return Icons.star_rounded;
      case AchievementCategory.decisions:
        return Icons.psychology_rounded;
      case AchievementCategory.level:
        return Icons.trending_up_rounded;
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final IconData icon;
  final int requiredValue;
  final bool unlocked;
  final int currentProgress;
  final DateTime? unlockedAt;
  final String rewardDescription;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.category,
    required this.icon,
    required this.requiredValue,
    this.unlocked = false,
    this.currentProgress = 0,
    this.unlockedAt,
    required this.rewardDescription,
  });

  double get progressFraction =>
      unlocked ? 1.0 : (currentProgress / requiredValue).clamp(0.0, 1.0);

  Achievement copyWith({
    bool? unlocked,
    int? currentProgress,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      rarity: rarity,
      category: category,
      icon: icon,
      requiredValue: requiredValue,
      unlocked: unlocked ?? this.unlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rewardDescription: rewardDescription,
    );
  }
}