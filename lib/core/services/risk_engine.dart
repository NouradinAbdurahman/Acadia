
import 'package:flutter/foundation.dart';

enum RiskLevel { low, moderate, high }

class RiskResult {
  final double score;
  final RiskLevel level;
  final List<String> reasons;
  final Map<String, double> breakdown;

  RiskResult({
    required this.score, 
    required this.level, 
    required this.reasons,
    required this.breakdown,
  });
}

class RiskEngine {
  /// The single source of truth for academic risk calculation.
  /// Follows the strict mathematical weighting requested by the user.
  static RiskResult calculate({
    required int overdueTasks,
    required int dueSoonTasks,
    required double studyDeficitHours,
    required double stressLevel,
    required double consistency,
    bool hasStressData = false,
    // Note: totalTasks and gpa kept for backward compatibility if needed, 
    // but the core formula prioritizes the user's specific requirements.
    int totalTasks = 0,
    double gpa = 0,
  }) {
    double score = 0;
    final reasons = <String>[];
    
    // 1. Overdue tasks (0 - 30)
    // 10 points per task, caps at 3 tasks for 30 points.
    final overdueScore = (overdueTasks * 10.0).clamp(0.0, 30.0);
    if (overdueTasks > 0) reasons.add("$overdueTasks overdue tasks");

    // 2. Tasks due soon (0 - 15)
    // 5 points per task, caps at 3 tasks for 15 points.
    final dueSoonScore = (dueSoonTasks * 5.0).clamp(0.0, 15.0);
    if (dueSoonTasks > 0) reasons.add("$dueSoonTasks tasks due soon");

    // 3. Study deficit (0 - 25)
    // Max 25 points. Normalized against 24 hours of deficit.
    // A 24h deficit means you missed ~3.5 days of study in a week.
    final deficitScore = ((studyDeficitHours / 24.0) * 25.0).clamp(0.0, 25.0);
    if (studyDeficitHours > 5) {
      reasons.add("Study deficit of ${studyDeficitHours.toStringAsFixed(1)}h");
    }

    // 4. Stress (0 - 15)
    // Stress is 0-10, weight is 15.
    double stressScore = 0.0;
    if (hasStressData) {
      stressScore = ((stressLevel / 10.0) * 15.0).clamp(0.0, 15.0);
      if (stressLevel >= 7) reasons.add("High stress levels reported");
    }

    // 5. Consistency penalty (0 - 15)
    // 1.0 consistency = 0 penalty. 0.0 consistency = 15 penalty.
    final consistencyScore = ((1.0 - consistency) * 15.0).clamp(0.0, 15.0);
    if (consistency < 0.4) reasons.add("Low study consistency");

    // Final Score: Strictly additive (30 + 15 + 25 + 15 + 15 = 100)
    final totalRaw = overdueScore + dueSoonScore + deficitScore + stressScore + consistencyScore;
    final finalScore = totalRaw.clamp(0.0, 100.0);

    // Removed duplicate logging - see risk_provider.dart for unified logging

    final breakdown = {
      'overdue': overdueScore,
      'dueSoon': dueSoonScore,
      'deficit': deficitScore,
      'stress': stressScore,
      'consistency': consistencyScore,
    };

    RiskLevel level;
    if (finalScore >= 60) {
      level = RiskLevel.high;
    } else if (finalScore >= 30) {
      level = RiskLevel.moderate;
    } else {
      level = RiskLevel.low;
    }

    return RiskResult(
      score: finalScore, 
      level: level, 
      reasons: reasons,
      breakdown: breakdown,
    );
  }
}
