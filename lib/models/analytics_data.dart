class AnalyticsData {
  final Map<String, double> studyHoursPerCourse; // courseId -> hours
  final Map<String, int> gradeDistribution; // letter grade -> count
  final double taskCompletionRate;
  final int completedTasks;
  final int totalTasks;
  final double averageGPA;
  final double weeklyAverageStudyHours;
  final int totalECTS;
  final double riskScore;
  final double avgMood;
  final double avgStress;
  final int moodLogCount;

  AnalyticsData({
    required this.studyHoursPerCourse,
    required this.gradeDistribution,
    required this.taskCompletionRate,
    required this.completedTasks,
    required this.totalTasks,
    this.averageGPA = 0.0,
    this.weeklyAverageStudyHours = 0.0,
    this.totalECTS = 0,
    this.riskScore = 0.0,
    this.avgMood = 0.0,
    this.avgStress = 0.0,
    this.moodLogCount = 0,
  });

  bool get hasValidGpa => gradeDistribution.isNotEmpty;
}
