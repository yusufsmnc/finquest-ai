import 'package:flutter/material.dart';
import '../domain/dashboard_state.dart';

class DashboardConstants {
  DashboardConstants._();

  static const int xpPerLevel = 100;
  static const int maxLevel = 50;

  static const List<String> mentorInsights = [
    'Market downturns are normal — staying invested historically beats panic selling.',
    'Diversification isn\'t about owning many things; it\'s about owning things that don\'t move together.',
    'Your emergency fund is your first investment. Aim for 3–6 months of expenses.',
    'Compound interest works best with time — starting early beats starting big.',
  ];

  static List<DashboardChallenge> seedChallenges() => const [
        DashboardChallenge(
          id: 'daily_decision',
          title: 'Daily Decision',
          subtitle: 'Make 3 financial decisions',
          progress: 1,
          target: 3,
          xpReward: 30,
          icon: Icons.bolt_rounded,
          color: Color(0xFF2563EB),
        ),
        DashboardChallenge(
          id: 'streak_master',
          title: 'Streak Master',
          subtitle: 'Keep a 7-day streak',
          progress: 1,
          target: 7,
          xpReward: 70,
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFF59E0B),
        ),
        DashboardChallenge(
          id: 'risk_analyst',
          title: 'Risk Analyst',
          subtitle: 'Complete 5 risk scenarios',
          progress: 0,
          target: 5,
          xpReward: 50,
          icon: Icons.analytics_rounded,
          color: Color(0xFF0EA5E9),
        ),
      ];

  static List<DashboardAchievement> seedAchievements() => const [
        DashboardAchievement(
          id: 'badge_novice',
          label: 'Novice Investor',
          unlocked: true,
        ),
        DashboardAchievement(
          id: 'badge_investor',
          label: 'Investor',
          unlocked: false,
        ),
        DashboardAchievement(
          id: 'badge_expert',
          label: 'Expert',
          unlocked: false,
        ),
        DashboardAchievement(
          id: 'badge_master',
          label: 'Master',
          unlocked: false,
        ),
      ];

  static List<DashboardCategory> seedCategories() => const [
        DashboardCategory(
          name: 'Budgeting',
          progress: 0.65,
          color: Color(0xFF2563EB),
          icon: Icons.account_balance_wallet_rounded,
        ),
        DashboardCategory(
          name: 'Investing',
          progress: 0.40,
          color: Color(0xFF16A34A),
          icon: Icons.trending_up_rounded,
        ),
        DashboardCategory(
          name: 'Savings',
          progress: 0.80,
          color: Color(0xFF0EA5E9),
          icon: Icons.savings_rounded,
        ),
        DashboardCategory(
          name: 'Risk Management',
          progress: 0.30,
          color: Color(0xFFF59E0B),
          icon: Icons.shield_rounded,
        ),
      ];
}