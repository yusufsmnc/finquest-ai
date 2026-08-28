import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_mentor/ai_mentor_providers.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/gamification/gamification_providers.dart';
import '../../features/market_events/market_events_providers.dart';
import '../../features/profile/profile_providers.dart';
import '../../features/scenarios/scenario_providers.dart';
import '../navigation/shell_providers.dart';

/// Every provider whose state belongs to the signed-in user.
///
/// Riverpod keeps a notifier alive for as long as something is listening, so
/// none of these clear themselves when the session ends: without an explicit
/// reset the next person to sign in on the same device sees the previous
/// user's XP, achievements and mentor messages until each provider happens to
/// refetch. Anything derived from a token has to be listed here.
///
/// Two deliberate absences. `unlockedAchievementCodesProvider` and
/// `achievementsNotifierProvider` both `ref.watch(authProvider)` already, so
/// they recompute the moment the session flips and return empty for a signed-out
/// user — they need no help. They must also *not* be listed: invalidating a
/// provider that depends on the notifier doing the invalidating is a
/// `CircularDependencyError`, which is how this list originally failed.
///
/// This lives in `core/` rather than in a feature: the session lifecycle spans
/// all of them, and putting the list here keeps the auth notifier from having
/// to import every feature in the app.
final _sessionScoped = <ProviderOrFamily>[
  progressProvider,
  dashboardNotifierProvider,
  scenarioNotifierProvider,
  gamificationOverlayProvider,
  aiMentorProvider,
  marketEventsProvider,
  profileNotifierProvider,
  // Not user data, but a stale tab index would drop the next session onto
  // whatever screen the last one was looking at.
  shellTabIndexProvider,
];

/// Discard everything tied to the signed-in user.
///
/// Called on logout and on a 401 from the API client, so an expired token
/// leaves the app in the same clean state an explicit sign-out does.
void resetSessionState(Ref ref) {
  for (final provider in _sessionScoped) {
    ref.invalidate(provider);
  }
}

/// The providers [resetSessionState] clears. Exposed for tests, which assert
/// the list actually covers the user-scoped state rather than trusting it.
@visibleForTesting
List<ProviderOrFamily> get sessionScopedProviders =>
    List.unmodifiable(_sessionScoped);
