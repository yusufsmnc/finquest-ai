import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/dashboard_event_dispatcher.dart';
import 'application/dashboard_notifier.dart';
import 'domain/dashboard_state.dart';
import '../gamification/gamification_providers.dart';
import '../achievements/achievements_providers.dart';
import '../ai_mentor/ai_mentor_providers.dart';

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

final dashboardDispatcherProvider = Provider<DashboardEventDispatcher>((ref) {
  final notifier = ref.read(dashboardNotifierProvider.notifier);
  final overlayNotifier = ref.read(gamificationOverlayProvider.notifier);
  final achievementsNotifier = ref.read(achievementsNotifierProvider.notifier);
  final mentorNotifier = ref.read(aiMentorProvider.notifier);
  return DashboardEventDispatcher(
      notifier, overlayNotifier, achievementsNotifier, mentorNotifier);
});