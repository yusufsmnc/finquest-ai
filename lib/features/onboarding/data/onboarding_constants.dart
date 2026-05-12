/// OnboardingConstants — all hardcoded tutorial scenario data (CR-001).
/// No logic lives here — pure data.
class OnboardingConstants {
  OnboardingConstants._();

  // Scenario metadata
  static const String scenarioId = 'CR-001';
  static const String scenarioTitle = 'Market Crash Alert';
  static const String scenarioDescription =
      'The stock market dropped 10% today. You have \$1,000 in your '
      'investment portfolio. What do you do?';
  static const String riskLevel = 'Medium';

  // Decision options
  static const String optionAId = 'A';
  static const String optionAText =
      'Hold steady — market crashes are temporary';
  static const bool optionAIsCorrect = true;

  static const String optionBId = 'B';
  static const String optionBText = 'Sell everything immediately to avoid losses';
  static const bool optionBIsCorrect = false;

  // Mentor feedback
  static const String mentorCorrectFeedback =
      'Great decision! Panic selling locks in losses. '
      'Long-term investors stay the course.';
  static const String mentorWrongFeedback =
      'No worries! Selling during a crash locks in losses. '
      'Holding lets you recover when markets rebound.';

  // Gamification
  static const int xpCorrect = 50;
  static const int xpWrong = 10;
  static const int xpMax = 100; // Anti-exploit ceiling: max XP per action
  static const int xpForLevelUp = 100; // XP needed for level 1
  static const int startingLevel = 1;
  static const int levelAfterOnboarding = 2;
  static const int streakAfterOnboarding = 1;

  // Reward
  static const String rewardId = 'badge_novice';
  static const String rewardLabel = 'Novice Investor Badge';

  // Unlocked rewards shown on S5
  static const List<Map<String, String>> unlockedRewards = [
    {
      'icon': 'dashboard',
      'label': 'Dashboard Access',
      'sublabel': 'Explore your financial hub',
    },
    {
      'icon': 'scenario',
      'label': 'First Scenario Set',
      'sublabel': '5 new financial challenges',
    },
  ];

  // Total onboarding steps
  static const int totalSteps = 5;
}