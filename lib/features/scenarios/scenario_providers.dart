import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/scenario_event_dispatcher.dart';
import 'application/scenario_notifier.dart';
import 'domain/scenario_state.dart';

final scenarioNotifierProvider =
    NotifierProvider<ScenarioNotifier, ScenarioState>(
  ScenarioNotifier.new,
);

final scenarioDispatcherProvider = Provider<ScenarioEventDispatcher>((ref) {
  final notifier = ref.read(scenarioNotifierProvider.notifier);
  return ScenarioEventDispatcher(notifier);
});