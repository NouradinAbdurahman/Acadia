import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analytics_data.dart';
import '../repositories/analytics_repository.dart';
import 'app_providers.dart';
import 'study_sessions_provider.dart';
import 'student_profile_provider.dart';
import '../models/study_session.dart';

final analyticsJumpToTrendsTokenProvider = StateProvider<int>((ref) => 0);

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>(
  (ref) {
    final repository = ref.watch(analyticsRepositoryProvider);
    final supabase = ref.watch(supabaseProvider);
    final user = ref.watch(currentUserProvider);
    
    final notifier = AnalyticsNotifier(
      repository: repository,
      supabaseClient: supabase,
    );
    
    if (user != null) {
      notifier.loadAnalytics(user.id);
    }
    
    return notifier;
  },
);

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  final AnalyticsRepository repository;
  final SupabaseClient supabaseClient;

  AnalyticsNotifier({
    required this.repository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading());

  Future<void> loadAnalytics(String userId, {String? semesterId}) async {
    try {
      state = const AsyncValue.loading();
      final data = await repository.getAnalyticsData(userId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      await loadAnalytics(userId);
    }
  }
}

class StudyAnalytics {
  final List<StudySession> sessions;
  final int weeklyGoalMinutes;

  StudyAnalytics(this.sessions, this.weeklyGoalMinutes);

  int get todayMinutes {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  List<StudySession> get recentSessions {
    return sessions.toList();
  }

  int get shortSessions => sessions.where((s) => s.durationMinutes < 15).length;

  int get earlyStops => sessions.where((s) => !s.completed).length;

  double get avgDuration => sessions.isEmpty
      ? 0.0
      : (sessions.fold(0, (sum, s) => sum + s.durationMinutes) /
          sessions.length);

  // ── Pomodoro analytics ──
  List<StudySession> get pomodoroSessions =>
      sessions.where((s) => s.isPomodoro).toList();

  /// Ratio of fully completed Pomodoro sessions to all Pomodoro sessions (0.0–1.0)
  double get pomodoroCompletionRate {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final completed = ps.where((s) => s.completed).length;
    return completed / ps.length;
  }

  /// Average cycles per Pomodoro session
  double get averageCyclesPerSession {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final totalCycles = ps.fold<int>(0, (sum, s) => sum + (s.cyclesCompleted ?? 0));
    return totalCycles / ps.length;
  }

  /// Average focus minutes per Pomodoro session
  double get avgFocusMinutesPerSession {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final totalFocus = ps.fold<int>(0, (sum, s) => sum + (s.totalFocusMinutes ?? s.durationMinutes));
    return totalFocus / ps.length;
  }

  /// 3-tier behavioral insight about Pomodoro usage
  String getPomodoroInsight(AppLocalizations l10n) {
    if (pomodoroSessions.isEmpty) return '';
    final rate = pomodoroCompletionRate;
    if (rate >= 0.8) return l10n.pomodoroInsightConsistent;
    if (rate >= 0.4) return l10n.pomodoroInsightPartial;
    return l10n.pomodoroInsightNeedsWork;
  }

  int get sessionsThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions.where((s) => s.createdAt.isAfter(weekStart)).length;
  }

  int get activeDaysThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions
        .where((s) => s.createdAt.isAfter(weekStart))
        .map((s) => s.createdAt.day)
        .toSet()
        .length;
  }

  double get currentWeekAvg {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekSessions = sessions.where((s) => s.createdAt.isAfter(weekStart)).toList();
    if (weekSessions.isEmpty) return 0;
    return weekSessions.fold(0, (sum, s) => sum + s.durationMinutes) / weekSessions.length;
  }

  double get previousWeekAvg {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekSessions = sessions.where((s) => s.createdAt.isAfter(prevWeekStart) && s.createdAt.isBefore(weekStart)).toList();
    if (prevWeekSessions.isEmpty) return 0;
    return prevWeekSessions.fold(0.0, (sum, s) => sum + s.durationMinutes) / prevWeekSessions.length;
  }

  Map<int, int> get weeklyMinutes {
    final Map<int, int> data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    for (final s in sessions) {
      if (s.createdAt.isAfter(weekStart)) {
        final day = s.createdAt.weekday; 
        data[day] = (data[day] ?? 0) + s.durationMinutes;
      }
    }
    return data;
  }

  bool get hasData => sessions.isNotEmpty;

  int get focusScore {
    if (!hasData) return 50;
    
    // Formula:
    // durationScore (max 40) = (avgMinutes / 60) * 40
    // consistencyScore (max 30) = (sessionsThisWeek / 7) * 30
    // completionScore (max 30) = (completedCount / totalCount) * 30
    
    final durationScore = (avgDuration / 60) * 40;
    final consistencyScore = (sessionsThisWeek / 7) * 30;
    
    final completedCount = sessions.where((s) => s.completed).length;
    final completionScore = (completedCount / sessions.length) * 30;

    final score = durationScore + consistencyScore + completionScore;
    return score.clamp(0, 100).round();
  }

  String get trend {
    if (currentWeekAvg > previousWeekAvg) return "improving";
    if (currentWeekAvg < previousWeekAvg) return "declining";
    return "stable";
  }

  int get suggestedDuration {
    if (focusScore < 40) return 15;
    if (focusScore < 70) return 25;
    return 45;
  }

  bool get isStable => hasData && trend == "stable";
  
  String getFocusLabel(int minutes, AppLocalizations l10n) {
    if (minutes < 15) return l10n.lightFocus;
    if (minutes < 30) return l10n.goodFocus;
    if (minutes < 50) return l10n.deepFocus;
    return l10n.excellentDeepWork;
  }

  int calculateImpact(StudySession s) {
    final durationScore = (s.durationMinutes / 60) * 40;
    final completionScore = s.completed ? 30 : 0;
    return (durationScore + completionScore).round();
  }

  Map<String, int> get weeklyTotals {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    int thisWeek = 0;
    int lastWeek = 0;

    for (final s in sessions) {
      if (s.createdAt.isAfter(startOfThisWeek)) {
        thisWeek += s.durationMinutes;
      } else if (s.createdAt.isAfter(startOfLastWeek) && s.createdAt.isBefore(startOfThisWeek)) {
        lastWeek += s.durationMinutes;
      }
    }

    return {
      'thisWeek': thisWeek,
      'lastWeek': lastWeek,
    };
  }

  double get weeklyChange {
    final totals = weeklyTotals;
    final int thisTotal = totals['thisWeek']!;
    final int lastTotal = totals['lastWeek']!;
    if (lastTotal == 0) return thisTotal > 0 ? -1.0 : 0.0;
    return ((thisTotal - lastTotal) / lastTotal) * 100;
  }

  String getWeeklyStatus(AppLocalizations l10n) {
    final minutes = weeklyTotals['thisWeek']!;
    final activeDays = weeklyMinutes.values.where((m) => m > 0).length;
    
    if (minutes == 0) return l10n.noStudyActivityYet;
    if (activeDays == 1) return l10n.studiedOnlyOneDay;
    if (minutes < 60) return l10n.gettingStartedExtend;
    if (minutes < 180) return l10n.buildingConsistency;
    return l10n.strongConsistentPattern;
  }

  String getPeakDay(AppLocalizations l10n) {
    final data = weeklyMinutes;
    if (data.values.every((v) => v == 0)) return l10n.noActivity;
    
    int maxMin = -1;
    int peakDay = 1;
    
    data.forEach((day, min) {
      if (min > maxMin) {
        maxMin = min;
        peakDay = day;
      }
    });

    final days = ['', l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
    return "${days[peakDay]} (${formatDuration(maxMin)})";
  }

  int get currentStreak {
    if (sessions.isEmpty) return 0;

    final validSessions = sessions
        .where((s) => s.durationMinutes >= 10)
        .toList();

    if (validSessions.isEmpty) return 0;

    final days = validSessions
        .map((s) {
          final d = s.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    if (!days.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    for (final day in days) {
      if (day == current) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        if (day.isAfter(current)) continue; 
        break;
      }
    }

    return streak;
  }

  String getStreakMessage(AppLocalizations l10n) {
    final streak = currentStreak;
    if (streak == 0) return l10n.startStreakToday;
    if (streak == 1) return l10n.streakDay1;
    if (streak < 4) return l10n.buildingConsistency;
    if (streak < 7) return l10n.strongHabitForming;
    return l10n.excellentDiscipline;
  }

  bool get studiedToday {
    final today = DateTime.now();
    return sessions.any((s) {
      final d = s.createdAt.toLocal();
      return d.year == today.year &&
             d.month == today.month &&
             d.day == today.day &&
             s.durationMinutes >= 10;
    });
  }

  bool get streakWarning {
    return currentStreak > 0 && !studiedToday;
  }

  double get weeklyGoalProgress => sessions.isNotEmpty 
      ? (weeklyTotals['thisWeek']! / weeklyGoalMinutes) 
      : 0.0;

  String formatDuration(int minutes) {
    if (minutes >= 60) {
      return '${(minutes / 60).toStringAsFixed(1)}h';
    }
    return '$minutes m';
  }

  String getInsight(StudySession s, AppLocalizations l10n) {
    if (s.durationMinutes >= 45 && sessionsThisWeek >= 3) {
      return l10n.insightCycle;
    }
    if (s.durationMinutes < 25) {
      return l10n.insightStart;
    }
    return l10n.insightMomentum;
  }
}

final studyAnalyticsProvider = Provider<StudyAnalytics>((ref) {
  final sessionsAsync = ref.watch(studySessionsProvider);
  final profileAsync = ref.watch(studentProfileProvider);

  final goalHours = profileAsync.maybeWhen(
    data: (p) => p?.studyHoursPerWeek ?? 15,
    orElse: () => 15,
  );
  
  final goalMinutes = goalHours * 60;

  return sessionsAsync.maybeWhen(
    data: (sessions) => StudyAnalytics(sessions, goalMinutes),
    orElse: () => StudyAnalytics([], goalMinutes),
  );
});
