import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/scenario_event_dispatcher.dart';
import 'application/scenario_notifier.dart';
import 'domain/scenario_state.dart';
import '../gamification/gamification_providers.dart';
import '../achievements/achievements_providers.dart';

final scenarioNotifierProvider =
    NotifierProvider<ScenarioNotifier, ScenarioState>(
  ScenarioNotifier.new,
);

final scenarioDispatcherProvider = Provider<ScenarioEventDispatcher>((ref) {
  final notifier = ref.read(scenarioNotifierProvider.notifier);
  final overlayNotifier = ref.read(gamificationOverlayProvider.notifier);
  final achievementsNotifier = ref.read(achievementsNotifierProvider.notifier);
  return ScenarioEventDispatcher(notifier, overlayNotifier, achievementsNotifier);
});