/// The Profile screen's persistent statistics are renderings of authoritative
/// backend values, not of in-session counters.
///
/// This is the bug Faz 7b closes: the header read its XP from the gamification
/// overlay's in-session accumulator (zero until the user made a decision *this
/// session*), while the XP Progress card read `DashboardState`, whose
/// constructor defaulted to a fabricated 2 / 60 / 1. One screen, two numbers,
/// neither from the server.
///
/// Each test pumps a section widget with a container whose backend answers with
/// known values, then asserts those exact values are on screen — with the
/// in-session counters left at zero, so anything reading them would show a
/// different number and fail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/profile/presentation/widgets/profile_identity_card.dart';
import 'package:finquest_ai/features/profile/presentation/widgets/profile_streak_section.dart';
import 'package:finquest_ai/features/profile/presentation/widgets/profile_xp_section.dart';

import '../support/test_harness.dart';

/// Widget tests run without the app's real fonts and the substitute is wider
/// per glyph, which overflows fixed-height cards by a few pixels. That is an
/// artifact of the font, not of the layout under test.
void ignoreFontSubstitutionOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

/// A signed-in user with a history: 60 net XP, 100 gross earned, 8 decisions of
/// which 6 were right, a current streak of 2 and a record of 5.
const seededProgress = ProgressDto(
  xp: 60,
  level: 2,
  streakCount: 2,
  bestStreak: 5,
  decisionsMade: 8,
  decisionsToday: 3,
  correctDecisions: 6,
  accuracy: 0.75,
  xpEarnedTotal: 100,
);

ProviderContainer containerWith(ProgressDto progress) => testContainer(
      initialProgress: progress,
      initialAchievements: const [],
      decisionResult: correctDecision(
        xpDelta: 0,
        progress: progress,
      ),
    );

Future<void> pumpSection(
  WidgetTester tester,
  ProviderContainer container,
  Widget section,
) async {
  ignoreFontSubstitutionOverflow();
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: section)),
      ),
    ),
  );
  // Bounded frames only — the profile widgets animate continuously, so
  // pumpAndSettle would wait for a frame that never comes.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('identity card header', () {
    testWidgets('XP and Decisions come from the backend', (tester) async {
      final container = containerWith(seededProgress);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileIdentityCard());

      // 60, not the overlay's in-session 0.
      expect(find.text('60'), findsOneWidget);
      // 8, not the scenario notifier's in-session 0.
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('a user with no history reads zero, not a seeded number',
        (tester) async {
      final container = containerWith(ProgressDto.empty);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileIdentityCard());

      expect(find.text('60'), findsNothing, reason: 'the old fabricated XP');
      expect(find.text('0'), findsWidgets);
    });
  });

  group('XP progress card', () {
    testWidgets('level, XP and total earned come from the backend',
        (tester) async {
      final container = containerWith(seededProgress);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileXpSection());

      expect(find.textContaining('100 XP'), findsOneWidget,
          reason: 'Total XP Earned is gross, not the 60 net balance');
      expect(find.textContaining('200 XP'), findsOneWidget,
          reason: 'Next Level At = level x 100');
    });

    testWidgets('the next-level target follows the backend level',
        (tester) async {
      final container = containerWith(
        const ProgressDto(xp: 340, level: 4, streakCount: 0),
      );
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileXpSection());

      expect(find.textContaining('400 XP'), findsOneWidget);
    });

    testWidgets('an empty profile does not show a seeded level',
        (tester) async {
      final container = containerWith(ProgressDto.empty);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileXpSection());

      expect(find.textContaining('200 XP'), findsNothing);
      expect(find.textContaining('100 XP'), findsWidgets,
          reason: 'level 1 targets 100');
    });
  });

  group('streak and accuracy', () {
    testWidgets('current and best streak come from the backend',
        (tester) async {
      final container = containerWith(seededProgress);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileStreakSection());

      expect(find.text('2'), findsWidgets, reason: 'current streak');
      expect(find.textContaining('5'), findsWidgets, reason: 'best streak');
    });

    testWidgets('accuracy renders the backend rate as a percentage',
        (tester) async {
      final container = containerWith(seededProgress);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileStreakSection());

      expect(find.textContaining('75'), findsWidgets);
    });

    testWidgets('accuracy is zero before any decision, not a stale rate',
        (tester) async {
      final container = containerWith(ProgressDto.empty);
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileStreakSection());

      expect(find.textContaining('75'), findsNothing);
    });

    testWidgets('the best streak survives the current one being zero',
        (tester) async {
      // Exactly the case a local high-water mark got wrong: reload after a
      // wrong answer and the record was gone.
      final container = containerWith(
        const ProgressDto(xp: 40, level: 1, streakCount: 0, bestStreak: 7),
      );
      addTearDown(container.dispose);

      await pumpSection(tester, container, const ProfileStreakSection());

      expect(find.textContaining('7'), findsWidgets);
    });
  });
}
