/// Signing out. The JWT is stateless, so there is nothing to revoke on the
/// server — logging out means dropping the token and every piece of state
/// derived from it. These tests hold the second half to account: clearing the
/// token while leaving the previous user's XP on screen is the easy mistake.
///
/// Everything that can be asserted at the provider level is, because the
/// Profile screen runs pulse animations that never settle and is a poor thing
/// to drive from a widget test. Only the button itself is pumped, and only with
/// bounded `pump` calls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/core/navigation/shell_providers.dart';
import 'package:finquest_ai/core/session/session_reset.dart';
import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/achievements/achievements_providers.dart';
import 'package:finquest_ai/features/auth/auth_providers.dart';
import 'package:finquest_ai/features/dashboard/dashboard_providers.dart';
import 'package:finquest_ai/features/profile/presentation/widgets/profile_logout_button.dart';

import 'support/test_harness.dart';

ProviderContainer signedInContainer({FakeTokenStorage? tokenStorage}) {
  return testContainer(
    initialProgress: const ProgressDto(
      xp: 60,
      level: 2,
      streakCount: 3,
      decisionsMade: 5,
      decisionsToday: 5,
    ),
    initialAchievements: const [],
    decisionResult: correctDecision(
      xpDelta: 20,
      progress: const ProgressDto(xp: 80, level: 2, streakCount: 4),
    ),
    tokenStorage: tokenStorage,
  );
}

void main() {
  group('logout drops the session', () {
    test('the stored token is cleared', () async {
      final storage = FakeTokenStorage();
      final container = signedInContainer(tokenStorage: storage);
      addTearDown(container.dispose);
      await warmUp(container);
      expect(storage.token, isNotNull);

      await container.read(authProvider.notifier).logout();

      expect(storage.token, isNull);
      expect(storage.clearCalls, 1);
    });

    test('the session ends up unauthenticated', () async {
      final container = signedInContainer();
      addTearDown(container.dispose);
      await warmUp(container);
      expect(container.read(authProvider).value!.isAuthenticated, isTrue);

      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider).value!.isAuthenticated, isFalse);
    });

    test('the next session does not inherit the previous XP', () async {
      final repo = FakeProgressRepo(
        progress: const ProgressDto(xp: 60, level: 2, streakCount: 3),
        achievements: const [],
      );
      final container = testContainer(
        initialProgress: const ProgressDto(xp: 60, level: 2, streakCount: 3),
        initialAchievements: const [],
        decisionResult: correctDecision(
          xpDelta: 20,
          progress: const ProgressDto(xp: 80, level: 2, streakCount: 4),
        ),
        progressRepo: repo,
      );
      addTearDown(container.dispose);
      await warmUp(container);
      expect(container.read(progressProvider).value!.xp, 60);

      // Stand in for the next session: the backend now answers with a
      // different user's progress.
      repo.progress = ProgressDto.empty;
      await container.read(authProvider.notifier).logout();
      await container.read(progressProvider.future);

      // 60 is gone. Had the provider survived the session, it would still be
      // showing the previous user's XP.
      expect(container.read(progressProvider).value!.xp, 0);
    });

    test('the shell returns to the first tab', () async {
      final container = signedInContainer();
      addTearDown(container.dispose);
      await warmUp(container);
      container.read(shellTabIndexProvider.notifier).state = 3;

      await container.read(authProvider.notifier).logout();

      expect(container.read(shellTabIndexProvider), 0);
    });

    test('achievements empty out for the signed-out user', () async {
      final container = signedInContainer();
      addTearDown(container.dispose);
      await warmUp(container);

      await container.read(authProvider.notifier).logout();
      await container.read(unlockedAchievementCodesProvider.future);

      expect(container.read(unlockedAchievementCodesProvider).value, isEmpty);
      expect(unlockedCodes(container), isEmpty);
    });

    test('an expired token takes the same path as an explicit sign-out',
        () async {
      final container = signedInContainer();
      addTearDown(container.dispose);
      await warmUp(container);
      expect(container.read(progressProvider).value!.xp, 60);

      // What the API client's 401 interceptor calls.
      final before = container.read(progressProvider);
      await container.read(authProvider.notifier).markUnauthenticated();

      expect(container.read(authProvider).value!.isAuthenticated, isFalse);
      expect(
        identical(container.read(progressProvider), before),
        isFalse,
        reason: 'the cached progress must have been discarded, not reused',
      );
    });
  });

  group('the reset list', () {
    test('covers the providers that do not track the session themselves', () {
      // A provider added to the app but forgotten here is exactly how one
      // user's data survives into the next session, so the list is asserted
      // rather than assumed.
      expect(
        sessionScopedProviders,
        containsAll(<Object>[
          progressProvider,
          dashboardNotifierProvider,
          shellTabIndexProvider,
        ]),
      );
    });

    test('leaves out the providers that already watch the session', () {
      // Both of these `ref.watch(authProvider)` and return empty when signed
      // out. Listing them would also be a CircularDependencyError, since the
      // auth notifier cannot invalidate something that depends on it.
      expect(
        sessionScopedProviders,
        isNot(contains(unlockedAchievementCodesProvider)),
      );
      expect(
        sessionScopedProviders,
        isNot(contains(achievementsNotifierProvider)),
      );
    });

    test('does not clear the repositories or the token storage itself', () {
      // Stateless wiring; invalidating it would only churn.
      expect(sessionScopedProviders, isNot(contains(tokenStorageProvider)));
      expect(
        sessionScopedProviders,
        isNot(contains(progressRepositoryProvider)),
      );
      expect(sessionScopedProviders, isNot(contains(apiClientProvider)));
    });
  });

  group('the profile action', () {
    /// Pumps the button alone. No `pumpAndSettle` anywhere: bounded frames
    /// only, matching the pattern in `test/widget/`.
    Future<void> pumpButton(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              appBar: null,
              body: Center(child: ProfileLogoutButton()),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders a sign-out control', (tester) async {
      final container = signedInContainer();
      addTearDown(container.dispose);

      await pumpButton(tester, container);

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('asks before ending the session', (tester) async {
      final storage = FakeTokenStorage();
      final container = signedInContainer(tokenStorage: storage);
      addTearDown(container.dispose);
      await pumpButton(tester, container);

      await openDialog(tester);

      expect(find.text('Log out?'), findsOneWidget);
      expect(storage.token, isNotNull, reason: 'asking must not sign out');
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final storage = FakeTokenStorage();
      final container = signedInContainer(tokenStorage: storage);
      addTearDown(container.dispose);
      await pumpButton(tester, container);
      await openDialog(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Asserted on the storage rather than the session: without warmUp the
      // auth provider is still resolving, and "nothing happened" is exactly
      // what the token proves.
      expect(storage.token, isNotNull);
      expect(storage.clearCalls, 0);
    });

    testWidgets('confirming signs out', (tester) async {
      final storage = FakeTokenStorage();
      final container = signedInContainer(tokenStorage: storage);
      addTearDown(container.dispose);
      await pumpButton(tester, container);
      await openDialog(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(storage.token, isNull);
      expect(container.read(authProvider).value!.isAuthenticated, isFalse);
    });
  });
}
