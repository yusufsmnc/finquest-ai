import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/dashboard_providers.dart';
import '../domain/profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Track best streak reactively — no new events needed
    ref.listen(
      dashboardNotifierProvider.select((s) => s.currentStreak),
      (_, streak) {
        if (streak > state.bestStreak) {
          state = state.copyWith(bestStreak: streak);
        }
      },
    );
    return const ProfileState();
  }

  void setDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      state = state.copyWith(displayName: trimmed);
    }
  }

  void setAvatar(int index) {
    state = state.copyWith(avatarIndex: index);
  }
}