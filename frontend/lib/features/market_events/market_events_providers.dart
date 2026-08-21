import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/market_events_notifier.dart';
import 'domain/market_events_state.dart';

final marketEventsProvider =
    NotifierProvider<MarketEventsNotifier, MarketEventsState>(
  MarketEventsNotifier.new,
);