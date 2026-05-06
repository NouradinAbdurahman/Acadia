import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/analytics_data.dart';
import '../models/deadline.dart';
import '../models/study_session.dart';
import '../models/task.dart';
import '../models/mood_log.dart';
import '../services/supabase/analytics_service.dart';
import '../core/services/risk_engine.dart';

class AnalyticsRepository {
  final AnalyticsService _analyticsService;

  final Map<String, AnalyticsData> _cache = {};
  final Map<String, DateTime> _lastFetch = {};
  final Map<String, Future<AnalyticsData>> _ongoingFetches = {};
  List<Map<String, dynamic>> _lastMoodLogs = [];
  static const _cacheDuration = Duration(seconds: 10);

  AnalyticsRepository(this._analyticsService);

  Future<AnalyticsData> getAnalyticsData(
    String userId, {
    required String semesterId,
  }) async {
    final now = DateTime.now();
    final cached = _cache[semesterId];
    final lastFetchTime = _lastFetch[semesterId];

    // ✅ Return cached data if still fresh for THIS semester
    if (cached != null &&
        lastFetchTime != null &&
        now.difference(lastFetchTime) < _cacheDuration) {
      return cached;
    }

    // ✅ Prevent parallel fetches for THIS semester
    if (_ongoingFetches.containsKey(semesterId)) {
      return await _ongoingFetches[semesterId]!;
    }

    final completer = _fetchAnalyticsData(userId, semesterId);
    _ongoingFetches[semesterId] = completer;
    
    try {
      final result = await completer;
      _cache[semesterId] = result;
      _lastFetch[semesterId] = DateTime.now();
      return result;
    } finally {
      _ongoingFetches.remove(semesterId);
    }
  }

