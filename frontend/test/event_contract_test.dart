/// Asserts the EXACT ordered event stream the scenario dispatcher emits.
///
/// CLAUDE.md fixes the event contract and requires the pipeline to be fully
/// deterministic, so the sequence itself is testable 1:1 — not just its visible
/// side effects. The regression this guards: REWARD_UNLOCKED being emitted more
/// than once per unlock, or re-emitted on reload.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/core/events/game_event.dart';
import 'package:finquest_ai/data/dtos/achievement_dto.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import 'support/test_harness.dart';

void main() {
  setUp(SpyScenarioNotifier.reset);

  group('event contract — exact emitted sequence', () {
    test(
        'correct decision crossing a level threshold with one new achievement '
        'emits DECISION_MADE → DECISION_CORRECT → XP_GAINED → LEVEL_UP → '
        'STREAK_UPDATED → REWARD_UNLOCKED, once each', () async {
      final container = testContainer(
        spyEvents: true,
        // Before: level 1 @ 80 XP. Correct answer → 100 XP, level 2.
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
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);

      expect(SpyScenarioNotifier.types, [
        GameEventType.decisionMade,
        GameEventType.decisionCorrect,
        GameEventType.xpGained,
        GameEventType.levelUp,
        GameEventType.streakUpdated,
        GameEventType.rewardUnlocked,
      ]);

      // The headline invariant: exactly one unlock event, for the right code.
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1);
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.rewardUnlocked)
            .single
            .payload['rewardId'],
        'streak_5',
      );

      // Payloads carry the backend-authoritative diff, not UI-computed values.
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.xpGained)
            .single
            .payload['amount'],
        20,
      );
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.levelUp)
            .single
            .payload['newLevel'],
        2,
      );
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.streakUpdated)
            .single
            .payload['streak'],
        5,
      );
      expect(SpyScenarioNotifier.countOf(GameEventType.xpLost), 0);
    });

    test(
        'two newly unlocked achievements → REWARD_UNLOCKED exactly twice, '
        'one per code, no duplicates', () async {
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 90, level: 2, streakCount: 2),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 110, level: 2, streakCount: 3),
          newAchievements: const ['streak_3', 'xp_100'],
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('budget-101', 'opt_a', true);

      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 2);
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.rewardUnlocked)
            .map((e) => e.payload['rewardId'])
            .toList(),
        ['streak_3', 'xp_100'],
      );
      // No level change in the response → no LEVEL_UP.
      expect(SpyScenarioNotifier.countOf(GameEventType.levelUp), 0);
    });

    test('correct decision with no new achievement emits ZERO REWARD_UNLOCKED',
        () async {
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 20, level: 1, streakCount: 1),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 40, level: 1, streakCount: 2),
          newAchievements: const [],
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('savings-101', 'opt_a', true);

      expect(SpyScenarioNotifier.types, [
        GameEventType.decisionMade,
        GameEventType.decisionCorrect,
        GameEventType.xpGained,
        GameEventType.streakUpdated,
      ]);
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 0);
    });

    test(
        'wrong decision emits DECISION_WRONG + XP_LOST + STREAK_UPDATED, '
        'never XP_GAINED / LEVEL_UP / REWARD_UNLOCKED', () async {
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
        initialAchievements: const [AchievementDto(code: 'streak_5')],
        decisionResult: wrongDecision(
          xpDelta: -10,
          progress: const ProgressDto(xp: 90, level: 1, streakCount: 0),
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('risk-101', 'opt_b', false);

      expect(SpyScenarioNotifier.types, [
        GameEventType.decisionMade,
        GameEventType.decisionWrong,
        GameEventType.xpLost,
        GameEventType.streakUpdated,
      ]);
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.xpLost)
            .single
            .payload['amount'],
        10,
      );
      expect(
        SpyScenarioNotifier.eventsOf(GameEventType.streakUpdated)
            .single
            .payload['streak'],
        0,
      );
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 0);
      expect(SpyScenarioNotifier.countOf(GameEventType.levelUp), 0);
      expect(SpyScenarioNotifier.countOf(GameEventType.xpGained), 0);
      // Level going DOWN must not emit anything (no such event in the contract).
      expect(SpyScenarioNotifier.countOf(GameEventType.decisionCorrect), 0);
    });

    test('reload with an already-unlocked achievement emits NO events at all',
        () async {
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 0),
        initialAchievements: const [AchievementDto(code: 'streak_5')],
        decisionResult: correctDecision(
          xpDelta: 0,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 0),
        ),
      );
      addTearDown(container.dispose);

      // A full cold start: auth → progress → achievements, no user action.
      await warmUp(container);

      expect(unlockedCodes(container), contains('streak_5'));
      expect(SpyScenarioNotifier.recorded, isEmpty,
          reason: 'loading persisted state must never replay the event stream');
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 0);
    });

    test(
        'the same decision replayed twice re-emits per call and never '
        'accumulates a second REWARD_UNLOCKED for a repeat code', () async {
      // Backend is authoritative: a code already unlocked is NOT returned again
      // in new_achievements, so the second call must produce no unlock event.
      final api = FakeScenarioApi(
        correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 100, level: 1, streakCount: 5),
          newAchievements: const ['streak_5'],
        ),
      );
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        initialAchievements: const [],
        decisionResult: api.result,
        scenarioApi: api,
      );
      addTearDown(container.dispose);
      await warmUp(container);

      final dispatcher = container.read(scenarioDispatcherProvider);
      await dispatcher.onDecisionMade('emergency-fund', 'opt_a', true);
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1);

      // Second decision: backend reports the code as already owned.
      api.result = correctDecision(
        xpDelta: 20,
        progress: const ProgressDto(xp: 120, level: 1, streakCount: 6),
        newAchievements: const [],
      );
      await dispatcher.onDecisionMade('emergency-fund', 'opt_a', true);

      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1,
          reason: 'still exactly one unlock across both decisions');
      expect(unlockedCodes(container), contains('streak_5'));
      expect(api.calls.length, 2);
    });

    test('every emitted event belongs to the immutable contract', () async {
      final container = testContainer(
        spyEvents: true,
        initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
          newAchievements: const ['streak_5'],
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);

      expect(SpyScenarioNotifier.recorded, isNotEmpty);
      for (final event in SpyScenarioNotifier.recorded) {
        expect(GameEventType.values, contains(event.type));
      }
    });
  });

  group('persistence boundary', () {
    test(
        'unlocked achievements survive a container restart (reload) with the '
        'backend as the only source', () async {
      // Session 1: unlock via a decision.
      final repo = FakeProgressRepo(
        progress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        achievements: const [],
      );
      final first = testContainer(
        spyEvents: true,
        initialProgress: repo.progress,
        initialAchievements: repo.achievements,
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
          newAchievements: const ['streak_5'],
        ),
        progressRepo: repo,
      );
      await warmUp(first);
      await first
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);
      expect(unlockedCodes(first), contains('streak_5'));
      expect(SpyScenarioNotifier.countOf(GameEventType.rewardUnlocked), 1);
      first.dispose();

      // Backend persisted it.
      repo
        ..progress = const ProgressDto(xp: 100, level: 2, streakCount: 5)
        ..achievements = const [AchievementDto(code: 'streak_5')];

      // Session 2: brand-new container == app restart.
      SpyScenarioNotifier.reset();
      final second = testContainer(
        spyEvents: true,
        initialProgress: repo.progress,
        initialAchievements: repo.achievements,
        decisionResult: correctDecision(
          xpDelta: 0,
          progress: repo.progress,
        ),
        progressRepo: repo,
      );
      addTearDown(second.dispose);
      await warmUp(second);

      expect(unlockedCodes(second), contains('streak_5'),
          reason: 'restored from GET /me/achievements');
      expect(second.read(progressProvider).value!.xp, 100);
      expect(second.read(progressProvider).value!.level, 2);
      expect(SpyScenarioNotifier.recorded, isEmpty,
          reason: 'restart replays state, never events');
    });
  });
}
