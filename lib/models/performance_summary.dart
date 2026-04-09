import '../models/semester.dart';
import '../models/analytics_data.dart';

class PerformanceSummary {
  final Semester? bestSemester;
  final double? highestGpa;
  final Semester? worstSemester;
  final double? lowestGpa;
  final Semester? mostImprovedSemester;
  final double? improvementDelta;
  final int totalCreditsEarned;
  final List<SemesterPerformance> history;

  PerformanceSummary({
    this.bestSemester,
    this.highestGpa,
    this.worstSemester,
    this.lowestGpa,
    this.mostImprovedSemester,
    this.improvementDelta,
    this.totalCreditsEarned = 0,
    required this.history,
  });
}

class SemesterPerformance {
  final Semester semester;
  final AnalyticsData data;

  SemesterPerformance({
    required this.semester,
    required this.data,
  });
}
