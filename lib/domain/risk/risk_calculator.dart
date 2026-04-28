import '../../core/services/risk_engine.dart' as core;
import 'risk_input.dart';
import 'risk_result.dart';

/// Pure, stateless calculation engine.
class RiskCalculator {
  /// Calculates the risk score and level from a [RiskInput].
  static RiskResult calculate(RiskInput input) {
    final coreResult = core.RiskEngine.calculate(
      overdueTasks: input.overdueTasks,
      dueSoonTasks: input.upcomingTasks,
      studyDeficitHours: input.studyDeficit,
      stressLevel: input.avgSessionStress,
      consistency: input.consistency,
      hasStressData: input.hasStressData,
    );

    final finalScore = coreResult.score;

    return RiskResult(
      overdueContribution: coreResult.breakdown['overdue'] ?? 0.0,
      upcomingContribution: coreResult.breakdown['dueSoon'] ?? 0.0,
      ectsContribution: 0.0, 
      studyContribution: coreResult.breakdown['deficit'] ?? 0.0,
      sessionStressContribution: coreResult.breakdown['stress'] ?? 0.0,
      consistencyContribution: coreResult.breakdown['consistency'] ?? 0.0,
      totalScore: finalScore,
      riskLevel: _level(finalScore),
    );
  }

  static String _level(double score) {
    if (score < 30) return 'low';
    if (score < 60) return 'medium';
    return 'high';
  }
}
