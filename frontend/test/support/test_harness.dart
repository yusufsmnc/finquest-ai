/// Shared test doubles + container harness.
///
/// Nothing here touches the network: every repository that would issue an HTTP
/// call is replaced by a fake returning canned backend responses. This keeps the
/// suite deterministic and CI-safe (no server, no DB, no timing flake).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finquest_ai/core/events/game_event.dart';
import 'package:finquest_ai/data/api_client.dart';
import 'package:finquest_ai/data/auth/token_storage.dart';
import 'package:finquest_ai/data/dtos/achievement_dto.dart';
import 'package:finquest_ai/data/dtos/decision_result_dto.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/data/repositories/progress_repository.dart';
import 'package:finquest_ai/data/repositories/scenario_api_repository.dart';
import 'package:finquest_ai/features/achievements/achievements_providers.dart';
import 'package:finquest_ai/features/auth/application/auth_notifier.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/auth/domain/auth_state.dart';
import 'package:finquest_ai/features/scenarios/application/scenario_notifier.dart';
import 'package:finquest_ai/features/scenarios/scenario_providers.dart';

/// An [ApiClient] whose Dio is never exercised — the fake repos below override
/// every method that would hit the wire.
ApiClient fakeApiClient() =>
    ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () async {});

/// Always-authenticated session, so auth-gated providers resolve immediately.
class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState.authenticated();
}

/// Canned `POST /scenarios/{id}/decision`.
class FakeScenarioApi extends ScenarioApiRepository {
  FakeScenarioApi(this.result) : super(fakeApiClient());

  DecisionResultDto result;

  /// Every decision request the dispatcher issued (id, choice, correct).
  final List<({String scenarioId, String choice, bool correct})> calls = [];

  @override
  Future<DecisionResultDto> postDecision(
    String scenarioId, {
    required String choice,
    required bool correct,
  }) async {
    calls.add((scenarioId: scenarioId, choice: choice, correct: correct));
    return result;
  }
}

/// Canned `GET /me/progress` + `GET /me/achievements`.
class FakeProgressRepo extends ProgressRepository {
  FakeProgressRepo({required this.progress, required this.achievements})
      : super(fakeApiClient());

  ProgressDto progress;
  List<AchievementDto> achievements;

  int getProgressCalls = 0;
  int getAchievementsCalls = 0;

  @override
  Future<ProgressDto> getProgress() async {
    getProgressCalls++;
    return progress;
  }

  @override
  Future<List<AchievementDto>> getAchievements() async {
    getAchievementsCalls++;
    return achievements;
  }
}

/// A [ScenarioNotifier] that records the exact ordered stream of events the
/// dispatcher fans out, then delegates to the real implementation.
///
/// The dispatcher calls `applyEvent` on this notifier for *every* dispatched
/// event, so this is a faithful tap on the event pipeline without adding any
/// production-only test hooks or new event types.
class SpyScenarioNotifier extends ScenarioNotifier {
  static final List<GameEvent> recorded = [];

  /// Call in `setUp` — the notifier is constructed by Riverpod, so the log has
  /// to live statically.
  static void reset() => recorded.clear();

  static List<GameEventType> get types =>
      recorded.map((e) => e.type).toList(growable: false);

  static int countOf(GameEventType type) =>
      recorded.where((e) => e.type == type).length;

  static List<GameEvent> eventsOf(GameEventType type) =>
      recorded.where((e) => e.type == type).toList(growable: false);

  @override
  void applyEvent(GameEvent event) {
    recorded.add(event);
    super.applyEvent(event);
  }
}

/// Overrides wiring the whole graph onto fakes.
List<Override> testOverrides({
  required ProgressDto initialProgress,
  required List<AchievementDto> initialAchievements,
  required DecisionResultDto decisionResult,
  bool spyEvents = false,
  FakeProgressRepo? progressRepo,
  FakeScenarioApi? scenarioApi,
}) {
  return [
    authProvider.overrideWith(FakeAuthNotifier.new),
    progressRepositoryProvider.overrideWithValue(
      progressRepo ??
          FakeProgressRepo(
            progress: initialProgress,
            achievements: initialAchievements,
          ),
    ),
    scenarioApiRepositoryProvider
        .overrideWithValue(scenarioApi ?? FakeScenarioApi(decisionResult)),
    if (spyEvents)
      scenarioNotifierProvider.overrideWith(SpyScenarioNotifier.new),
  ];
}

/// A container with the full fake graph installed.
ProviderContainer testContainer({
  required ProgressDto initialProgress,
  required List<AchievementDto> initialAchievements,
  required DecisionResultDto decisionResult,
  bool spyEvents = false,
  FakeProgressRepo? progressRepo,
  FakeScenarioApi? scenarioApi,
}) {
  return ProviderContainer(
    overrides: testOverrides(
      initialProgress: initialProgress,
      initialAchievements: initialAchievements,
      decisionResult: decisionResult,
      spyEvents: spyEvents,
      progressRepo: progressRepo,
      scenarioApi: scenarioApi,
    ),
  );
}

/// Resolves the async providers a real session would have loaded before the
/// user can act (auth → progress → achievements), so tests start from the same
/// state a warm app screen does.
Future<void> warmUp(ProviderContainer c) async {
  await c.read(authProvider.future);
  await c.read(progressProvider.future);
  // Keep the achievements notifier alive so it recomposes on remote arrival.
  c.listen(achievementsNotifierProvider, (_, __) {});
  await c.read(unlockedAchievementCodesProvider.future);
  await Future<void>.delayed(Duration.zero);
}

/// Codes currently rendered as unlocked.
Set<String> unlockedCodes(ProviderContainer c) => c
    .read(achievementsNotifierProvider)
    .achievements
    .where((a) => a.unlocked)
    .map((a) => a.id)
    .toSet();

/// Convenience builders keeping the canned backend payloads readable.
DecisionResultDto correctDecision({
  required ProgressDto progress,
  required int xpDelta,
  List<String> newAchievements = const [],
  List<String> events = const [],
}) =>
    DecisionResultDto(
      result: 'DECISION_CORRECT',
      xpDelta: xpDelta,
      events: events,
      progress: progress,
      newAchievements: newAchievements,
    );

DecisionResultDto wrongDecision({
  required ProgressDto progress,
  required int xpDelta,
  List<String> newAchievements = const [],
  List<String> events = const [],
}) =>
    DecisionResultDto(
      result: 'DECISION_WRONG',
      xpDelta: xpDelta,
      events: events,
      progress: progress,
      newAchievements: newAchievements,
    );