  /// Computes analytics from already-loaded Dart model objects.
  /// This avoids duplicate DB queries — sessions, tasks and moods are already
  /// fetched by their own Riverpod providers. Only courses, results, and
  /// semester metadata are fetched here (not held by other providers).
  Future<AnalyticsData> computeFromPreloaded({
    required String userId,
    required String semesterId,
    required List<StudySession> sessions,
    required List<Task> tasks,
    required List<MoodLog> moodLogs,
    List<Deadline> deadlines = const [],
  }) async {
    // Bust the per-semester cache so stale data is never returned.
    _cache.remove(semesterId);
    _lastFetch.remove(semesterId);
    _ongoingFetches.remove(semesterId);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Only fetch things NOT held by other providers.
    final results = await _analyticsService.getCourseResults(
      userId: userId,
      semesterId: semesterId,
    );
    final courses = await _analyticsService.getCourses(semesterId: semesterId);
    final semData = await _analyticsService.getSemester(semesterId);

    final studyGoal = (semData?['weekly_study_goal'] ?? 15).toDouble();

    // ── Compute from typed Dart models ─────────────────────────────────────

    final hasData = sessions.isNotEmpty ||
        tasks.isNotEmpty ||
        moodLogs.isNotEmpty ||
        deadlines.isNotEmpty;

    // ── Mood stats — split by source to match UI expectations ──────────────
    // The analytics screen reads dailyMoodLogCount/sessionMoodLogCount etc.
    // Aggregate-only fields (avgMood, avgStress, moodLogCount) are also kept.
    bool isSession(MoodLog m) => m.source.trim().toLowerCase() == 'session';

    final dailyMoods = moodLogs.where((m) => !isSession(m)).toList();
    final sessionMoods = moodLogs.where((m) => isSession(m)).toList();

    // Diagnostics for Mood Classification
    debugPrint('[AnalyticsRepository] computeFromPreloaded Detail:');
    debugPrint('  - Semester: $semesterId');
    debugPrint('  - Total Moods: ${moodLogs.length}');
    debugPrint('  - Daily Classified: ${dailyMoods.length}');
    debugPrint('  - Session Classified: ${sessionMoods.length}');
    if (moodLogs.isNotEmpty && dailyMoods.isEmpty) {
      debugPrint('  - WARNING: All moods classified as session! Sample Source: "${moodLogs.first.source}"');
    }

    double avg(List<MoodLog> list, double Function(MoodLog) fn) =>
        list.isEmpty ? 0.0 : list.fold(0.0, (s, m) => s + fn(m)) / list.length;

    final avgDailyMoodVal = avg(dailyMoods, (m) => m.moodLevel.toDouble());
    final avgDailyStressVal = avg(dailyMoods, (m) => m.stressLevel.toDouble());
    final avgSessionMoodVal = avg(sessionMoods, (m) => m.moodLevel.toDouble());
    final avgSessionStressVal = avg(sessionMoods, (m) => m.stressLevel.toDouble());

    // Aggregate across all logs for backward-compatible fields.
    final avgMoodVal = avg(moodLogs, (m) => m.moodLevel.toDouble());
    final avgStressVal = avg(moodLogs, (m) => m.stressLevel.toDouble());
    final hasStressData = moodLogs.isNotEmpty;

    // Stress trend (overall)
    double stressTrend = 0.0;
    if (moodLogs.length >= 2) {
      final sorted = [...moodLogs]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      stressTrend = (sorted.last.stressLevel - sorted.first.stressLevel).toDouble();
    }

    // Consistency (distinct study days in last 7 days)
    final sessionDays = sessions.where((s) {
      return s.createdAt.isAfter(now.subtract(const Duration(days: 7)));
    }).map((s) {
      final d = s.createdAt.toLocal();
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();
    final consistency = (sessionDays.length / 7.0).clamp(0.0, 1.0);

    // This-week sessions
    final thisWeekSessions = sessions.where(
      (s) => !s.createdAt.isBefore(startOfWeek) && s.createdAt.isBefore(endOfWeek),
    ).toList();
    final thisWeekHours = thisWeekSessions.fold<double>(
      0.0, (sum, s) => sum + s.durationMinutes / 60.0);

    // Study hours per course (all-time for semester)
    final Map<String, double> hoursPerCourse = {};
    double totalHistoricalHours = 0.0;
    for (final s in sessions) {
      final h = (s.durationMinutes / 60.0).clamp(0.0, 100.0);
      totalHistoricalHours += h;
      hoursPerCourse[s.courseId] = (hoursPerCourse[s.courseId] ?? 0) + h;
    }

    // Weekly average (hours / semester weeks)
    double weeklyAvg = 0.0;
    if (semData != null) {
      final start = DateTime.tryParse(semData['start_date'] ?? '') ??
          DateTime.parse(semData['created_at']);
      final end = DateTime.tryParse(semData['end_date'] ?? '') ?? now;
      final weeks = (end.difference(start).inDays / 7.0).clamp(1.0, double.infinity);
      weeklyAvg = totalHistoricalHours / weeks;
    }

    // Task stats (this week only for completion rate) — include academic_deadlines
    // so counts match chat/unified analytics when work lives only on deadlines.
    final weeklyTasks = tasks.where((t) {
      if (t.deadline == null) return false;
      final d = DateTime(t.deadline!.year, t.deadline!.month, t.deadline!.day);
      return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
    }).toList();
    final weeklyDeadlinesInWindow = deadlines.where((dl) {
      final d = DateTime(
        dl.deadlineDate.year,
        dl.deadlineDate.month,
        dl.deadlineDate.day,
      );
      return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
    }).toList();
    final totalTasks = weeklyTasks.length + weeklyDeadlinesInWindow.length;
    final completedTasks = weeklyTasks.where((t) => t.status == 'completed').length +
        weeklyDeadlinesInWindow.where((dl) => dl.isCompleted).length;
    final rate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks.toDouble();

    // Overdue / due soon (tasks + deadlines)
    final overdueTasksCount = tasks.where((t) {
      if (t.status == 'completed') return false;
      return t.deadline != null && t.deadline!.isBefore(startOfToday);
    }).length +
        deadlines.where((dl) {
          if (dl.isCompleted) return false;
          final day = DateTime(
            dl.deadlineDate.year,
            dl.deadlineDate.month,
            dl.deadlineDate.day,
          );
          return day.isBefore(startOfToday);
        }).length;
    final dueSoonTasksCount = tasks.where((t) {
      if (t.status == 'completed') return false;
      if (t.deadline == null) return false;
      return t.deadline!.isAfter(startOfToday) &&
          t.deadline!.isBefore(startOfToday.add(const Duration(days: 3)));
    }).length +
        deadlines.where((dl) {
          if (dl.isCompleted) return false;
          final day = DateTime(
            dl.deadlineDate.year,
            dl.deadlineDate.month,
            dl.deadlineDate.day,
          );
          return day.isAfter(startOfToday) &&
              day.isBefore(startOfToday.add(const Duration(days: 3)));
        }).length;

    final gradeDistribution = <String, int>{};
    final semesterGpa = _calculateGpa(
      results: results,
      courses: courses,
      gradeDistributionOut: gradeDistribution,
    );

    final allCourses = await _analyticsService.getAllCoursesByUser(userId: userId);
    final allResults = await _analyticsService.getAllCourseResultsByUser(userId: userId);
    final cumulativeGpa = _calculateGpa(results: allResults, courses: allCourses);

    final totalEcts = courses.fold<int>(0, (s, c) => s + (c['ects'] as int? ?? 0));
    final studyDeficitHours = (studyGoal - thisWeekHours).clamp(0.0, double.infinity);

    final riskScore = _calculateSnapshotRisk(
      overdueTasks: overdueTasksCount,
      dueSoonTasks: dueSoonTasksCount,
      studyDeficitHours: studyDeficitHours,
      stressLevel: avgStressVal,
      consistency: consistency,
      hasStressData: hasStressData,
    );
    final burnoutScore = _computeBurnoutScore(
      avgStress: avgSessionStressVal,
      studyDeficit: studyDeficitHours,
      consistency: consistency,
    );

    return AnalyticsData(
      studyHoursPerCourse: hoursPerCourse,
      gradeDistribution: gradeDistribution,
      taskCompletionRate: rate,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      averageGPA: semesterGpa,
      cumulativeGPA: cumulativeGpa,
      weeklyAverageStudyHours: weeklyAvg,
      totalECTS: totalEcts,
      riskScore: riskScore,
      hasData: hasData,
      overdueTasks: overdueTasksCount,
      dueSoonTasks: dueSoonTasksCount,
      upcomingTasks: dueSoonTasksCount,
      studyDeficit: studyDeficitHours,
      consistency: consistency,
      weeklyConsistency: consistency,
      studyHours: thisWeekHours,
      // Aggregate mood (backward-compatible)
      avgMood: avgMoodVal,
      avgStress: avgStressVal,
      moodLogCount: moodLogs.length,
      hasStressData: hasStressData,
      // Split-by-source mood fields (used by Analytics screen tabs)
      avgDailyMood: avgDailyMoodVal,
      avgDailyStress: avgDailyStressVal,
      dailyMoodLogCount: dailyMoods.length,
      avgSessionMood: avgSessionMoodVal,
      avgSessionStress: avgSessionStressVal,
      sessionMoodLogCount: sessionMoods.length,
      isStressRising: stressTrend > 0.5,
      stressTrend: stressTrend,
      studyGoal: studyGoal,
      totalTrackedSessions: sessions.length,
      burnoutScore: burnoutScore,
    );
  }


  Future<AnalyticsData> _fetchAnalyticsData(
    String userId,
    String? semesterId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final sessions = await _analyticsService.getStudySessions(
        userId: userId,
        semesterId: semesterId,
      );
      final tasks = await _analyticsService.getTasks(
        userId: userId,
        semesterId: semesterId,
      );
      final results = semesterId == null
          ? const <Map<String, dynamic>>[]
          : await _analyticsService.getCourseResults(
              userId: userId,
              semesterId: semesterId,
            );
      final courses = await _analyticsService.getCourses(semesterId: semesterId);
      
      List<Map<String, dynamic>> moodLogs = [];
      try {
        moodLogs = await _analyticsService.getMoodLogs(
          userId: userId,
          startDate: startOfWeek.toUtc(),
        );
        _lastMoodLogs = moodLogs;
      } catch (e) {
        // Fallback to previous if network/Supabase errors to prevent flip
        moodLogs = _lastMoodLogs;
      }

      final hasData = sessions.isNotEmpty || tasks.isNotEmpty;

      // Settings Data
      final semData = semesterId != null ? await _analyticsService.getSemester(semesterId) : null;
      final studyGoal = (semData?['weekly_study_goal'] ?? 15).toDouble();

      // Stress Calculation
      final hasStressData = moodLogs.isNotEmpty;
      double avgStress = 0.0;
      if (moodLogs.isNotEmpty) {
        final stressSum = moodLogs.fold<double>(0.0, (sum, m) => sum + (m['stress_level'] ?? 0.0));
        avgStress = stressSum / moodLogs.length;
      }

      // Consistency Calculation (Days with sessions in last 7 days)
      final sessionDays = sessions.where((s) {
        final createdAtStr = s['created_at'];
        if (createdAtStr == null) return false;
        final date = DateTime.tryParse(createdAtStr)?.toLocal();
        return date != null && date.isAfter(now.subtract(const Duration(days: 7)));
      }).map((s) {
        final date = DateTime.parse(s['created_at']).toLocal();
        return "${date.year}-${date.month}-${date.day}";
      }).toSet();
      final consistency = (sessionDays.length / 7.0).clamp(0.0, 1.0);

      // This Week's Study Hours (for deficit calculation)
      final thisWeekSessions = sessions.where((s) {
        final createdAtStr = s['created_at'];
        if (createdAtStr == null) return false;
        final date = DateTime.tryParse(createdAtStr)?.toLocal();
        return date != null && !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
      }).toList();

      double thisWeekHours = thisWeekSessions.fold<double>(0.0, (sum, s) {
        final minutes = s['duration_minutes'] ?? 0;
        return sum + (minutes / 60.0);
      });

      // Study Hours Aggregation (Total Historical)
      Map<String, double> hoursPerCourse = {};
      double totalHistoricalHours = 0.0;
      for (final s in sessions) {
        final courseId = s['course_id'];
        if (courseId == null) continue;

        final minutes = s['duration_minutes'] ?? 0;
        final double hoursValue = (minutes / 60.0).clamp(0.0, 100.0);
        
        totalHistoricalHours += hoursValue;
        hoursPerCourse[courseId] = (hoursPerCourse[courseId] ?? 0) + hoursValue;
      }

      // Calculation of "Avg Weekly Hours"
      double weeklyAvg = 0.0;
      if (semesterId != null) {
        final semData = await _analyticsService.getSemester(semesterId);
        if (semData != null) {
          final start = DateTime.tryParse(semData['start_date'] ?? '') ?? DateTime.parse(semData['created_at']);
          final end = DateTime.tryParse(semData['end_date'] ?? '') ?? now;
          
          final weeks = max(1.0, end.difference(start).inDays / 7.0);
          weeklyAvg = totalHistoricalHours / weeks;
        }
      }

      final weeklyTasks = tasks.where((t) {
        final deadlineStr = t['deadline'];
        if (deadlineStr == null) return false;

        final dueDate = DateTime.tryParse(deadlineStr);
        if (dueDate == null) return false;

        final taskDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return !taskDay.isBefore(startOfWeek) && taskDay.isBefore(endOfWeek);
      }).toList();

      final total = weeklyTasks.length;
      final completed = weeklyTasks.where((t) {
        final status =
            t['status'] ??
            (t['is_completed'] == true ? 'completed' : 'pending');
        return status == 'completed';
      }).length;

      final rate = total == 0 ? 0.0 : completed / total.toDouble();

      final gradeDistribution = <String, int>{};
      final averageGPA = _calculateGpa(
        results: results,
        courses: courses,
        gradeDistributionOut: gradeDistribution,
      );
      final allCourses = await _analyticsService.getAllCoursesByUser(userId: userId);
      final allResults = await _analyticsService.getAllCourseResultsByUser(userId: userId);
      final cumulativeGPA = _calculateGpa(results: allResults, courses: allCourses);

      // Risk snapshot calculation for historical comparison
      final totalEcts = courses.fold<int>(0, (sum, c) => sum + (c['ects'] as int? ?? 0));
      final overdueTasksCount = tasks.where((t) {
        final status = t['status'] ?? (t['is_completed'] == true ? 'completed' : 'pending');
         if (status == 'completed') return false;
         final deadlineStr = t['deadline'];
         if (deadlineStr == null) return false;
         final dueDate = DateTime.tryParse(deadlineStr);
         return dueDate != null && dueDate.isBefore(startOfToday);
      }).length;

      final dueSoonTasksCount = tasks.where((t) {
        final status = t['status'] ?? (t['is_completed'] == true ? 'completed' : 'pending');
        if (status == 'completed') return false;
        final deadlineStr = t['deadline'];
        if (deadlineStr == null) return false;
        final dueDate = DateTime.tryParse(deadlineStr);
        if (dueDate == null) return false;
        return dueDate.isAfter(startOfToday) && 
               dueDate.isBefore(startOfToday.add(const Duration(days: 3)));
      }).length;
      
      final studyDeficitHours = max(0.0, studyGoal - thisWeekHours);

      final riskScore = _calculateSnapshotRisk(
        overdueTasks: overdueTasksCount,
        dueSoonTasks: dueSoonTasksCount,
        studyDeficitHours: studyDeficitHours,
        stressLevel: avgStress,
        consistency: consistency,
        hasStressData: hasStressData,
      );
      final burnoutScore = _computeBurnoutScore(
        avgStress: avgStress,
        studyDeficit: studyDeficitHours,
        consistency: consistency,
      );

      // Stress Trend (Simple slope of last 7 days)
      double stressTrend = 0.0;
      if (moodLogs.length >= 2) {
        final sortedLogs = [...moodLogs]..sort((a, b) => 
          DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        final first = sortedLogs.first['stress_level'] ?? 0.0;
        final last = sortedLogs.last['stress_level'] ?? 0.0;
        stressTrend = (last - first).toDouble();
      }

      final avgMoodValue = moodLogs.isEmpty 
        ? 0.0 
        : moodLogs.fold<double>(0.0, (sum, m) => sum + (m['mood_level'] ?? 0.0)) / moodLogs.length;

      return AnalyticsData(
        studyHoursPerCourse: hoursPerCourse,
        gradeDistribution: gradeDistribution,
        taskCompletionRate: rate,
        completedTasks: completed, 
        totalTasks: total,
        averageGPA: averageGPA,
        cumulativeGPA: cumulativeGPA,
        weeklyAverageStudyHours: weeklyAvg,
        totalECTS: totalEcts,
        riskScore: riskScore,
        hasData: hasData,
        overdueTasks: overdueTasksCount,
        dueSoonTasks: dueSoonTasksCount,
        upcomingTasks: dueSoonTasksCount, // For RiskInput parity
        studyDeficit: studyDeficitHours,
        consistency: consistency,
        weeklyConsistency: consistency, 
        studyHours: thisWeekHours, // Current week actual hours
        avgStress: avgStress,
        avgMood: avgMoodValue,
        moodLogCount: moodLogs.length,
        avgSessionStress: avgStress,
        avgDailyStress: avgStress,
        isStressRising: stressTrend > 0.5,
        stressTrend: stressTrend,
        studyGoal: studyGoal,
        hasStressData: hasStressData,
        burnoutScore: burnoutScore,
      );
    } catch (_) {
      rethrow;
    }
  }

  double _calculateSnapshotRisk({
    required int overdueTasks,
    required int dueSoonTasks,
    required double studyDeficitHours,
    required double stressLevel,
    required double consistency,
    bool hasStressData = false,
  }) {
    final result = RiskEngine.calculate(
      overdueTasks: overdueTasks,
      dueSoonTasks: dueSoonTasks,
      studyDeficitHours: studyDeficitHours,
      stressLevel: stressLevel,
      consistency: consistency,
      hasStressData: hasStressData,
    );
    return result.score;
  }

  double _computeBurnoutScore({
    required double avgStress,
    required double studyDeficit,
    required double consistency,
  }) {
    final stressFactor = (avgStress / 10.0).clamp(0.0, 1.0);
    final deficitFactor = (studyDeficit / 24.0).clamp(0.0, 1.0);
    final consistencyFactor = (1.0 - consistency).clamp(0.0, 1.0);
    final score =
        (stressFactor * 0.4 + deficitFactor * 0.4 + consistencyFactor * 0.2) *
            100.0;
    return score.clamp(0.0, 100.0);
  }

  double? _gradeToValue(String code) {
    const map = <String, double>{
      'AA': 4.0, 'BA': 3.5, 'BB': 3.0, 'CB': 2.5,
      'CC': 2.0, 'DC': 1.5, 'DD': 1.0, 'FF': 0.0,
    };
    return map[code];
  }

  double _calculateGpa({
    required List<Map<String, dynamic>> results,
    required List<Map<String, dynamic>> courses,
    Map<String, int>? gradeDistributionOut,
  }) {
    final courseCreditById = <String, int>{};
    for (final course in courses) {
      final courseId = (course['id'] as String?) ?? '';
      if (courseId.isEmpty) continue;
      final credits = (course['credits'] as int?) ?? 0;
      if (credits > 0) courseCreditById[courseId] = credits;
    }

    // University policy: for retaken courses, only the latest attempt counts.
    final latestResultByCourse = <String, Map<String, dynamic>>{};
    for (final result in results) {
      final courseId = (result['course_id'] as String?) ?? '';
      if (courseId.isEmpty) continue;
      final existing = latestResultByCourse[courseId];
      if (existing == null) {
        latestResultByCourse[courseId] = result;
        continue;
      }

      final existingDate = _resultTimestamp(existing);
      final nextDate = _resultTimestamp(result);
      if (nextDate.isAfter(existingDate)) latestResultByCourse[courseId] = result;
    }

    double weightedGradePoints = 0.0;
    int totalWeightedCredits = 0;
    double unweightedGradePoints = 0.0;
    int unweightedCount = 0;

    for (final result in latestResultByCourse.values) {
      final code = _normalizeGradeCode(result['letter_grade'] as String?);
      if (code == null) continue;
      gradeDistributionOut?.update(code, (value) => value + 1, ifAbsent: () => 1);
      final gradeValue = _gradeToValue(code);
      if (gradeValue == null) continue;

      unweightedGradePoints += gradeValue;
      unweightedCount++;

      final courseId = (result['course_id'] as String?) ?? '';
      final credits = courseCreditById[courseId] ?? 0;
      if (credits <= 0) continue;
      weightedGradePoints += gradeValue * credits;
      totalWeightedCredits += credits;
    }

    if (totalWeightedCredits > 0) {
      final weighted = weightedGradePoints / totalWeightedCredits;
      if (weighted.isFinite) return weighted;
    }
    if (unweightedCount > 0) {
      final fallback = unweightedGradePoints / unweightedCount;
      if (fallback.isFinite) return fallback;
    }
    return 0.0;
  }

  DateTime _resultTimestamp(Map<String, dynamic> result) {
    final updatedRaw = result['updated_at'] as String?;
    final createdRaw = result['created_at'] as String?;
    return DateTime.tryParse(updatedRaw ?? '') ??
        DateTime.tryParse(createdRaw ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  String? _normalizeGradeCode(String? rawGrade) {
    final normalized = (rawGrade ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return normalized.split(' ').first;
  }
}
