import 'package:dio/dio.dart';

import '../api_client.dart';
import '../dtos/mentor_dto.dart';

/// Talks to `POST /mentor`. The backend owns the LLM call and its fallback, so
/// this repository has no notion of prompts, models or keys.
class MentorApiRepository {
  MentorApiRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<MentorResponseDto> fetchMessage(MentorRequestDto request) async {
    final res = await _dio.post('/mentor', data: request.toJson());
    return MentorResponseDto.fromJson(res.data as Map<String, dynamic>);
  }
}
