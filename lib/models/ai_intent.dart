enum AiIntentType {
  getTasksByTimeRange,
  getCompletedTasks,
  getUpcomingDeadlines,
  getStudySummary,
  getProgress,
  getRiskStatus,
  unknown,
}

enum TimeRange {
  today,
  thisWeek,
  lastWeek,
  lastTwoWeeks,
  custom,
}

class AiFilter {
  final TimeRange? timeRange;
  final bool? isCompleted;
  final String? course;

  const AiFilter({
    this.timeRange,
    this.isCompleted,
    this.course,
  });

  @override
  String toString() => 'AiFilter(timeRange: $timeRange, isCompleted: $isCompleted, course: $course)';
}

class AiIntent {
  final AiIntentType type;
  final AiFilter filter;
  final String originalMessage;

  const AiIntent({
    required this.type,
    required this.filter,
    required this.originalMessage,
  });
}
