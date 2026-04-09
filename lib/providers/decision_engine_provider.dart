import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/deadline.dart';
import '../models/decision_snapshot.dart';
import '../models/task.dart';
import '../models/trend_data.dart';
import 'analytics_provider.dart';
import 'course_provider.dart';
import 'deadlines_provider.dart';
import 'tasks_provider.dart';
import 'trend_provider.dart';

final decisionEngineProvider = Provider<AsyncValue<DecisionSnapshot>>((ref) {
  final coursesAsync = ref.watch(courseProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final deadlinesAsync = ref.watch(deadlinesProvider);
  final analyticsAsync = ref.watch(analyticsProvider);
  final trendAsync = ref.watch(trendProvider(7));
  final studyAnalytics = ref.watch(studyAnalyticsProvider);

  if (coursesAsync.isLoading ||
      tasksAsync.isLoading ||
      deadlinesAsync.isLoading ||
      analyticsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final error = coursesAsync.asError?.error ??
      tasksAsync.asError?.error ??
      deadlinesAsync.asError?.error ??
      analyticsAsync.asError?.error;
  if (error != null) {
    return AsyncValue.data(_fallbackDecisionSnapshot());
  }

  final courses = coursesAsync.value ?? const <Course>[];
  final tasks = tasksAsync.value ?? const <Task>[];
  final deadlines = deadlinesAsync.value ?? const <Deadline>[];
  final analyticsData = analyticsAsync.value;
  final trendData = trendAsync.value ?? const TrendData.empty();

  if (courses.isEmpty || analyticsData == null) {
    return AsyncValue.data(_fallbackDecisionSnapshot());
  }

  final snapshot = buildDecisionSnapshotV1(
    courses: courses,
    tasks: tasks,
    deadlines: deadlines,
    studyHoursByCourse: analyticsData.studyHoursPerCourse,
    trendData: trendData,
    studyAnalytics: studyAnalytics,
  );

  return AsyncValue.data(snapshot);
});

DecisionSnapshot buildDecisionSnapshotV1({
  required List<Course> courses,
  required List<Task> tasks,
  required List<Deadline> deadlines,
  required Map<String, double> studyHoursByCourse,
  required TrendData trendData,
  required StudyAnalytics studyAnalytics,
  BurnoutLevel? burnoutLevelOverride,
}) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final upcomingLimit = startOfToday.add(const Duration(days: 7));

  final courseById = <String, Course>{for (final c in courses) c.id: c};
  final studiedHours = <String, double>{for (final c in courses) c.id: 0};
  for (final entry in studyHoursByCourse.entries) {
    if (courseById.containsKey(entry.key)) {
      studiedHours[entry.key] = entry.value;
    }
  }

  final totalEcts = courses.fold<int>(0, (sum, course) => sum + course.ects);
  final weeklyGoalHours = studyAnalytics.weeklyGoalHours;
  final targetHoursByCourse = <String, double>{
    for (final course in courses)
      course.id: _targetHoursForCourse(
        course: course,
        totalEcts: totalEcts,
        weeklyGoalHours: weeklyGoalHours,
        courseCount: courses.length,
      ),
  };

  final overdueCountByCourse = <String, int>{for (final c in courses) c.id: 0};
  final openTasksByCourse = <String, int>{for (final c in courses) c.id: 0};

  for (final task in tasks) {
    final courseId = task.courseId;
    if (courseId == null || !courseById.containsKey(courseId)) continue;

    if (!task.isCompleted) {
      openTasksByCourse[courseId] = (openTasksByCourse[courseId] ?? 0) + 1;
    }

    final isOverdue = !task.isCompleted &&
        (task.status == 'overdue' ||
            (task.deadline != null && task.deadline!.isBefore(startOfToday)));
    if (isOverdue) {
      overdueCountByCourse[courseId] = (overdueCountByCourse[courseId] ?? 0) + 1;
    }
  }

  final pendingDeadlines = deadlines.where((d) => !d.isCompleted).toList();
  for (final deadline in pendingDeadlines) {
    final courseId = deadline.courseId;
    if (courseId == null || !courseById.containsKey(courseId)) continue;

    if (deadline.deadlineDate.isBefore(startOfToday)) {
      overdueCountByCourse[courseId] = (overdueCountByCourse[courseId] ?? 0) + 1;
    }
  }

  final overdueCourses = overdueCountByCourse.entries
      .where((entry) => entry.value > 0)
      .map((entry) => courseById[entry.key]!)
      .toList();

  DecisionNextAction nextAction;
  DecisionConfidence nextActionConfidence;
  if (overdueCourses.isNotEmpty) {
    overdueCourses.sort((a, b) {
      final overdueCmp = (overdueCountByCourse[b.id] ?? 0)
          .compareTo(overdueCountByCourse[a.id] ?? 0);
      if (overdueCmp != 0) return overdueCmp;
      final studyCmp = (studiedHours[a.id] ?? 0).compareTo(studiedHours[b.id] ?? 0);
      if (studyCmp != 0) return studyCmp;
      return b.ects.compareTo(a.ects);
    });

    final picked = overdueCourses.first;
    final duration = _applyBurnoutGuard(
      baseMinutes: 90,
      studyAnalytics: studyAnalytics,
      burnoutLevelOverride: burnoutLevelOverride,
    );

    nextAction = DecisionNextAction(
      courseId: picked.id,
      courseName: picked.courseName,
      durationMinutes: duration,
      reason:
          'Overdue tasks need immediate attention\nYou studied ${_hours(studiedHours[picked.id] ?? 0)}h of your ${_hours(targetHoursByCourse[picked.id] ?? 0)}h target',
    );
    nextActionConfidence = DecisionConfidence.high;
  } else {
    final upcomingByCourse = <String, int>{};
    for (final deadline in pendingDeadlines) {
      final courseId = deadline.courseId;
      if (courseId == null || !courseById.containsKey(courseId)) continue;
      if (deadline.deadlineDate.isBefore(startOfToday) ||
          deadline.deadlineDate.isAfter(upcomingLimit)) {
        continue;
      }
      final days = deadline.deadlineDate.difference(startOfToday).inDays;
      final current = upcomingByCourse[courseId];
      if (current == null || days < current) {
        upcomingByCourse[courseId] = days;
      }
    }

    if (upcomingByCourse.isNotEmpty) {
      final candidates = upcomingByCourse.keys.map((id) => courseById[id]!).toList();
      candidates.sort((a, b) {
        final daysCmp = (upcomingByCourse[a.id] ?? 99).compareTo(upcomingByCourse[b.id] ?? 99);
        if (daysCmp != 0) return daysCmp;
        final studyCmp = (studiedHours[a.id] ?? 0).compareTo(studiedHours[b.id] ?? 0);
        if (studyCmp != 0) return studyCmp;
        return b.ects.compareTo(a.ects);
      });

      final picked = candidates.first;
      final days = upcomingByCourse[picked.id] ?? 7;
      final base = _deadlineBaseMinutes(days);
      final duration = _applyBurnoutGuard(
        baseMinutes: base,
        studyAnalytics: studyAnalytics,
        burnoutLevelOverride: burnoutLevelOverride,
      );

      nextAction = DecisionNextAction(
        courseId: picked.id,
        courseName: picked.courseName,
        durationMinutes: duration,
        reason:
          'Deadline in $days days\nYou studied ${_hours(studiedHours[picked.id] ?? 0)}h of your ${_hours(targetHoursByCourse[picked.id] ?? 0)}h target\nImportant course (${picked.ects} ECTS)',
      );
      final deficit = _deficitRatio(
        studied: studiedHours[picked.id] ?? 0,
        target: targetHoursByCourse[picked.id] ?? 0,
      );
      nextActionConfidence = deficit >= 0.18
          ? DecisionConfidence.high
          : DecisionConfidence.medium;
    } else {
      final leastStudied = [...courses]
        ..sort((a, b) {
          final studyCmp = (studiedHours[a.id] ?? 0).compareTo(studiedHours[b.id] ?? 0);
          if (studyCmp != 0) return studyCmp;
          final ectsCmp = b.ects.compareTo(a.ects);
          if (ectsCmp != 0) return ectsCmp;
          return (openTasksByCourse[b.id] ?? 0).compareTo(openTasksByCourse[a.id] ?? 0);
        });

      final picked = leastStudied.first;
      final duration = _applyBurnoutGuard(
        baseMinutes: 60,
        studyAnalytics: studyAnalytics,
        burnoutLevelOverride: burnoutLevelOverride,
      );
      nextAction = DecisionNextAction(
        courseId: picked.id,
        courseName: picked.courseName,
        durationMinutes: duration,
        reason:
          'You studied ${_hours(studiedHours[picked.id] ?? 0)}h of your ${_hours(targetHoursByCourse[picked.id] ?? 0)}h target\nNo urgent deadlines. Stay consistent.',
      );
      nextActionConfidence = DecisionConfidence.low;
    }
  }

  final focusCourse = _pickFocusCourse(
    courses: courses,
    studiedHours: studiedHours,
    openTasksByCourse: openTasksByCourse,
    pendingDeadlines: pendingDeadlines,
    startOfToday: startOfToday,
  );

  DecisionFocusRecommendation? focusRecommendation;
  if (focusCourse != null && focusCourse.id != nextAction.courseId) {
    final focusReason = _focusReason(
      course: focusCourse,
      studiedHours: studiedHours[focusCourse.id] ?? 0,
      openTasks: openTasksByCourse[focusCourse.id] ?? 0,
      pendingDeadlines: pendingDeadlines,
      startOfToday: startOfToday,
    );

    focusRecommendation = DecisionFocusRecommendation(
      courseId: focusCourse.id,
      courseName: focusCourse.courseName,
      reason: focusReason,
    );
  }

  final comparativeCourseName = focusRecommendation?.courseName;
  if (comparativeCourseName != null && comparativeCourseName.isNotEmpty) {
    nextAction = DecisionNextAction(
      courseId: nextAction.courseId,
      courseName: nextAction.courseName,
      durationMinutes: nextAction.durationMinutes,
      reason:
          '${nextAction.reason}\nMore urgent than $comparativeCourseName',
      confidence: nextActionConfidence,
      higherPriorityThanCourseName: comparativeCourseName,
    );
  } else {
    nextAction = DecisionNextAction(
      courseId: nextAction.courseId,
      courseName: nextAction.courseName,
      durationMinutes: nextAction.durationMinutes,
      reason: nextAction.reason,
      confidence: nextActionConfidence,
      higherPriorityThanCourseName: null,
    );
  }

  final whatChanged = DecisionWhatChanged(
    study: _changeLabel(trendData.studyChangePercent),
    taskLoad: _changeLabel(trendData.workloadChangePercent),
    performance: _performanceLabel(trendData.performanceChange),
  );

  return DecisionSnapshot(
    nextAction: nextAction,
    focusRecommendation: focusRecommendation,
    todayPlanSecondaryRecommendation: focusRecommendation,
    whatChanged: whatChanged,
  );
}

DecisionSnapshot _fallbackDecisionSnapshot() {
  return const DecisionSnapshot(
    nextAction: DecisionNextAction(
      courseId: '',
      courseName: 'any course',
      durationMinutes: 45,
      reason: 'Fallback recommendation: keep your consistency this week',
      confidence: DecisionConfidence.low,
    ),
    focusRecommendation: null,
    todayPlanSecondaryRecommendation: null,
    whatChanged: DecisionWhatChanged(
      study: 'Stable',
      taskLoad: 'Stable',
      performance: 'Stable',
    ),
  );
}

double _targetHoursForCourse({
  required Course course,
  required int totalEcts,
  required double weeklyGoalHours,
  required int courseCount,
}) {
  if (courseCount <= 0) return 0.75;
  final ectsShare = totalEcts > 0 ? (course.ects / totalEcts) : (1.0 / courseCount);
  return (weeklyGoalHours * ectsShare).clamp(0.75, 40.0);
}

double _deficitRatio({required double studied, required double target}) {
  if (target <= 0) return 0;
  return ((target - studied) / target).clamp(0.0, 1.0);
}

String _hours(double value) => value.toStringAsFixed(1);

int _deadlineBaseMinutes(int days) {
  if (days <= 2) return 90;
  if (days <= 4) return 75;
  if (days <= 7) return 60;
  return 60;
}

int _applyBurnoutGuard({
  required int baseMinutes,
  required StudyAnalytics studyAnalytics,
  BurnoutLevel? burnoutLevelOverride,
}) {
  final level = burnoutLevelOverride ?? studyAnalytics.burnoutLevel;
  final cap = switch (level) {
    BurnoutLevel.highRisk => 60,
    BurnoutLevel.burnoutRisk => 60,
    BurnoutLevel.warning => 75,
    BurnoutLevel.stable => baseMinutes,
  };

  final guarded = baseMinutes > cap ? cap : baseMinutes;
  return guarded < 45 ? 45 : guarded;
}

Course? _pickFocusCourse({
  required List<Course> courses,
  required Map<String, double> studiedHours,
  required Map<String, int> openTasksByCourse,
  required List<Deadline> pendingDeadlines,
  required DateTime startOfToday,
}) {
  if (courses.isEmpty) return null;

  final nearestDaysByCourse = <String, int>{};
  for (final deadline in pendingDeadlines) {
    final courseId = deadline.courseId;
    if (courseId == null) continue;

    final days = deadline.deadlineDate.difference(startOfToday).inDays;
    if (days < 0) continue;

    final current = nearestDaysByCourse[courseId];
    if (current == null || days < current) {
      nearestDaysByCourse[courseId] = days;
    }
  }

  final candidates = [...courses]
    ..sort((a, b) {
      final studyCmp = (studiedHours[a.id] ?? 0).compareTo(studiedHours[b.id] ?? 0);
      if (studyCmp != 0) return studyCmp;

      final aDays = nearestDaysByCourse[a.id] ?? 999;
      final bDays = nearestDaysByCourse[b.id] ?? 999;
      final dayCmp = aDays.compareTo(bDays);
      if (dayCmp != 0) return dayCmp;

      final openCmp = (openTasksByCourse[b.id] ?? 0).compareTo(openTasksByCourse[a.id] ?? 0);
      if (openCmp != 0) return openCmp;

      return b.ects.compareTo(a.ects);
    });

  return candidates.first;
}

String _focusReason({
  required Course course,
  required double studiedHours,
  required int openTasks,
  required List<Deadline> pendingDeadlines,
  required DateTime startOfToday,
}) {
  int? nearestDays;
  for (final deadline in pendingDeadlines) {
    if (deadline.courseId != course.id) continue;
    final days = deadline.deadlineDate.difference(startOfToday).inDays;
    if (days < 0) continue;
    if (nearestDays == null || days < nearestDays) {
      nearestDays = days;
    }
  }

  if (nearestDays != null && nearestDays <= 7) {
    return 'Lowest study time this week and deadline in $nearestDays days';
  }
  if (openTasks > 0) {
    return 'Lowest study time this week and $openTasks open tasks';
  }
  return studiedHours <= 0
      ? 'No study logged this week'
      : 'Lowest study time this week';
}

String _changeLabel(double delta) {
  if (delta > 5) return 'Increased';
  if (delta < -5) return 'Decreased';
  return 'Stable';
}

String _performanceLabel(double change) {
  if (change > 0.05) return 'Improving';
  if (change < -0.05) return 'Declining';
  return 'Stable';
}
