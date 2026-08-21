/// OPTIONAL browser E2E — the same invariant the widget suite guards, but
/// driven through the real app against a real backend.
///
///   login/register → make a correct decision → unlock overlay appears →
///   restart the app → still unlocked, overlay does NOT replay.
///
/// PREREQUISITES (this does NOT run as part of `flutter test`):
///   1. a backend on API_BASE_URL with a reachable database
///   2. `chromedriver --port=4444` running
///   3. run with:
///        flutter drive \
///          --driver=test_driver/integration_test.dart \
///          --target=integration_test/unlock_persistence_e2e_test.dart \
///          -d chrome --dart-define=API_BASE_URL=http://localhost:8000
///      (or `flutter test integration_test -d chrome` on a device that has a
///      driver attached)
///
/// The fast, hermetic protection lives in `test/` — this is the slow
/// confidence check, kept out of the default CI lane on purpose.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:finquest_ai/features/gamification/presentation/widgets/achievement_unlock_overlay.dart';
import 'package:finquest_ai/main.dart' as app;

/// Waits until [finder] matches (or [timeout] elapses), pumping in between.
/// `pumpAndSettle` is unusable here: several overlays run looping animations.
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Unique per run so registration never collides with an existing row.
String uniqueEmail() =>
    'e2e_${DateTime.now().millisecondsSinceEpoch}@finquest.test';

const String password = 'testpassword123';

Future<void> bootApp(WidgetTester tester) async {
  app.main();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 2));
}

Future<void> registerAndLogin(WidgetTester tester, String email) async {
  // Land on the login screen, flip it into register mode.
  expect(await pumpUntilFound(tester, find.text('Welcome back')), isTrue,
      reason: 'login screen should be the entry point when unauthenticated');

  await tester.tap(find.textContaining('Sign up'));
  await tester.pump(const Duration(milliseconds: 300));

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.pump(const Duration(milliseconds: 200));

  await tester.tap(find.text('Create account'));
  await pumpUntilFound(tester, find.text('Scenarios'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unlock survives a restart and the overlay does not replay',
      (tester) async {
    final email = uniqueEmail();

    // ── Session 1: register → decide → unlock ───────────────────────────
    await bootApp(tester);
    await registerAndLogin(tester, email);

    // Onboarding may be in the way on a fresh account — skip through it.
    while (find.textContaining('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.textContaining('Skip').first);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.tap(find.text('Scenarios'));
    await tester.pump(const Duration(seconds: 1));

    // Open the first scenario and take the first option.
    await tester.tap(find.byType(Card).first);
    await tester.pump(const Duration(seconds: 1));

    final overlayAppeared =
        await pumpUntilFound(tester, find.byType(AchievementUnlockOverlay));
    expect(overlayAppeared, isTrue,
        reason: 'a decision that crosses a threshold must show the unlock');

    // Let the celebration finish so nothing is mid-animation at restart.
    await tester.pump(const Duration(seconds: 5));

    // ── Session 2: restart ──────────────────────────────────────────────
    await bootApp(tester);

    // The stored token logs the user straight back in — no login screen.
    expect(await pumpUntilFound(tester, find.text('Achievements')), isTrue);

    // The celebration must NOT replay for an already-owned achievement.
    await tester.pump(const Duration(seconds: 6));
    expect(find.byType(AchievementUnlockOverlay), findsNothing,
        reason: 'REWARD_UNLOCKED must not be re-emitted on restart');

    // …while the achievement itself is still there.
    await tester.tap(find.text('Achievements'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Unlocked'), findsWidgets);
  });
}
