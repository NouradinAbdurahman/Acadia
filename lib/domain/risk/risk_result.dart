/// The output of the RiskCalculator.
/// Encapsulates the final 0-100 score, its conceptual level, and the breakdown logic.
class RiskResult {
  final double overdueContribution;
  final double upcomingContribution;
  final double ectsContribution;
  final double studyContribution;
  final double totalScore;
  final String riskLevel;

  const RiskResult({
    required this.overdueContribution,
    required this.upcomingContribution,
    required this.ectsContribution,
    required this.studyContribution,
    required this.totalScore,
    required this.riskLevel,
  });
}
