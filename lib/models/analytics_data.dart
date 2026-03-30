class AnalyticsData {
  final Map<String, double> studyHoursPerCourse; // courseId -> hours
  final double taskCompletionRate;
  final int completedTasks;
  final int totalTasks;

  AnalyticsData({
    required this.studyHoursPerCourse,
    required this.taskCompletionRate,
    required this.completedTasks,
    required this.totalTasks,
  });
}
