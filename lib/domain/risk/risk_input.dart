/// Aggregated inputs required by the RiskCalculator.
/// All computation lives in RiskCalculator — this model is pure data.
class RiskInput {
  final int overdueTasks;
  final int upcomingTasks;
  final int totalECTS;
  final double studyHours;
  final double studyGoal;
  final double studyDeficit;
  final double gradeRiskAdjustment;
  final double avgDailyStress;
  final double avgSessionStress;
  final bool isStressRising;
  final double consistency;
  final bool hasStressData;
  final bool hasAcademicContent;
  final dynamic stressLevel;

  const RiskInput({
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.totalECTS,
    required this.studyHours,
    required this.studyGoal,
    this.studyDeficit = 0.0,
    this.gradeRiskAdjustment = 0.0,
    this.avgDailyStress = 0.0,
    this.avgSessionStress = 0.0,
    this.isStressRising = false,
    this.consistency = 0.0,
    this.hasStressData = false,
    this.hasAcademicContent = false,
    this.stressLevel,
  });

  factory RiskInput.empty() => const RiskInput(
        overdueTasks: 0,
        upcomingTasks: 0,
        totalECTS: 0,
        studyHours: 0,
        studyGoal: 0.0,
      );

  bool get isEmpty => overdueTasks == 0 && upcomingTasks == 0 && studyHours == 0 && totalECTS == 0;

  /// Returns true if we lack the behavioral data (sessions/moods) 
  /// required for a high-confidence academic risk assessment.
  bool get hasInsufficientData => studyHours == 0 && !hasStressData;
}
