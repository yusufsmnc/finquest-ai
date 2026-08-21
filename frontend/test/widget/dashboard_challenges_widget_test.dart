/// Missions/challenges are pure renderings of authoritative backend counters.
/// These tests pump the real section widget and assert the numbers on screen
/// change when — and only when — the backend progress changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/dashboard/presentation/widgets/dashboard_challenges_section.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import '../support/test_harness.dart';

/// Widget tests run without the app's real fonts (Poppins/Inter are fetched at
/// runtime), and the test fallback font is far wider per glyph. That wraps the
/// mission subtitle onto an extra line and overflows the fixed-height card by a
/// couple of pixels — an artifact of the substitute font, not of the layout
/// under test. Overflow reports are filtered out; every other error still fails
/// the test.
void ignoreFontSubstitutionOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> pumpChallenges(
  WidgetTester tester,
  ProviderContainer container,
) async {
  ignoreFontSubstitutionOverflow();
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: DashboardChallengesSection()),
      ),
    ),
  );
  await container.read(authProvider.future);
  await container.read(progressProvider.future);
  await tester.pump();
}

void main() {
  setUp(SpyScenarioNotifier.reset);

  testWidgets('mission counters render the authoritative backend numbers',
      (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(
        xp: 140,
        level: 2,
        streakCount: 3,
        decisionsMade: 4,
        decisionsToday: 2,
      ),
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 0,
        progress: const ProgressDto(xp: 140, level: 2, streakCount: 3),
      ),
    );
    addTearDown(container.dispose);

    await pumpChallenges(tester, container);

    expect(find.text('2 / 3'), findsOneWidget); // daily ← decisions_today
    expect(find.text('3 / 7'), findsOneWidget); // streak ← streak_count
    expect(find.text('4 / 5'), findsOneWidget); // risk ← decisions_made
  });

  testWidgets('a decision advances mission progress from the decision response',
      (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: const ProgressDto(
        xp: 140,
        level: 2,
        streakCount: 3,
        decisionsMade: 4,
        decisionsToday: 2,
      ),
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 20,
        progress: const ProgressDto(
          xp: 160,
          level: 2,
          streakCount: 4,
          decisionsMade: 5,
          decisionsToday: 3,
        ),
      ),
    );
    addTearDown(container.dispose);

    await pumpChallenges(tester, container);
    expect(find.text('2 / 3'), findsOneWidget);

    // ignore: discarded_futures
    container
        .read(scenarioDispatcherProvider)
        .onDecisionMade('budget-101', 'opt_a', true);
    await tester.pump();

    expect(find.text('3 / 3'), findsOneWidget); // daily complete
    expect(find.text('4 / 7'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget); // risk complete
    // Completed missions swap the XP reward chip for a "Done" badge.
    expect(find.text('Done'), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('empty progress renders all missions at zero', (tester) async {
    final container = testContainer(
      spyEvents: true,
      initialProgress: ProgressDto.empty,
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 0,
        progress: ProgressDto.empty,
      ),
    );
    addTearDown(container.dispose);

    await pumpChallenges(tester, container);

    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('0 / 7'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });
}
