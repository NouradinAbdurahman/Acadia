import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/risk/risk_calculator.dart';
import '../domain/risk/risk_input.dart';
import '../domain/risk/risk_state.dart';
import '../domain/risk/risk_result.dart';

import '../models/course.dart';
import '../models/course_result.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/deadline.dart';

import 'app_providers.dart';
import 'deadlines_provider.dart';
import 'study_sessions_provider.dart';
import 'tasks_provider.dart';
import 'semester_provider.dart';
import 'analytics_provider.dart';
import 'mood_provider.dart';
import 'course_provider.dart';
import 'course_results_provider.dart';
import 'decision_provider.dart';

// --- DATA AGGREGATION & READINESS ---

bool _isSessionMoodSource(String source) => source.trim().toLowerCase() == 'session';

double _avgStress(List<dynamic> logs) {
  if (logs.isEmpty) return 0.0;
  final total = logs
      .map((entry) => (entry.stressLevel as num).toDouble())
      .fold<double>(0.0, (sum, value) => sum + value);
  return total / logs.length;
}

bool _isDailyMoodTrendDown(List<dynamic> dailyLogs) {
  if (dailyLogs.length < 4) return false;
  final sorted = [...dailyLogs]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final sample = sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;
  final mid = sample.length ~/ 2;
  if (mid == 0 || mid == sample.length) return false;

  double avgMood(List<dynamic> values) {
    final total = values
        .map((entry) => (entry.moodLevel as num).toDouble())
        .fold<double>(0.0, (sum, value) => sum + value);
    return total / values.length;
  }

  return (avgMood(sample.sublist(mid)) - avgMood(sample.sublist(0, mid))) < -0.35;
}

