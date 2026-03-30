import 'dart:math';
import 'risk_input.dart';
import 'risk_result.dart';

/// Pure, stateless calculation engine.
class RiskCalculator {
  /// Calculates the risk score and level from a [RiskInput].
  static RiskResult calculate(RiskInput input) {
    // Edge Case: No courses, no tasks, no study sessions
    if (input.totalECTS == 0 && input.overdueTasks == 0 && input.upcomingTasks == 0 && input.studyHours == 0.0) {
      return const RiskResult(
        overdueContribution: 0.0,
        upcomingContribution: 0.0,
        ectsContribution: 0.0,
        studyContribution: 0.0,
        totalScore: 0.0,
        riskLevel: 'low',
      );
    }

    // Normal calculation (Balanced model as requested by professor)
    // 1. Overdue: max ~3 tasks * 15 = 45 points
    final overdueContribution = (min(input.overdueTasks, 3) * 15.0);
    
    // 2. Upcoming: max ~3 tasks * 5 = 15 points
    final upcomingContribution = (min(input.upcomingTasks, 3) * 5.0);
    
    // 3. ECTS: 30 ECTS = 20 points (Full load normalization)
    final ectsContribution = min((input.totalECTS / 30.0) * 15.0, 15.0);

    // 4. Study Deficit: max 20 points
    double studyDeficit = 0.0;
    if (input.studyGoal > 0) {
      studyDeficit = max(0.0, (input.studyGoal - input.studyHours) / input.studyGoal);
    }
    final studyContribution = (studyDeficit * 15.0).clamp(0.0, 20.0);

    double score = overdueContribution + upcomingContribution + ectsContribution + studyContribution;
    final totalScore = score.clamp(0.0, 100.0);

    return RiskResult(
      overdueContribution: overdueContribution,
      upcomingContribution: upcomingContribution,
      ectsContribution: ectsContribution,
      studyContribution: studyContribution,
      totalScore: totalScore,
      riskLevel: _level(totalScore),
    );
  }

  static String _level(double score) {
    if (score <= 30) return 'low';
    if (score <= 60) return 'medium';
    return 'high';
  }
}
