import '../../models/mood_log.dart';

class DecisionInsights {
  const DecisionInsights._();

  static bool isStressTrendIncreasing(List<MoodLog> moods) {
    if (moods.length < 4) return false;
    final sorted = [...moods]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 4) return false;

    final mid = recent.length ~/ 2;
    final firstHalf = recent.take(mid).map((e) => e.stressLevel).toList();
    final secondHalf = recent.skip(mid).map((e) => e.stressLevel).toList();
    if (firstHalf.isEmpty || secondHalf.isEmpty) return false;

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    return (secondAvg - firstAvg) >= 1.0;
  }

  static bool isMoodTrendDeclining(List<MoodLog> moods) {
    if (moods.length < 4) return false;
    final sorted = [...moods]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 4) return false;

    final mid = recent.length ~/ 2;
    final firstHalf = recent.take(mid).map((e) => e.moodLevel).toList();
    final secondHalf = recent.skip(mid).map((e) => e.moodLevel).toList();
    if (firstHalf.isEmpty || secondHalf.isEmpty) return false;

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    return (firstAvg - secondAvg) >= 0.6;
  }

  static int? worstMoodWeekday(List<MoodLog> moods) {
    if (moods.isEmpty) return null;

    final byWeekday = <int, List<int>>{};
    for (final mood in moods) {
      byWeekday.putIfAbsent(mood.createdAt.weekday, () => <int>[]).add(mood.moodLevel);
    }

    int? worstDay;
    double? worstAvg;
    byWeekday.forEach((weekday, values) {
      if (values.isEmpty) return;
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (worstAvg == null || avg < worstAvg!) {
        worstAvg = avg;
        worstDay = weekday;
      }
    });

    return worstDay;
  }

  static String? mostFrequentFactor(List<MoodLog> moods) {
    final counts = <String, int>{};
    for (final mood in moods) {
      for (final factor in mood.factors) {
        final normalized = factor.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
