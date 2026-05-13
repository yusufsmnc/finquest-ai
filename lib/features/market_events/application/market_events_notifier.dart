import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/game_event.dart';
import '../data/market_events_repository.dart';
import '../domain/market_events_state.dart';

class MarketEventsNotifier extends Notifier<MarketEventsState> {
  @override
  MarketEventsState build() {
    return MarketEventsState(events: MarketEventsRepository.all);
  }

  void setActiveEvent(String eventId) {
    state = state.copyWith(activeEventId: eventId);
  }

  void applyEvent(GameEvent event) {
    if (event.type == GameEventType.decisionMade) {
      if (state.activeEventId != null) {
        state = state.copyWith(
          resolvedIds: {...state.resolvedIds, state.activeEventId!},
          clearActiveEventId: true,
        );
      }
    }
  }

  MarketEventsState get currentState => state;
}