import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/events/game_event.dart';
import '../../../data/repositories/scenario_api_repository.dart';
import '../../achievements/application/achievements_notifier.dart';
import '../../achievements/data/achievements_repository.dart';
import '../../ai_mentor/application/ai_mentor_notifier.dart';
import '../../auth/application/progress_notifier.dart';
import '../../gamification/application/gamification_overlay_notifier.dart';
import '../../market_events/application/market_events_notifier.dart';
import 'scenario_notifier.dart';

class ScenarioEventDispatcher {
  final ScenarioNotifier _notifier;
  final GamificationOverlayNotifier _overlayNotifier;
  final AchievementsNotifier _achievementsNotifier;
  final AiMentorNotifier _mentorNotifier;
  final MarketEventsNotifier _marketEventsNotifier;
  final ProgressNotifier _progressNotifier;
  final ScenarioApiRepository _scenarioApi;

  bool _disposed = false;

  ScenarioEventDispatcher(
    this._notifier,
    this._overlayNotifier,
    this._achievementsNotifier,
    this._mentorNotifier,
    this._marketEventsNotifier,
    this._progressNotifier,
    this._scenarioApi,
  );

  void dispose() => _disposed = true;

  void _dispatch(GameEvent event) {
    _notifier.applyEvent(event);
    _overlayNotifier.applyEvent(event);
    _achievementsNotifier.applyEvent(event);
    _mentorNotifier.applyEvent(event);
    _marketEventsNotifier.applyEvent(event);
  }

  /// User picks an option. The backend applies authoritative gamification; the
  /// UI only renders the diff (it never computes XP/level itself).
  ///
  /// Pipeline: User Action → DECISION_MADE → POST /scenarios/{id}/decision →
  /// diff old vs new progress → emit XP/LEVEL/STREAK events → animations.
  Future<void> onDecisionMade(
      String scenarioId, String optionId, bool isCorrect) async {
    // Snapshot authoritative progress BEFORE the decision, for diffing.
    final before = _progressNotifier.currentOrNull;

    _dispatch(GameEvent.decisionMade(optionId: optionId));

    DecisionOutcomeResult? outcome;
    try {
      final result = await _scenarioApi.postDecision(
        scenarioId,
        choice: optionId,
        correct: isCorrect,
      );
      outcome = DecisionOutcomeResult(
        correct: result.isCorrect,
        newXp: result.progress.xp,
        newLevel: result.progress.level,
        newStreak: result.progress.streakCount,
        xpDelta: result.xpDelta,
        newAchievements: result.newAchievements,
      );
      // Backend is the source of truth → update it immediately.
      _progressNotifier.setProgress(result.progress);
    } on DioException catch (_) {
      // Server unreachable/error: keep the UX alive with a visual-only
      // correctness cue, but never fabricate XP/level (backend owns those).
      _dispatch(isCorrect
          ? GameEvent.decisionCorrect(optionId: optionId)
          : GameEvent.decisionWrong(optionId: optionId));
      await _finishToFeedback(scenarioId);
      return;
    }

    // ── Diff-driven events (no UI computation of XP/level) ──────────────
    if (outcome.correct) {
      _dispatch(GameEvent.decisionCorrect(optionId: optionId));
    } else {
      _dispatch(GameEvent.decisionWrong(optionId: optionId));
    }

    // Fall back to the reported delta only when we had no prior snapshot.
    final oldXp = before?.xp ?? (outcome.newXp - outcome.xpDelta);
    if (outcome.newXp > oldXp) {
      _dispatch(GameEvent.xpGained(amount: outcome.newXp - oldXp));
    } else if (outcome.newXp < oldXp) {
      _dispatch(GameEvent.xpLost(amount: oldXp - outcome.newXp));
    }

    final oldLevel = before?.level ?? outcome.newLevel;
    if (outcome.newLevel > oldLevel) {
      _dispatch(GameEvent.levelUp(newLevel: outcome.newLevel));
    }

    _dispatch(GameEvent.streakUpdated(streak: outcome.newStreak));

    // Achievements are backend-owned: reflect the codes it just unlocked and
    // emit REWARD_UNLOCKED for each (drives the toast + unlock overlay).
    if (outcome.newAchievements.isNotEmpty) {
      _achievementsNotifier.addUnlockedCodes(outcome.newAchievements);
      for (final code in outcome.newAchievements) {
        _overlayNotifier.triggerAchievementUnlock(
          AchievementsRepository.titleFor(code) ?? 'Achievement Unlocked',
        );
        _dispatch(GameEvent.rewardUnlocked(rewardId: code));
      }
    }

    // ── Mentor: exactly ONE request per decision ────────────────────────
    // Deliberately after the event burst, so the four events above cost a
    // single call. The events already painted a local placeholder; this
    // replaces it when the backend answers. Not awaited — the feedback
    // animation must not wait on the network.
    unawaited(
      _mentorNotifier.requestForDecision(
        isCorrect: outcome.correct,
        scenarioId: scenarioId,
        category: _notifier.currentState.activeScenario?.category,
        xp: outcome.newXp,
        level: outcome.newLevel,
        streak: outcome.newStreak,
        leveledUp: outcome.newLevel > oldLevel,
        unlockedAchievement: outcome.newAchievements.isNotEmpty,
      ),
    );

    await _finishToFeedback(scenarioId);
  }

  Future<void> _finishToFeedback(String scenarioId) async {
    _notifier.markCompleted(scenarioId);
    // Let the answer animation play before advancing.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_disposed) return;
    _notifier.advanceToFeedback();
  }

  void onScenarioSelected(String id) {
    _notifier.loadScenario(id);
    final category = _notifier.currentState.activeScenario?.category;
    if (category != null) {
      _mentorNotifier.setCategoryGuidance(category);
    }
  }

  void onNextScenario() => _notifier.nextScenario();
  void onBackToList() => _notifier.backToList();
  void onCategorySelected(String? category) {
    _notifier.setCategory(category);
    if (category != null) {
      _mentorNotifier.setCategoryGuidance(category);
    }
  }

  void onXpFloatDismissed() => _notifier.dismissXpFloat();
  void onRewardToastDismissed() => _notifier.dismissRewardToast();
  void onStreakPulseDismissed() => _notifier.dismissStreakPulse();
}

/// Small value object bundling the authoritative outcome of a decision.
class DecisionOutcomeResult {
  final bool correct;
  final int newXp;
  final int newLevel;
  final int newStreak;
  final int xpDelta;
  final List<String> newAchievements;

  const DecisionOutcomeResult({
    required this.correct,
    required this.newXp,
    required this.newLevel,
    required this.newStreak,
    required this.xpDelta,
    this.newAchievements = const [],
  });
}
