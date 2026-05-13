import 'package:flutter/material.dart';

class AvatarOption {
  final Color primary;
  final Color secondary;
  final IconData icon;
  final String label;

  const AvatarOption({
    required this.primary,
    required this.secondary,
    required this.icon,
    required this.label,
  });
}

class AvatarData {
  static const List<AvatarOption> options = [
    AvatarOption(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF1D4ED8),
      icon: Icons.trending_up_rounded,
      label: 'Investor',
    ),
    AvatarOption(
      primary: Color(0xFF059669),
      secondary: Color(0xFF047857),
      icon: Icons.savings_rounded,
      label: 'Saver',
    ),
    AvatarOption(
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFD97706),
      icon: Icons.bolt_rounded,
      label: 'Risk Taker',
    ),
    AvatarOption(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF6D28D9),
      icon: Icons.psychology_rounded,
      label: 'Strategist',
    ),
    AvatarOption(
      primary: Color(0xFF0EA5E9),
      secondary: Color(0xFF0284C7),
      icon: Icons.bar_chart_rounded,
      label: 'Analyst',
    ),
    AvatarOption(
      primary: Color(0xFFDC2626),
      secondary: Color(0xFFB91C1C),
      icon: Icons.local_fire_department_rounded,
      label: 'Achiever',
    ),
    AvatarOption(
      primary: Color(0xFF0D9488),
      secondary: Color(0xFF0F766E),
      icon: Icons.account_balance_rounded,
      label: 'Banker',
    ),
    AvatarOption(
      primary: Color(0xFFCA8A04),
      secondary: Color(0xFFB45309),
      icon: Icons.emoji_events_rounded,
      label: 'Champion',
    ),
  ];
}