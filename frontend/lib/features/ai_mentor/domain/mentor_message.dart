import 'package:flutter/material.dart';

enum MentorMood { calm, happy, encouraging, excited, proud, thinking }

enum MentorContext {
  idle,
  decisionCorrect,
  decisionWrong,
  levelUp,
  streakMilestone,
  achievementUnlock,
  categoryBudgeting,
  categoryInvesting,
  categorySavings,
  categoryRisk,
  nextStep,
  onboarding,
  newUser,
  firstWin,
  streakHigh,
  highAccuracy,
}

extension MentorMoodExt on MentorMood {
  String get label {
    switch (this) {
      case MentorMood.calm:        return 'Ready to guide';
      case MentorMood.happy:       return 'Great decision!';
      case MentorMood.encouraging: return 'Keep going';
      case MentorMood.excited:     return 'Level up!';
      case MentorMood.proud:       return 'Well earned';
      case MentorMood.thinking:    return 'Analyzing...';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case MentorMood.calm:
        return [const Color(0xFF7C3AED), const Color(0xFF0EA5E9)];
      case MentorMood.happy:
        return [const Color(0xFF059669), const Color(0xFF10B981)];
      case MentorMood.encouraging:
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
      case MentorMood.excited:
        return [const Color(0xFF7C3AED), const Color(0xFFEC4899)];
      case MentorMood.proud:
        return [const Color(0xFFCA8A04), const Color(0xFFF59E0B)];
      case MentorMood.thinking:
        return [const Color(0xFF4338CA), const Color(0xFF7C3AED)];
    }
  }

  IconData get icon {
    switch (this) {
      case MentorMood.calm:        return Icons.psychology_rounded;
      case MentorMood.happy:       return Icons.check_circle_rounded;
      case MentorMood.encouraging: return Icons.favorite_rounded;
      case MentorMood.excited:     return Icons.auto_awesome_rounded;
      case MentorMood.proud:       return Icons.emoji_events_rounded;
      case MentorMood.thinking:    return Icons.lightbulb_rounded;
    }
  }
}

extension MentorContextExt on MentorContext {
  String get displayLabel {
    switch (this) {
      case MentorContext.idle:             return 'Daily Insight';
      case MentorContext.decisionCorrect:  return 'Correct Decision';
      case MentorContext.decisionWrong:    return 'Learning Moment';
      case MentorContext.levelUp:          return 'Level Up';
      case MentorContext.streakMilestone:  return 'Streak';
      case MentorContext.achievementUnlock:return 'Achievement';
      case MentorContext.categoryBudgeting:return 'Budgeting';
      case MentorContext.categoryInvesting:return 'Investing';
      case MentorContext.categorySavings:  return 'Savings';
      case MentorContext.categoryRisk:     return 'Risk';
      case MentorContext.nextStep:         return 'Next Step';
      case MentorContext.onboarding:       return 'Welcome';
      case MentorContext.newUser:          return 'Getting Started';
      case MentorContext.firstWin:         return 'First Win';
      case MentorContext.streakHigh:       return 'On Fire';
      case MentorContext.highAccuracy:     return 'Sharp Mind';
    }
  }

  static MentorContext fromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'budgeting':  return MentorContext.categoryBudgeting;
      case 'investing':  return MentorContext.categoryInvesting;
      case 'savings':    return MentorContext.categorySavings;
      case 'risk':
      case 'risk management': return MentorContext.categoryRisk;
      default:           return MentorContext.idle;
    }
  }
}

class MentorMessage {
  final String id;
  final String text;
  final MentorMood mood;
  final MentorContext context;
  final DateTime timestamp;

  const MentorMessage({
    required this.id,
    required this.text,
    required this.mood,
    required this.context,
    required this.timestamp,
  });
}