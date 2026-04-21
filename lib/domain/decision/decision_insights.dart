import '../../models/mood_log.dart';
import '../../models/study_session.dart';

class DecisionInsights {
  const DecisionInsights._();

  static bool isStressTrendIncreasing(List<MoodLog> moods) {
    if (moods.length < 4) return false;
    final sorted = [...moods]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 6) return false;
    final last3 = recent.sublist(recent.length - 3).map((e) => e.stressLevel).toList();
    final prev3 = recent.sublist(recent.length - 6, recent.length - 3).map((e) => e.stressLevel).toList();

    final firstAvg = prev3.reduce((a, b) => a + b) / 3.0;
    final secondAvg = last3.reduce((a, b) => a + b) / 3.0;
    return (secondAvg - firstAvg) >= 1.0;
  }

  static bool isMoodTrendDeclining(List<MoodLog> moods) {
    if (moods.length < 4) return false;
    final sorted = [...moods]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 6) return false;
    final last3 = recent.sublist(recent.length - 3).map((e) => e.moodLevel).toList();
    final prev3 = recent.sublist(recent.length - 6, recent.length - 3).map((e) => e.moodLevel).toList();

    final firstAvg = prev3.reduce((a, b) => a + b) / 3.0;
    final secondAvg = last3.reduce((a, b) => a + b) / 3.0;
    return (firstAvg - secondAvg) >= 0.6;
  }

  static bool isStressTrendIncreasingFromSessions(List<StudySession> sessions) {
    if (sessions.length < 6) return false;
    final sorted = [...sessions]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 6) return false;
    final last3 = recent.sublist(recent.length - 3).where((e) => e.stress != null).map((e) => e.stress!).toList();
    final prev3 = recent.sublist(recent.length - 6, recent.length - 3).where((e) => e.stress != null).map((e) => e.stress!).toList();

    if (last3.length < 3 || prev3.length < 3) return false;

    final firstAvg = prev3.reduce((a, b) => a + b) / 3.0;
    final secondAvg = last3.reduce((a, b) => a + b) / 3.0;
    return (secondAvg - firstAvg) >= 1.0;
  }

  static bool isMoodTrendDecliningFromSessions(List<StudySession> sessions) {
    if (sessions.length < 6) return false;
    final sorted = [...sessions]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (recent.length < 6) return false;
    final last3 = recent.sublist(recent.length - 3).where((e) => e.mood != null).map((e) => e.mood!).toList();
    final prev3 = recent.sublist(recent.length - 6, recent.length - 3).where((e) => e.mood != null).map((e) => e.mood!).toList();

    if (last3.length < 3 || prev3.length < 3) return false;

    final firstAvg = prev3.reduce((a, b) => a + b) / 3.0;
    final secondAvg = last3.reduce((a, b) => a + b) / 3.0;
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
