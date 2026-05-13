import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../market_events_providers.dart';
import '../domain/market_event.dart';
import 'widgets/market_event_card.dart';
import 'widgets/market_event_detail_modal.dart';

class MarketEventsScreen extends ConsumerStatefulWidget {
  const MarketEventsScreen({super.key});

  @override
  ConsumerState<MarketEventsScreen> createState() => _MarketEventsScreenState();
}

class _MarketEventsScreenState extends ConsumerState<MarketEventsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _entryController.value = 1;
        } else {
          _entryController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _actNow(BuildContext context, MarketEvent event) {
    ref.read(marketEventsProvider.notifier).setActiveEvent(event.id);
    Navigator.of(context).pushNamed(
      AppRoutes.scenarios,
      arguments: event.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketEventsProvider);
    final activeEvents = marketState.activeEvents;
    final resolvedEvents = marketState.resolvedEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: true,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  const Text(
                    'Market Events',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (activeEvents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${activeEvents.length} LIVE',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (activeEvents.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    'Active Events',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final event = activeEvents[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketEventCard(
                          event: event,
                          isResolved: false,
                          onTap: () => MarketEventDetailModal.show(
                            context,
                            event: event,
                            isResolved: false,
                            onActNow: () => _actNow(context, event),
                          ),
                          onActNow: () => _actNow(context, event),
                        ),
                      );
                    },
                    childCount: activeEvents.length,
                  ),
                ),
              ),
            ],
            if (resolvedEvents.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Resolved',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final event = resolvedEvents[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketEventCard(
                          event: event,
                          isResolved: true,
                          onTap: () => MarketEventDetailModal.show(
                            context,
                            event: event,
                            isResolved: true,
                          ),
                        ),
                      );
                    },
                    childCount: resolvedEvents.length,
                  ),
                ),
              ),
            ],
            if (activeEvents.isEmpty && resolvedEvents.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No events at this time.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}