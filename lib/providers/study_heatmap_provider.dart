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

  // If sessions are refreshing but we have previous data, pass through loading
  // WITH the previous heatmap so the widget doesn't tear down the scroll view.
  if (sessionsAsync.isLoading && !sessionsAsync.hasValue) {
    return const AsyncValue.loading();
  }

  // Use previous sessions value while refreshing so we can still compute.
  final sessions = sessionsAsync.valueOrNull ?? [];

  final today = normalize(DateTime.now());

  // Show roughly a year, aligned so the first row is always Monday.
  final firstDayToShow = today.subtract(const Duration(days: 364));
  final paddingStart = firstDayToShow.weekday - 1;
  final startDate = normalize(firstDayToShow.subtract(Duration(days: paddingStart)));

  final paddingEnd = 7 - today.weekday;
  final endDate = normalize(today.add(Duration(days: paddingEnd)));

  final Map<DateTime, List<int>> dailyStats = {};
  final totalDays = endDate.difference(startDate).inDays + 1;

  for (int i = 0; i < totalDays; i++) {
    final date = normalize(startDate.add(Duration(days: i)));
    dailyStats[date] = [0, 0];
  }

  int maxScore = 1;

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

  final result = HeatmapData(days: heatmapDays, maxScore: maxScore);

  // Wrap in the same async state as sessions so callers can see isLoading.
  if (sessionsAsync.isLoading) {
    // Loading with known previous value — UI keeps showing current data.
    return AsyncValue<HeatmapData>.loading().copyWithPrevious(AsyncValue.data(result));
  }
  if (sessionsAsync.hasError) {
    return AsyncValue.error(sessionsAsync.error!, sessionsAsync.stackTrace!);
  }
  return AsyncValue.data(result);
});

