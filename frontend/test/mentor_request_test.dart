/// The mentor must cost one backend request per decision — not one per
/// emitted event — and must never break the UI when that request fails.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/ai_mentor/ai_mentor_providers.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

import 'support/test_harness.dart';

void main() {
  group('mentor is called once per decision', () {
    test(
        'a decision emitting DECISION_CORRECT + XP_GAINED + LEVEL_UP + '
        'REWARD_UNLOCKED still issues exactly ONE /mentor request', () async {
      final mentorApi = FakeMentorApi(message: 'Steady work. Keep that pace.');
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
          newAchievements: const ['streak_5'],
        ),
        mentorApi: mentorApi,
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);
      await Future<void>.delayed(Duration.zero);

      expect(mentorApi.calls.length, 1,
          reason: 'four events must not mean four billed LLM calls');
    });

    test('two decisions issue exactly two requests', () async {
      final mentorApi = FakeMentorApi();
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 20, level: 1, streakCount: 1),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 40, level: 1, streakCount: 2),
        ),
        mentorApi: mentorApi,
      );
      addTearDown(container.dispose);
      await warmUp(container);

      final dispatcher = container.read(scenarioDispatcherProvider);
      await dispatcher.onDecisionMade('savings-101', 'opt_a', true);
      await dispatcher.onDecisionMade('savings-101', 'opt_a', true);
      await Future<void>.delayed(Duration.zero);

      expect(mentorApi.calls.length, 2);
    });

    test('the request carries the authoritative context, not UI guesses',
        () async {
      final mentorApi = FakeMentorApi();
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 80, level: 1, streakCount: 4),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
          newAchievements: const ['streak_5'],
        ),
        mentorApi: mentorApi,
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('emergency-fund', 'opt_a', true);
      await Future<void>.delayed(Duration.zero);

      final sent = mentorApi.calls.single;
      expect(sent.xp, 100);
      expect(sent.level, 2);
      expect(sent.streak, 5);
      // An unlock outranks the level-up and the plain correct answer.
      expect(sent.context, 'achievement_unlock');
      expect(sent.recentDecisions.single.scenarioId, 'emergency-fund');
      expect(sent.recentDecisions.single.isCorrect, isTrue);
    });

    test('a wrong decision sends the decision_wrong context', () async {
      final mentorApi = FakeMentorApi();
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 100, level: 2, streakCount: 5),
        initialAchievements: const [],
        decisionResult: wrongDecision(
          xpDelta: -10,
          progress: const ProgressDto(xp: 90, level: 2, streakCount: 0),
        ),
        mentorApi: mentorApi,
      );
      addTearDown(container.dispose);
      await warmUp(container);

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('risk-101', 'opt_b', false);
      await Future<void>.delayed(Duration.zero);

      expect(mentorApi.calls.single.context, 'decision_wrong');
      expect(mentorApi.calls.single.streak, 0);
    });
  });

  group('mentor rendering', () {
    test('the backend message replaces the local placeholder', () async {
      const remote = 'You paused before deciding. That habit compounds.';
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 20, level: 1, streakCount: 1),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 40, level: 1, streakCount: 2),
        ),
        mentorApi: FakeMentorApi(message: remote),
      );
      addTearDown(container.dispose);
      await warmUp(container);
      container.listen(aiMentorProvider, (_, __) {});

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('savings-101', 'opt_a', true);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(aiMentorProvider);
      expect(state.currentMessage!.text, remote);
      expect(state.isMentorLoading, isFalse);
      // The placeholder was replaced in place, not stacked on top of itself.
      expect(state.messageHistory.first.text, remote);
      expect(state.messageHistory.where((m) => m.text == remote).length, 1);
    });

    test('an unreachable backend leaves the local placeholder on screen',
        () async {
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 20, level: 1, streakCount: 1),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 40, level: 1, streakCount: 2),
        ),
        mentorApi: FakeMentorApi(error: Exception('connection refused')),
      );
      addTearDown(container.dispose);
      await warmUp(container);
      container.listen(aiMentorProvider, (_, __) {});

      await container
          .read(scenarioDispatcherProvider)
          .onDecisionMade('savings-101', 'opt_a', true);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(aiMentorProvider);
      // Still a real, readable message — the UI never goes blank or throws.
      expect(state.currentMessage, isNotNull);
      expect(state.currentMessage!.text, isNotEmpty);
      expect(state.isMentorLoading, isFalse);
    });
  });
}
