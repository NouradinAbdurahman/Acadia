/// Aggregated inputs required by the RiskCalculator.
/// All computation lives in RiskCalculator — this model is pure data.
class RiskInput {
  final int overdueTasks;
  final int upcomingTasks;
  final int totalECTS;
  final double studyHours;
  final double studyGoal;
  final double gradeRiskAdjustment;
  final dynamic stressLevel; // placeholder for Week 6

  const RiskInput({
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.totalECTS,
    required this.studyHours,
    required this.studyGoal,
    this.gradeRiskAdjustment = 0.0,
    this.stressLevel,
  });
}
