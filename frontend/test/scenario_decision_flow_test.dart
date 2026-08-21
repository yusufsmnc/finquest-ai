/// End-to-end behaviour of the decision pipeline at the state layer:
/// backend response → authoritative progress → rendered gamification state.
///
/// The exact event *sequence* is asserted in `event_contract_test.dart`; this
/// file asserts the observable state those events produce.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/data/dtos/achievement_dto.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/gamification/gamification_providers.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import 'support/test_harness.dart';

void main() {
  group('decision → event pipeline (backend-authoritative)', () {
    test(
        'unlock: emits DECISION_CORRECT + XP_GAINED + LEVEL_UP + REWARD_UNLOCKED '
        'exactly once', () async {
      // Before: level 1 @ 80xp; a correct answer pushes to 100xp → level 2.
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          events: const [
            'DECISION_MADE',
            'DECISION_CORRECT',
            'XP_GAINED',
            'STREAK_UPDATED',
            'LEVEL_UP',
            'REWARD_UNLOCKED',
          ],
          progress: const ProgressDto(
            xp: 100,
            level: 2,
            streakCount: 5,
            decisionsMade: 5,
            decisionsToday: 5,
          ),
          // Exactly one new achievement → exactly one REWARD_UNLOCKED.
          newAchievements: const ['streak_5'],
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);

      // Authoritative progress updated from the backend response.
      final progress = container.read(progressProvider).value!;
      expect(progress.xp, 100);
      expect(progress.level, 2);
      expect(progress.streakCount, 5);

      final scenario = container.read(scenarioNotifierProvider);
      expect(scenario.isCorrect, isTrue, reason: 'DECISION_CORRECT fired');
      expect(scenario.lastXpGained, 20, reason: 'XP_GAINED carried the diff');
      expect(scenario.currentStreak, 5, reason: 'STREAK_UPDATED fired');

      final overlay = container.read(gamificationOverlayProvider);
      expect(overlay.showLevelUp, isTrue, reason: 'LEVEL_UP fired');
      // toastQueue only grows on REWARD_UNLOCKED → exactly one unlock.
      expect(overlay.toastQueue.length, 1,
          reason: 'REWARD_UNLOCKED emitted exactly once');
      expect(overlay.showAchievementUnlock, isTrue);

      expect(unlockedCodes(container), contains('streak_5'));
    });

    test(
        'reload: unlocked state loads from backend WITHOUT re-emitting '
        'REWARD_UNLOCKED', () async {
      // Fresh app start: backend already has the achievement; no decision made.
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 0),
        initialAchievements: const [AchievementDto(code: 'streak_5')],
        decisionResult: correctDecision(
          xpDelta: 0,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 0),
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      // Loaded as unlocked…
      expect(unlockedCodes(container), contains('streak_5'));
      // …but no gamification event was replayed.
      final overlay = container.read(gamificationOverlayProvider);
      expect(overlay.toastQueue, isEmpty,
          reason: 'REWARD_UNLOCKED NOT re-emitted on reload');
      expect(overlay.showAchievementUnlock, isFalse);
      expect(overlay.showLevelUp, isFalse);
    });

    test('wrong decision: streak resets to 0 but unlocked list does not shrink',
        () async {
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
        initialAchievements: const [AchievementDto(code: 'streak_5')],
        decisionResult: wrongDecision(
          xpDelta: -10,
          events: const [
            'DECISION_MADE',
            'DECISION_WRONG',
            'XP_LOST',
            'STREAK_UPDATED',
          ],
          progress: const ProgressDto(xp: 90, level: 1, streakCount: 0),
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      final unlockedBefore = unlockedCodes(container);
      expect(unlockedBefore, contains('streak_5'));

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('risk-101', 'opt_b', false);

      expect(container.read(progressProvider).value!.streakCount, 0,
          reason: 'streak reset');
      // Permanent: unlocked achievements are never removed.
      final unlockedAfter = unlockedCodes(container);
      expect(unlockedAfter, contains('streak_5'));
      expect(unlockedAfter.length, greaterThanOrEqualTo(unlockedBefore.length));
    });

    test('wrong decision never unlocks anything even if the streak was high',
        () async {
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 9),
        initialAchievements: const [],
        decisionResult: wrongDecision(
          xpDelta: -10,
          progress: const ProgressDto(xp: 90, level: 2, streakCount: 0),
        ),
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('risk-101', 'opt_b', false);

      expect(unlockedCodes(container), isEmpty,
          reason: 'the frontend must never compute an unlock itself');
      expect(container.read(gamificationOverlayProvider).toastQueue, isEmpty);
    });
  });
}
