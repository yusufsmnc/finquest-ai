class ProfileState {
  final String displayName;
  final int avatarIndex;
  final int bestStreak;

  const ProfileState({
    this.displayName = 'Investor',
    this.avatarIndex = 0,
    this.bestStreak = 0,
  });

  ProfileState copyWith({
    String? displayName,
    int? avatarIndex,
    int? bestStreak,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}