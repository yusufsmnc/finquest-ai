import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../data/dashboard_constants.dart';
import '../domain/dashboard_gamification_handler.dart';
import '../domain/dashboard_state.dart';

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return DashboardState(
      challenges: DashboardConstants.seedChallenges(),
      achievements: DashboardConstants.seedAchievements(),
      categories: DashboardConstants.seedCategories(),
      mentorInsight: DashboardConstants.mentorInsights.first,
    );
  }

  void applyEvent(GameEvent event) {
    state = DashboardGamificationHandler.apply(state, event);
  }

  void dismissXpFloat() => state = state.copyWith(showXpFloat: false);
  void dismissStreakPulse() => state = state.copyWith(streakPulse: false);
}