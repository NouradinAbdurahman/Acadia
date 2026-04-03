class HeatmapDay {
  final DateTime date;
  final int totalMinutes;
  final int sessionsCount;
  final int score;

  HeatmapDay({
    required this.date,
    required this.totalMinutes,
    required this.sessionsCount,
    required this.score,
  });

  factory HeatmapDay.empty(DateTime date) {
    return HeatmapDay(
      date: date,
      totalMinutes: 0,
      sessionsCount: 0,
      score: 0,
    );
  }
}
