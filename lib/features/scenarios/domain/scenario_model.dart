enum RiskLevel { low, medium, high }

extension RiskLevelLabel on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }
}

class ScenarioOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String feedbackText;

  const ScenarioOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.feedbackText,
  });
}

class Scenario {
  final String id;
  final String title;
  final String description;
  final String category;
  final RiskLevel riskLevel;
  final List<ScenarioOption> options;
  final String mentorExplanation;
  final int xpCorrect;
  final int xpParticipation;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.riskLevel,
    required this.options,
    required this.mentorExplanation,
    this.xpCorrect = 50,
    this.xpParticipation = 10,
  });

  ScenarioOption? get correctOption =>
      options.where((o) => o.isCorrect).firstOrNull;
}