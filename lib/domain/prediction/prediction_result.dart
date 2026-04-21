enum PredictionLevel { low, medium, high }

class StudyPlanItem {
  final DateTime scheduledAt;
  final int durationMinutes;
  final String focusKey;

  const StudyPlanItem({
    required this.scheduledAt,
    required this.durationMinutes,
    required this.focusKey,
  });
}

class PredictionResult {
  final double predictedStress;
  final PredictionLevel stressLevel;
  final List<String> stressReasons;
  final List<String> explanationKeys;

  final double performanceRiskScore;
  final PredictionLevel performanceRiskLevel;
  final List<String> laggingCourses;

  final List<StudyPlanItem> recommendedPlan;
  final double confidence;

  const PredictionResult({
    required this.predictedStress,
    required this.stressLevel,
    required this.stressReasons,
    required this.explanationKeys,
    required this.performanceRiskScore,
    required this.performanceRiskLevel,
    required this.laggingCourses,
    required this.recommendedPlan,
    required this.confidence,
  });

  const PredictionResult.empty()
      : predictedStress = 0,
        stressLevel = PredictionLevel.low,
        stressReasons = const <String>[],
        explanationKeys = const <String>[],
        performanceRiskScore = 0,
        performanceRiskLevel = PredictionLevel.low,
        laggingCourses = const <String>[],
        recommendedPlan = const <StudyPlanItem>[],
        confidence = 0;

  bool get hasData =>
      stressReasons.isNotEmpty ||
      explanationKeys.isNotEmpty ||
      laggingCourses.isNotEmpty ||
      recommendedPlan.isNotEmpty;
}
