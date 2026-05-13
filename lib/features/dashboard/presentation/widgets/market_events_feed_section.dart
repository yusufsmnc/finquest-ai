import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/app_router.dart';
import '../../../market_events/market_events_providers.dart';
import '../../../market_events/domain/market_event.dart';
import '../../../market_events/presentation/widgets/market_event_card.dart';
import '../../../market_events/presentation/widgets/market_event_detail_modal.dart';

class MarketEventsFeedSection extends ConsumerWidget {
  const MarketEventsFeedSection({super.key});

  void _actNow(BuildContext context, WidgetRef ref, MarketEvent event) {
    ref.read(marketEventsProvider.notifier).setActiveEvent(event.id);
    Navigator.of(context).pushNamed(
      AppRoutes.scenarios,
      arguments: event.category,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEvents = ref.watch(
      marketEventsProvider.select((s) => s.activeEvents),
    );

    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final visible = activeEvents.take(4).toList();

    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final event = visible[i];
          return MarketEventCard(
            event: event,
            isResolved: false,
            onTap: () => MarketEventDetailModal.show(
              context,
              event: event,
              isResolved: false,
              onActNow: () => _actNow(context, ref, event),
            ),
            onActNow: () => _actNow(context, ref, event),
          );
        },
      ),
    );
  }
}