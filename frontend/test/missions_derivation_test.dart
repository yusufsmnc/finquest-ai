import 'package:flutter_test/flutter_test.dart';

import 'package:finquest_ai/data/dtos/progress_dto.dart';
import 'package:finquest_ai/features/dashboard/presentation/widgets/dashboard_challenges_section.dart';

void main() {
  group('mission/challenge progress derived from authoritative counts', () {
    const progress = ProgressDto(
      xp: 140,
      level: 2,
      streakCount: 3,
      decisionsMade: 4,
      decisionsToday: 2,
    );

    test('daily_decision ← decisions_today', () {
      expect(challengeProgressFor('daily_decision', progress), 2);
    });

    test('streak_master ← streak_count', () {
      expect(challengeProgressFor('streak_master', progress), 3);
    });

    test('risk_analyst ← total decisions_made', () {
      expect(challengeProgressFor('risk_analyst', progress), 4);
    });

    test('unknown challenge id → 0', () {
      expect(challengeProgressFor('does_not_exist', progress), 0);
    });

    test('empty progress → all zero', () {
      expect(challengeProgressFor('daily_decision', ProgressDto.empty), 0);
      expect(challengeProgressFor('streak_master', ProgressDto.empty), 0);
      expect(challengeProgressFor('risk_analyst', ProgressDto.empty), 0);
    });
  });
}
