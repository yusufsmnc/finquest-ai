import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/dashboard_event_dispatcher.dart';
import 'application/dashboard_notifier.dart';
import 'domain/dashboard_state.dart';

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

final dashboardDispatcherProvider = Provider<DashboardEventDispatcher>((ref) {
  final notifier = ref.read(dashboardNotifierProvider.notifier);
  return DashboardEventDispatcher(notifier);
});