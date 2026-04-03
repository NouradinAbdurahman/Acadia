import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heatmap_day.dart';
import 'study_sessions_provider.dart';

class HeatmapData {
  final List<HeatmapDay> days;
  final int maxScore;

  HeatmapData({required this.days, required this.maxScore});
}

final studyHeatmapProvider = Provider<AsyncValue<HeatmapData>>((ref) {
  final sessionsAsync = ref.watch(studySessionsProvider);

  DateTime normalize(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  return sessionsAsync.whenData((sessions) {
    final today = normalize(DateTime.now());
    
    // We want to show roughly a year, aligned so that the first row is always Monday and last is Sunday.
    final firstDayToShow = today.subtract(const Duration(days: 364));
    final paddingStart = firstDayToShow.weekday - 1; // 0 for Mon, 6 for Sun
    final startDate = normalize(firstDayToShow.subtract(Duration(days: paddingStart)));
    
    final paddingEnd = 7 - today.weekday; // 0 for Sun, 4 for Wed, etc.
    final endDate = normalize(today.add(Duration(days: paddingEnd)));
    
    final Map<DateTime, List<int>> dailyStats = {};
    
    // Calculate total days to show (last 364 days + start padding + end padding)
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    // Initialize map with empty stats for every day in the range
    for (int i = 0; i < totalDays; i++) {
       final date = normalize(startDate.add(Duration(days: i)));
       dailyStats[date] = [0, 0];
    }

    int maxScore = 1; // Avoid division by zero

    // Group sessions by normalized local date
    for (final session in sessions) {
      final dayKey = normalize(session.createdAt);
      
      if (dailyStats.containsKey(dayKey)) {
        dailyStats[dayKey]![0] += session.durationMinutes;
        dailyStats[dayKey]![1] += 1;
        
        final currentScore = dailyStats[dayKey]![0] + (dailyStats[dayKey]![1] * 5);
        if (currentScore > maxScore) maxScore = currentScore;
      }
    }

    final List<HeatmapDay> heatmapDays = [];
    for (int i = 0; i < totalDays; i++) {
      final date = normalize(startDate.add(Duration(days: i)));
      final stats = dailyStats[date] ?? [0, 0];
      final minutes = stats[0];
      final sessionsCount = stats[1];
      final score = minutes + (sessionsCount * 5);
      
      heatmapDays.add(HeatmapDay(
        date: date,
        totalMinutes: minutes,
        sessionsCount: sessionsCount,
        score: score,
      ));
    }

    return HeatmapData(days: heatmapDays, maxScore: maxScore);
  });
});