final riskInputProvider = Provider<RiskInput?>((ref) {
  final semesterAsync = ref.watch(activeSemesterProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final sessionsAsync = ref.watch(studySessionsProvider);
  final moodsAsync = ref.watch(moodLogsProvider);
  final deadlinesAsync = ref.watch(deadlinesProvider);
  final coursesAsync = ref.watch(courseProvider);
  final resultsAsync = ref.watch(courseResultsProvider);
  final studyGoalAsync = ref.watch(weeklyStudyGoalHoursProvider);

  if (semesterAsync.isLoading) return null;
  final semester = semesterAsync.value;
  if (semester == null) return null;

  // 🚨 CRITICAL: Block calculation until ALL asynchronous data sources are ready
  if (tasksAsync.isLoading ||
      sessionsAsync.isLoading ||
      moodsAsync.isLoading ||
      deadlinesAsync.isLoading ||
      coursesAsync.isLoading ||
      resultsAsync.isLoading) {
    return null;
  }

  // Extract values (fallback to empty list if data is null but finished loading)
  final tasks = tasksAsync.value ?? [];
  final sessions = sessionsAsync.value ?? [];
  final moods = moodsAsync.value ?? [];
  final deadlines = deadlinesAsync.value ?? [];
  final courses = coursesAsync.value ?? [];
  final results = resultsAsync.value ?? [];
  final studyGoal = studyGoalAsync.toDouble();

  // Filter by Semester
  final filteredTasks = tasks.where((t) => t.semesterId == semester).toList();
  final filteredSessions = sessions.where((s) => s.semesterId == semester).toList();
  final filteredMoods = moods.where((m) => m.semesterId == semester).toList();
  final filteredDeadlines = deadlines.where((d) => d.semesterId == semester).toList();
  final filteredCourses = courses.where((c) => c.semesterId == semester).toList();

  // Metric Calculations (Original logic moved into snapshot builder)
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final in3Days = startOfToday.add(const Duration(days: 3));
  final sevenDaysAgo = now.subtract(const Duration(days: 7));

  // Task metrics
  final overdue = filteredTasks.where((t) => 
    t.status != 'completed' && t.deadline != null && t.deadline!.isBefore(startOfToday)
  ).length;

  final upcoming = filteredTasks.where((t) => 
    t.status != 'completed' && 
    t.deadline != null &&
    t.deadline!.isAfter(startOfToday) && 
    t.deadline!.isBefore(in3Days)
  ).length;

  // Study metrics
  final thisWeekSessions = filteredSessions.where((s) => s.createdAt.isAfter(sevenDaysAgo)).toList();
  final currentHours = thisWeekSessions.fold<double>(0.0, (sum, s) => sum + s.durationMinutes / 60.0);
  final deficit = (studyGoal - currentHours).clamp(0.0, studyGoal);

  // ECTS & Stress
  final totalEcts = filteredCourses.fold<int>(0, (sum, c) => sum + c.ects);
  final consistency = filteredTasks.isEmpty ? 1.0 : (filteredTasks.where((t) => t.status == 'completed').length / filteredTasks.length).clamp(0.0, 1.0);
  final sessionMoods = filteredMoods.where((m) => _isSessionMoodSource(m.source ?? '')).toList();
  final avgSessionStress = _avgStress(sessionMoods);

  // Risk Adjustments
  final gradeRisk = _gradeAdjustment(results);
  final overduePenalty = _overdueDeadlinesPenalty(filteredDeadlines, startOfToday);
  final completionRelief = _linkedTaskCompletionRelief(filteredTasks, filteredDeadlines);
  final recentCompletionRelief = _completedDeadlineAdjustment(filteredDeadlines);

  final adjustment = _normalizeGradeRiskAdjustment(
    gradeRisk + overduePenalty + completionRelief + recentCompletionRelief
  );

  // hasData check (now centralized in Input)
  final hasAcademicContent = filteredCourses.isNotEmpty || filteredTasks.isNotEmpty || filteredDeadlines.isNotEmpty;
  
  // Strict validation: Do we have ANY core data to calculate for?
  final hasCoreData = filteredTasks.isNotEmpty || filteredSessions.isNotEmpty || filteredMoods.isNotEmpty;

  if (!hasCoreData) {
    return RiskInput.empty();
  }

  return RiskInput(
    overdueTasks: overdue,
    upcomingTasks: upcoming,
    totalECTS: totalEcts,
    studyHours: currentHours,
    studyGoal: studyGoal,
    studyDeficit: deficit,
    gradeRiskAdjustment: adjustment,
    avgDailyStress: _avgStress(filteredMoods),
    avgSessionStress: avgSessionStress,
    isStressRising: _isDailyMoodTrendDown(filteredMoods),
    consistency: consistency,
    hasStressData: sessionMoods.isNotEmpty,
    hasAcademicContent: hasAcademicContent,
  );
});

final riskProvider = Provider<RiskState>((ref) {
  final input = ref.watch(riskInputProvider);
  final userAsync = ref.watch(currentAppUserProvider);

  if (input == null || userAsync.isLoading) {
    return RiskState.loading();
  }

  final user = userAsync.value;
  // If input is empty OR lacks behavioral data (sessions/moods), show zero risk
  if (user == null || input.isEmpty || input.hasInsufficientData) {
    return RiskState.empty();
  }

  // 1. Calculate Primary Result
  final currentResult = RiskCalculator.calculate(input);

  // 2. Calculate Trend — use all sessions (already semester-scoped by riskInputProvider)
  final sessionsAsync = ref.watch(studySessionsProvider);
  final sessions = sessionsAsync.value ?? [];

  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final lastWeekStart = sevenDaysAgo.subtract(const Duration(days: 7));

  final lastWeekSessions = sessions.where((s) =>
    s.createdAt.isAfter(lastWeekStart) && s.createdAt.isBefore(sevenDaysAgo)
  ).toList();
  final previousHours = lastWeekSessions.fold<double>(0.0, (sum, s) => sum + s.durationMinutes / 60.0);
  final previousDeficit = (input.studyGoal - previousHours).clamp(0.0, input.studyGoal);

  final previousInput = RiskInput(
    overdueTasks: input.overdueTasks,
    upcomingTasks: input.upcomingTasks,
    totalECTS: input.totalECTS,
    studyHours: previousHours,
    studyGoal: input.studyGoal,
    studyDeficit: previousDeficit,
    gradeRiskAdjustment: input.gradeRiskAdjustment,
    avgDailyStress: input.avgDailyStress,
    avgSessionStress: input.avgSessionStress,
    isStressRising: input.isStressRising,
    consistency: input.consistency,
    hasStressData: input.hasStressData,
    hasAcademicContent: input.hasAcademicContent,
  );

  final previousResult = RiskCalculator.calculate(previousInput);
  final trendDelta = user.createdAt.isAfter(sevenDaysAgo)
      ? null
      : (currentResult.totalScore - previousResult.totalScore).toInt();

  return RiskState(
    input: input,
    result: currentResult,
    hasData: input.hasAcademicContent,
    trendDelta: trendDelta,
  );
});

String _riskLevelFromScore(double score) {
  if (score <= 30) return 'low';
  if (score <= 60) return 'medium';
  return 'high';
}

double _gradeAdjustment(List<CourseResult> results) {
  double score = 0;

  for (final result in results) {
    final code = result.letterGrade.trim().toUpperCase().split(' ').first;
    if (code == 'FF') {
      score += 10;
      continue;
    }
    if (code == 'DD' || code == 'DC') {
      score += 10;
      continue;
    }
    if (code == 'CC' || code == 'CB' || code == 'BB') {
      score += 5;
      continue;
    }
    if (code == 'BA') {
      score -= 3;
      continue;
    }
    if (code == 'AA') {
      score -= 5;
      continue;
    }
    // Ignored codes: EX, S, P, W, I, NA and others.
  }

  return score;
}

double _normalizeGradeRiskAdjustment(double raw) {
  // Keep grade/deadline modifiers meaningful without overpowering core inputs.
  return raw.clamp(-20.0, 40.0);
}

double _completedDeadlineAdjustment(List<Deadline> deadlines) {
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final completedRecently = deadlines.where((deadline) {
    if (!deadline.isCompleted) return false;
    final at = deadline.completedAt;
    return at != null && at.isAfter(sevenDaysAgo);
  }).length;

  // Reward handled deadlines without overpowering task/study risk signals.
  return -(completedRecently.clamp(0, 3) * 2).toDouble();
}

/// Academic targets past due and not marked handled increase pressure.
double _overdueDeadlinesPenalty(
  List<Deadline> deadlines,
  DateTime startOfToday,
) {
  var overdue = 0;
  for (final d in deadlines) {
    if (d.isCompleted) continue;
    final due = DateTime(
      d.deadlineDate.year,
      d.deadlineDate.month,
      d.deadlineDate.day,
    );
    if (due.isBefore(startOfToday)) overdue++;
  }
  return (overdue.clamp(0, 4) * 12.0);
}

/// Completing work linked to open deadlines slightly offsets risk.
double _linkedTaskCompletionRelief(List<Task> tasks, List<Deadline> deadlines) {
  final openIds = deadlines
      .where((d) => !d.isCompleted)
      .map((d) => d.id)
      .toSet();
  if (openIds.isEmpty) return 0.0;

  var linked = 0;
  var done = 0;
  for (final t in tasks) {
    final id = t.deadlineId;
    if (id == null || !openIds.contains(id)) continue;
    linked++;
    if (t.status == 'completed') done++;
  }
  if (linked == 0) return 0.0;
  final rate = done / linked;
  if (rate >= 0.6) return -5.0;
  return 0.0;
}
