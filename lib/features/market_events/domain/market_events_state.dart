import 'market_event.dart';

class MarketEventsState {
  final List<MarketEvent> events;
  final Set<String> resolvedIds;
  final String? activeEventId;

  const MarketEventsState({
    this.events = const [],
    this.resolvedIds = const {},
    this.activeEventId,
  });

  List<MarketEvent> get activeEvents =>
      events.where((e) => !resolvedIds.contains(e.id)).toList();

  List<MarketEvent> get resolvedEvents =>
      events.where((e) => resolvedIds.contains(e.id)).toList();

  int get activeCount => activeEvents.length;

  MarketEventsState copyWith({
    List<MarketEvent>? events,
    Set<String>? resolvedIds,
    String? activeEventId,
    bool clearActiveEventId = false,
  }) {
    return MarketEventsState(
      events: events ?? this.events,
      resolvedIds: resolvedIds ?? this.resolvedIds,
      activeEventId:
          clearActiveEventId ? null : (activeEventId ?? this.activeEventId),
    );
  }
}