import '../models/analytics_data.dart';

/// Represents a comparison between two semesters' analytics.
class SemesterComparison {
  final AnalyticsData current;
  final AnalyticsData? previous;
  final String? previousSemesterName;
  final double? currentRiskScore;
  final double? previousRiskScore;

  SemesterComparison({
    required this.current,
    this.previous,
    this.previousSemesterName,
    this.currentRiskScore,
    this.previousRiskScore,
  });

  /// Normalize study time: convert to average hours per week instead of total hours
  double? get studyTimeDelta {
    if (previous == null) return null;
    final currAvg = current.weeklyAverageStudyHours;
    final prevAvg = previous!.weeklyAverageStudyHours;
    if (prevAvg == 0) return currAvg > 0 ? 1.0 : 0.0;
    return (currAvg - prevAvg) / prevAvg;
  }

  /// Recalculates focus using actual study hours relative to baseline or previous period.
  /// Ensures it aligns with study trend, consistency, and risk score, avoiding false 100% highs.
  double? get focusDelta {
    if (previous == null) return null;
    
    final currStudy = current.weeklyAverageStudyHours;
    final prevStudy = previous!.weeklyAverageStudyHours;
    
    // Baseline logic to prevent infinite percentage jumps
    final baseline = prevStudy > 0 ? prevStudy : 2.0;
    
    // Base focus change
    double focusRatio = (currStudy - baseline) / baseline;
    
    // Do not show 100% (or positive) if total study time decreased or is very low
    if (currStudy < prevStudy || currStudy < 1.5) {
      focusRatio = focusRatio.clamp(-1.0, 0.0);
    }
    
    // Align with study trend (consistency and risk)
    final consistencyAlign = current.consistency - previous!.consistency;
    // Risk delta: positive means risk INCREASED (bad). So we invert it for alignment.
    final riskAlign = (previous!.riskScore - current.riskScore) / 100.0;
    
    // Blend metrics for a holistic focus score
    double finalFocusDelta = (focusRatio * 0.6) + (consistencyAlign * 0.2) + (riskAlign * 0.2);
    
    return finalFocusDelta.clamp(-1.0, 1.0);
  }

  /// The task completion rate delta (e.g., +5% improvement).
  double? get completionRateDelta {
    if (previous == null) return null;
    return current.taskCompletionRate - previous!.taskCompletionRate;
  }

  /// The GPA delta (e.g., +0.3 GPA points).
  double? get gpaDelta {
    if (!hasValidGpaComparison) return null;
    return current.averageGPA - previous!.averageGPA;
  }

  /// Risk delta: negative is better (less risk)
  double? get riskDelta {
    if (currentRiskScore == null || previousRiskScore == null) return null;
    return currentRiskScore! - previousRiskScore!;
  }

  /// Handle GPA edge case: GPA exists only if course results exist.
  bool get hasValidGpaComparison {
    return previous != null && 
           current.hasValidGpa && 
           previous!.hasValidGpa && 
           previous!.averageGPA > 0;
  }

  /// The performance comparison logic upgraded for academic excellence.
  bool? get isPerformanceImproving {
    if (previous == null) return null;
    
    // indicator weights for grade-tier analysis
    int score = 0;
    if (hasValidGpaComparison && (gpaDelta ?? 0) > 0) score += 2;
    if ((completionRateDelta ?? 0) > 0) score += 1;
    if ((studyTimeDelta ?? 0) > 0) score += 1;
    if (riskDelta != null && riskDelta! < 0) score += 1;
    
    return score >= 2;
  }

  /// Generates a list of data-driven insights.
  List<String> generateInsights(dynamic l10n) {
    if (previous == null) return [];
    final insights = <String>[];

    // 1. Study Time Analysis
    final currAvg = current.weeklyAverageStudyHours;
    final prevAvg = previous!.weeklyAverageStudyHours;

    if (prevAvg > 0 && current.totalTrackedSessions > 3) {
      final diff = currAvg - prevAvg;
      final percentChange = (diff.abs() / prevAvg * 100).round();
      
      if (diff > 0 && percentChange >= 5) {
        insights.add(l10n.studyTimeDeltaMsg(l10n.increased, percentChange));
      } else if (diff < 0 && percentChange >= 5) {
        insights.add(l10n.studyTimeDeltaMsg(l10n.decreased, percentChange));
      }
    }

    // 2. Task Completion Analysis
    final cDelta = completionRateDelta ?? 0;
    if (cDelta > 0.1) {
      insights.add(l10n.taskCompletionImproved);
    } else if (cDelta < -0.1) {
      insights.add(l10n.taskCompletionDecreased);
    }

    // 3. Risk Analysis
    if (riskDelta != null && riskDelta! > 10) {
      insights.add(l10n.academicRiskIncreased);
    }

    return insights;
  }
}

extension AnalyticsDataExt on AnalyticsData {
  double get totalStudyHours {
    return studyHoursPerCourse.values.fold(0.0, (sum, hrs) => sum + hrs);
  }
}
