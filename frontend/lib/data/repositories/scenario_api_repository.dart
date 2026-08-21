import 'package:dio/dio.dart';

import '../api_client.dart';
import '../dtos/decision_result_dto.dart';

/// Sends scenario decisions to the backend, which applies authoritative
/// gamification and returns the new progress + events.
///
/// Named `...ApiRepository` to distinguish it from the frontend's local
/// `ScenarioRepository` (which only holds static scenario content).
class ScenarioApiRepository {
  ScenarioApiRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<DecisionResultDto> postDecision(
    String scenarioId, {
    required String choice,
    required bool correct,
  }) async {
    final res = await _dio.post(
      '/scenarios/$scenarioId/decision',
      data: {'choice': choice, 'correct': correct},
    );
    return DecisionResultDto.fromJson(res.data as Map<String, dynamic>);
  }
}
