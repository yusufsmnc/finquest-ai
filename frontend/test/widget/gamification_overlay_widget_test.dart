/// Widget-level proof of the unlock UX: the achievement overlay is actually
/// *rendered* once on unlock, and is NOT rendered again after a restart where
/// the backend already reports the achievement as owned.
///
/// This is the layer the original bug showed up on, so it is asserted against
/// real widgets rather than notifier state alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/core/events/game_event.dart';
import 'package:finquest_ai/data/dtos/achievement_dto.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/achievements/achievements_providers.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/gamification/presentation/gamification_overlay_manager.dart';
import 'package:finquest_ai/features/gamification/presentation/widgets/achievement_unlock_overlay.dart';
import 'package:finquest_ai/features/gamification/presentation/widgets/gamification_toast_queue.dart';
import 'package:finquest_ai/features/gamification/presentation/widgets/level_up_modal.dart';
import 'package:finquest_ai/features/gamification/presentation/widgets/xp_lost_overlay.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import '../support/test_harness.dart';

/// Pumps the overlay host over a trivial screen, driven by [container].
Future<void> pumpOverlayHost(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: GamificationOverlayManager(child: SizedBox.expand()),
        ),
      ),
    ),
  );
}

/// Resolves the async providers a real session loads before the user can act.
/// Uses [tester] pumps instead of raw `Future.delayed`, which would stall under
/// the widget tester's fake clock.
Future<void> warmUpUi(WidgetTester tester, ProviderContainer c) async {
  await c.read(authProvider.future);
  await c.read(progressProvider.future);
  c.listen(achievementsNotifierProvider, (_, __) {});
  await c.read(unlockedAchievementCodesProvider.future);
  await tester.pump();
}

/// Advances past the overlays' self-dismiss timers so no timer is left pending.
Future<void> drainOverlayTimers(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  setUp(SpyScenarioNotifier.reset);

  testWidgets(
      'unlock renders the achievement overlay + reward toast exactly '
      'once, plus the level-up modal', (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 20,
        progress: const ProgressDto(
          xp: 100,
          level: 2,
          streakCount: 5,
          decisionsMade: 5,
          decisionsToday: 5,
        ),
        newAchievements: const ['streak_5'],
      ),
    );
    addTearDown(container.dispose);

    await pumpOverlayHost(tester, container);
    await warmUpUi(tester, container);

    // Nothing showing before the user acts.
    expect(find.byType(AchievementUnlockOverlay), findsNothing);
    expect(find.byType(LevelUpModal), findsNothing);

    // Fire the decision; do not await (the dispatcher holds a 1.5s animation
    // delay) — pump instead so the widget tree processes the events.
    unawaitedDecision(container, 'emergency-fund', 'opt_a', true);
    await tester.pump();

    expect(find.byType(AchievementUnlockOverlay), findsOneWidget,
        reason: 'unlock overlay rendered exactly once');
    expect(find.byType(GamificationToastQueue), findsOneWidget);
    expect(find.byType(LevelUpModal), findsOneWidget,
        reason: 'threshold crossed → LEVEL_UP rendered');
    expect(find.byType(XpLostOverlay), findsNothing);
    expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1);

    // The unlocked title is on screen (backend code → frontend label).
    expect(find.text('Unstoppable'), findsOneWidget);

    await drainOverlayTimers(tester);
  });

  testWidgets('after the overlay self-dismisses it does not come back',
      (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 20,
        progress: const ProgressDto(xp: 100, level: 1, streakCount: 5),
        newAchievements: const ['streak_5'],
      ),
    );
    addTearDown(container.dispose);

    await pumpOverlayHost(tester, container);
    await warmUpUi(tester, container);

    unawaitedDecision(container, 'emergency-fund', 'opt_a', true);
    await tester.pump();
    expect(find.byType(AchievementUnlockOverlay), findsOneWidget);

    await drainOverlayTimers(tester);

    expect(find.byType(AchievementUnlockOverlay), findsNothing,
        reason: 'self-dismissed');
    expect(find.byType(GamificationToastQueue), findsNothing,
        reason: 'toast queue drained');
    // And it stays gone.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(AchievementUnlockOverlay), findsNothing);
    expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1);
  });

  testWidgets(
      'RESTART: achievement already owned by the backend renders as '
      'unlocked WITHOUT any overlay replay', (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
      initialAchievements: const [AchievementDto(code: 'streak_5')],
      decisionResult: correctDecision(
        xpDelta: 0,
        progress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
      ),
    );
    addTearDown(container.dispose);

    await pumpOverlayHost(tester, container);
    await warmUpUi(tester, container);

    // State restored…
    expect(unlockedCodes(container), contains('streak_5'));

    // …and no celebration replays, now or after the animation windows.
    expect(find.byType(AchievementUnlockOverlay), findsNothing);
    expect(find.byType(GamificationToastQueue), findsNothing);
    expect(find.byType(LevelUpModal), findsNothing);

    await drainOverlayTimers(tester);

    expect(find.byType(AchievementUnlockOverlay), findsNothing,
        reason: 'REWARD_UNLOCKED must not be re-emitted on reload');
    expect(SpyScenarioNotifier.recorded, isEmpty);
  });

  testWidgets('wrong decision renders XP-lost feedback, no unlock overlay',
      (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
      initialAchievements: const [AchievementDto(code: 'streak_5')],
      decisionResult: wrongDecision(
        xpDelta: -10,
        progress: const ProgressDto(xp: 90, level: 2, streakCount: 0),
      ),
    );
    addTearDown(container.dispose);

    await pumpOverlayHost(tester, container);
    await warmUpUi(tester, container);

    final before = unlockedCodes(container);
    expect(before, contains('streak_5'));

    unawaitedDecision(container, 'risk-101', 'opt_b', false);
    await tester.pump();

    expect(find.byType(XpLostOverlay), findsOneWidget);
    expect(find.byType(AchievementUnlockOverlay), findsNothing);
    expect(find.byType(LevelUpModal), findsNothing);

    // Streak reset, but the badge is permanent.
    expect(container.read(progressProvider).value!.streakCount, 0);
    expect(unlockedCodes(container), containsAll(before));

    await drainOverlayTimers(tester);
  });
}

/// Fires a decision without awaiting it (the dispatcher parks on a 1.5s
/// animation delay that the widget tester advances via `pump`).
void unawaitedDecision(
  ProviderContainer container,
  String scenarioId,
  String optionId,
  bool correct,
) {
  // ignore: discarded_futures
  container
      .read(scenarioDispatcherProvider)
      .onDecisionMade(scenarioId, optionId, correct);
}
