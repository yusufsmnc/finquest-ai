import 'package:dio/dio.dart';

import '../api_client.dart';
import '../dtos/achievement_dto.dart';
import '../dtos/progress_dto.dart';

/// Reads/writes the authenticated user's authoritative progress.
class ProgressRepository {
  ProgressRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<ProgressDto> getProgress() async {
    final res = await _dio.get('/me/progress');
    return ProgressDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AchievementDto>> getAchievements() async {
    final res = await _dio.get('/me/achievements');
    return (res.data as List<dynamic>)
        .map((e) => AchievementDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
