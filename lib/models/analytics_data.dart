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
  final double avgDailyMood;
  final double avgDailyStress;
  final int dailyMoodLogCount;
  final double avgSessionMood;
  final double avgSessionStress;
  final int sessionMoodLogCount;
  final String dailyMoodTrend;
  final String sessionMoodTrend;
  final double avgMood;
  final double avgStress;
  final int moodLogCount;
  final bool hasStressData;
  final bool hasData;

  // NEW UNIFIED FIELDS
  final double consistency; // 0 -> 1
  final double studyHours;
  final double studyDeficit;
  final double stressTrend; // slope
  final bool isStressRising;
  final int overdueTasks;
  final int upcomingTasks;
  final int dueSoonTasks;
  final double previousWeekStudyHours;
  final double previousConsistency;
  final double weeklyConsistency;
  final int totalTrackedSessions;
  final double studyGoal;

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
    this.avgDailyMood = 0.0,
    this.avgDailyStress = 0.0,
    this.dailyMoodLogCount = 0,
    this.avgSessionMood = 0.0,
    this.avgSessionStress = 0.0,
    this.sessionMoodLogCount = 0,
    this.dailyMoodTrend = 'stable',
    this.sessionMoodTrend = 'stable',
    this.avgMood = 0.0,
    this.avgStress = 0.0,
    this.moodLogCount = 0,
    this.hasStressData = false,
    this.hasData = false,
    // Unified
    this.consistency = 0.0,
    this.studyHours = 0.0,
    this.studyDeficit = 0.0,
    this.stressTrend = 0.0,
    this.isStressRising = false,
    this.overdueTasks = 0,
    this.upcomingTasks = 0,
    this.dueSoonTasks = 0,
    this.previousWeekStudyHours = 0.0,
    this.previousConsistency = 0.0,
    this.weeklyConsistency = 0.0,
    this.totalTrackedSessions = 0,
    this.studyGoal = 15.0,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      studyHoursPerCourse: {},
      gradeDistribution: {},
      taskCompletionRate: 0.0,
      completedTasks: 0,
      totalTasks: 0,
      hasData: false,
    );
  }

  bool get hasValidGpa => gradeDistribution.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'studyHoursPerCourse': studyHoursPerCourse,
      'gradeDistribution': gradeDistribution,
      'taskCompletionRate': taskCompletionRate,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'averageGPA': averageGPA,
      'weeklyAverageStudyHours': weeklyAverageStudyHours,
      'totalECTS': totalECTS,
      'riskScore': riskScore,
      'avgDailyMood': avgDailyMood,
      'avgDailyStress': avgDailyStress,
      'dailyMoodLogCount': dailyMoodLogCount,
      'avgSessionMood': avgSessionMood,
      'avgSessionStress': avgSessionStress,
      'sessionMoodLogCount': sessionMoodLogCount,
      'dailyMoodTrend': dailyMoodTrend,
      'sessionMoodTrend': sessionMoodTrend,
      'avgMood': avgMood,
      'avgStress': avgStress,
      'moodLogCount': moodLogCount,
      'hasStressData': hasStressData,
      'hasData': hasData,
      'consistency': consistency,
      'studyHours': studyHours,
      'studyDeficit': studyDeficit,
      'stressTrend': stressTrend,
      'isStressRising': isStressRising,
      'overdueTasks': overdueTasks,
      'upcomingTasks': upcomingTasks,
      'dueSoonTasks': dueSoonTasks,
      'previousWeekStudyHours': previousWeekStudyHours,
      'previousConsistency': previousConsistency,
      'weeklyConsistency': weeklyConsistency,
      'totalTrackedSessions': totalTrackedSessions,
      'studyGoal': studyGoal,
    };
  }
}
