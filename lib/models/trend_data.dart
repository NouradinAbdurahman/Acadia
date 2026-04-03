class GradePoint {
  final DateTime date;
  final double value;

  const GradePoint({required this.date, required this.value});
}

enum InsightType { good, warning, critical }

class TrendInsight {
  final InsightType type;
  final String title;
  final String message;
  final String? key;
  final Map<String, int> params;

  const TrendInsight({
    required this.type,
    required this.title,
    required this.message,
    this.key,
    this.params = const {},
  });
}

class TrendData {
  final Map<DateTime, double> studyTrend; // day -> hours
  final Map<DateTime, int> taskTrend; // day -> completed tasks
  final Map<DateTime, int> workloadTrend; // day -> tasks/deadlines created
  final List<GradePoint> gradeTrend; // chronological grade points
  final List<TrendInsight> insights;
  final double studyChangePercent;
  final double workloadChangePercent;
  final double taskCompletionRate;
  final double performanceChange;

  const TrendData({
    required this.studyTrend,
    required this.taskTrend,
    required this.workloadTrend,
    required this.gradeTrend,
    required this.insights,
    required this.studyChangePercent,
    required this.workloadChangePercent,
    required this.taskCompletionRate,
    required this.performanceChange,
  });

  const TrendData.empty()
    : studyTrend = const {},
      taskTrend = const {},
      workloadTrend = const {},
      gradeTrend = const [],
      insights = const [],
      studyChangePercent = 0,
      workloadChangePercent = 0,
      taskCompletionRate = 0,
      performanceChange = 0;
}
