/// A single unlocked achievement (`GET /me/achievements`).
class AchievementDto {
  final String code;
  final DateTime? unlockedAt;

  const AchievementDto({required this.code, this.unlockedAt});

  factory AchievementDto.fromJson(Map<String, dynamic> json) {
    final raw = json['unlocked_at'] as String?;
    return AchievementDto(
      code: json['code'] as String,
      unlockedAt: raw == null ? null : DateTime.tryParse(raw),
    );
  }
}