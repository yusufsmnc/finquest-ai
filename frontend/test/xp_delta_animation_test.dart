/// The backend's `xp_delta` is what the UI animates when it has no previous
/// progress snapshot to diff against.
///
/// `ScenarioEventDispatcher` prefers a real diff (`newXp - before.xp`) and only
/// falls back to `newXp - xpDelta` when `before` is null — the first decision of
/// a session, before `/me/progress` has resolved. On that path a delta that
/// reports the *nominal* reward instead of the change actually applied makes the
/// UI animate XP the user never had: the backend clamps XP at zero, so a wrong
/// answer at 5 XP costs 5, not 10.
///
/// These tests pin the fallback path so the frontend stays honest about a value
/// it cannot recompute.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/core/events/game_event.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import 'support/test_harness.dart';

void main() {
  setUp(SpyScenarioNotifier.reset);

  group('xp_delta drives the animation when there is no snapshot', () {
    test('a clamped loss animates what was actually lost, not the nominal 10',
        () async {
      // Backend state: 5 XP, wrong answer. XP is clamped at 0, so the applied
      // change is -5 and `xp_delta` reports -5.
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 5, level: 1, streakCount: 1),
        initialAchievements: const [],
        decisionResult: wrongDecision(
          xpDelta: -5,
          events: const [
            'DECISION_MADE',
            'DECISION_WRONG',
            'XP_LOST',
            'STREAK_UPDATED',
          ],
          progress: const ProgressDto(xp: 0, level: 1, streakCount: 0),
        ),
        spyEvents: true,
      );
      addTearDown(container.dispose);
      // Deliberately NOT warmed up: `progressProvider` has not resolved, so the
      // dispatcher has no `before` snapshot and must use the reported delta.
      await container.read(authProvider.future);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_b', false);

      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.xpLost)
            .single
            .payload['amount'],
        5,
        reason: 'the user only had 5 XP to lose',
      );
    });

    test('a loss at zero XP animates nothing at all', () async {
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 0, level: 1, streakCount: 0),
        initialAchievements: const [],
        decisionResult: wrongDecision(
          xpDelta: 0,
          events: const [
            'DECISION_MADE',
            'DECISION_WRONG',
            'XP_LOST',
            'STREAK_UPDATED',
          ],
          progress: const ProgressDto(xp: 0, level: 1, streakCount: 0),
        ),
        spyEvents: true,
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_b', false);

      expect(
        SpyScenarioNotifier.countOf(GameEventType.xpLost),
        0,
        reason: 'nothing changed, so there is nothing to animate',
      );
      expect(SpyScenarioNotifier.countOf(GameEventType.xpGained), 0);
    });

    test('an unclamped gain animates the full reward', () async {
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 40, level: 1, streakCount: 2),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          events: const [
            'DECISION_MADE',
            'DECISION_CORRECT',
            'XP_GAINED',
            'STREAK_UPDATED',
          ],
          progress: const ProgressDto(xp: 60, level: 1, streakCount: 3),
        ),
        spyEvents: true,
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);

      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.xpGained)
            .single
            .payload['amount'],
        20,
      );
    });
  });

  test('with a snapshot the UI diffs it and ignores the reported delta',
      () async {
    // A deliberately wrong delta: the snapshot must win, so this value is
    // never used. Proves the fallback is a fallback, not the primary path.
    final container = testContainer(
      initialProgress: const ProgressDto(xp: 5, level: 1, streakCount: 1),
      initialAchievements: const [],
      decisionResult: wrongDecision(
        xpDelta: -999,
        events: const [
          'DECISION_MADE',
          'DECISION_WRONG',
          'XP_LOST',
          'STREAK_UPDATED',
        ],
        progress: const ProgressDto(xp: 0, level: 1, streakCount: 0),
      ),
      spyEvents: true,
    );
    addTearDown(container.dispose);
    await warmUp(container);

    await container
        .read(scenarioDispatcherProvider)
        .onDecisionMade('emergency-fund', 'opt_b', false);

    expect(
      SpyScenarioNotifier.eventsOf(GameEventType.xpLost)
          .single
          .payload['amount'],
      5,
      reason: '5 → 0 is the observed diff, whatever the response claimed',
    );
  });
}
