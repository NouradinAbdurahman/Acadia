class AnalyticsData {
  final Map<String, double> studyHoursPerCourse; // courseId -> hours
  final Map<String, int> gradeDistribution; // letter grade -> count
  final double taskCompletionRate;
  final int completedTasks;
  final int totalTasks;

  AnalyticsData({
    required this.studyHoursPerCourse,
    required this.gradeDistribution,
    required this.taskCompletionRate,
    required this.completedTasks,
    required this.totalTasks,
  });
}
