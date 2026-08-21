import 'package:flutter/material.dart';

enum MarketImpact { low, medium, high }

extension MarketImpactX on MarketImpact {
  String get label {
    switch (this) {
      case MarketImpact.low:
        return 'Low Impact';
      case MarketImpact.medium:
        return 'Medium Impact';
      case MarketImpact.high:
        return 'High Impact';
    }
  }

  Color get color {
    switch (this) {
      case MarketImpact.low:
        return const Color(0xFF059669);
      case MarketImpact.medium:
        return const Color(0xFFF59E0B);
      case MarketImpact.high:
        return const Color(0xFFDC2626);
    }
  }

  IconData get icon {
    switch (this) {
      case MarketImpact.low:
        return Icons.trending_up_rounded;
      case MarketImpact.medium:
        return Icons.show_chart_rounded;
      case MarketImpact.high:
        return Icons.warning_amber_rounded;
    }
  }
}

class MarketEvent {
  final String id;
  final String title;
  final String headline;
  final String description;
  final String category;
  final MarketImpact impact;
  final DateTime timestamp;

  const MarketEvent({
    required this.id,
    required this.title,
    required this.headline,
    required this.description,
    required this.category,
    required this.impact,
    required this.timestamp,
  });
}