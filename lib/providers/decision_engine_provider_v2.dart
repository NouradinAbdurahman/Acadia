import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/deadline.dart';
import '../models/decision_snapshot.dart';
import '../models/task.dart';
import '../models/trend_data.dart';
import 'analytics_provider.dart';
import 'course_provider.dart';
import 'deadlines_provider.dart';
import 'decision_engine_provider.dart';
import 'tasks_provider.dart';
import 'trend_provider.dart';

final decisionEngineV2Provider = Provider<AsyncValue<DecisionSnapshot>>((ref) {
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

  final courses = coursesAsync.value ?? const <Course>[];
  final tasks = tasksAsync.value ?? const <Task>[];
  final deadlines = deadlinesAsync.value ?? const <Deadline>[];
  final analyticsData = analyticsAsync.value;
  final trendData = trendAsync.value ?? const TrendData.empty();

  if (courses.isEmpty || analyticsData == null) {
    return AsyncValue.error('insufficient_data', StackTrace.current);
  }

  final snapshot = buildDecisionSnapshotV2(
    courses: courses,
    tasks: tasks,
    deadlines: deadlines,
    studyHoursByCourse: analyticsData.studyHoursPerCourse,
    trendData: trendData,
    studyAnalytics: studyAnalytics,
    analyticsRiskScore: analyticsData.riskScore,
  );

  return AsyncValue.data(snapshot);
});

final decisionEngineActiveProvider = Provider<AsyncValue<DecisionSnapshot>>((ref) {
  final v2 = ref.watch(decisionEngineV2Provider);
  if (v2.hasValue) return v2;

  final v1 = ref.watch(decisionEngineProvider);
  if (v1.hasValue) return v1;

  if (v2.hasError) return v1;
  return const AsyncValue.loading();
});

class _CoursePriority {
  final Course course;
  final int overdueCount;
  final int openTasks;
  final int openDeadlines;
  final int? nearestDeadlineDays;
  final double studiedHours;
  final double targetHours;
  final double urgency;
  final double deficit;
  final double workload;
  final double weight;
  final double riskSignal;
  final double score;

  const _CoursePriority({
    required this.course,
    required this.overdueCount,
    required this.openTasks,
    required this.openDeadlines,
    required this.nearestDeadlineDays,
    required this.studiedHours,
    required this.targetHours,
    required this.urgency,
    required this.deficit,
    required this.workload,
    required this.weight,
    required this.riskSignal,
    required this.score,
  });
}

DecisionSnapshot buildDecisionSnapshotV2({
  required List<Course> courses,
  required List<Task> tasks,
  required List<Deadline> deadlines,
  required Map<String, double> studyHoursByCourse,
  required TrendData trendData,
  required StudyAnalytics studyAnalytics,
  required double analyticsRiskScore,
  BurnoutLevel? burnoutLevelOverride,
}) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final upcomingLimit = startOfToday.add(const Duration(days: 7));

  final courseById = <String, Course>{for (final course in courses) course.id: course};
  final studiedHours = <String, double>{for (final course in courses) course.id: 0.0};
  for (final entry in studyHoursByCourse.entries) {
    if (courseById.containsKey(entry.key)) {
      studiedHours[entry.key] = entry.value;
    }
  }

  final openTasksByCourse = <String, int>{for (final c in courses) c.id: 0};
  final overdueByCourse = <String, int>{for (final c in courses) c.id: 0};
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
      overdueByCourse[courseId] = (overdueByCourse[courseId] ?? 0) + 1;
    }
  }

  final openDeadlinesByCourse = <String, int>{for (final c in courses) c.id: 0};
  final nearestDeadlineDaysByCourse = <String, int?>{for (final c in courses) c.id: null};
  for (final deadline in deadlines) {
    if (deadline.isCompleted) continue;
    final courseId = deadline.courseId;
    if (courseId == null || !courseById.containsKey(courseId)) continue;

    openDeadlinesByCourse[courseId] = (openDeadlinesByCourse[courseId] ?? 0) + 1;

    final days = deadline.deadlineDate.difference(startOfToday).inDays;
    if (days < 0) {
      overdueByCourse[courseId] = (overdueByCourse[courseId] ?? 0) + 1;
      continue;
    }

    if (!deadline.deadlineDate.isAfter(upcomingLimit)) {
      final current = nearestDeadlineDaysByCourse[courseId];
      if (current == null || days < current) {
        nearestDeadlineDaysByCourse[courseId] = days;
      }
    }
  }

  final maxEcts = courses.fold<int>(1, (maxVal, c) => c.ects > maxVal ? c.ects : maxVal);
  final maxLoad = math.max(
    1,
    courses
        .map((c) => (openTasksByCourse[c.id] ?? 0) + (openDeadlinesByCourse[c.id] ?? 0) + (overdueByCourse[c.id] ?? 0))
        .fold<int>(0, (sum, v) => v > sum ? v : sum),
  );

  final totalEcts = courses.fold<int>(0, (sum, c) => sum + c.ects);
  final weeklyGoalHours = studyAnalytics.weeklyGoalHours;
  final globalRiskNorm = (analyticsRiskScore / 100).clamp(0.0, 1.0);

  final priorities = courses.map((course) {
    final id = course.id;
    final overdueCount = overdueByCourse[id] ?? 0;
    final openTasks = openTasksByCourse[id] ?? 0;
    final openDeadlines = openDeadlinesByCourse[id] ?? 0;
    final nearestDays = nearestDeadlineDaysByCourse[id];
    final studied = studiedHours[id] ?? 0.0;

    final urgency = overdueCount > 0
        ? 1.0
        : nearestDays == null
            ? 0.0
            : ((8 - nearestDays) / 8).clamp(0.0, 1.0);

    final ectsShare = totalEcts > 0 ? (course.ects / totalEcts) : (1.0 / courses.length);
    final targetHours = math.max(0.75, weeklyGoalHours * ectsShare);
    final deficit = ((targetHours - studied) / targetHours).clamp(0.0, 1.0);

    final workloadRaw = openTasks + openDeadlines + overdueCount;
    final workload = (workloadRaw / maxLoad).clamp(0.0, 1.0);

    final weight = (course.ects / maxEcts).clamp(0.0, 1.0);

    final localRiskProxy = (0.5 * urgency + 0.3 * workload + 0.2 * deficit).clamp(0.0, 1.0);
    final riskSignal = (0.4 * globalRiskNorm + 0.6 * localRiskProxy).clamp(0.0, 1.0);

    final score =
        0.34 * urgency +
        0.24 * deficit +
        0.16 * workload +
        0.16 * weight +
        0.10 * riskSignal;

    return _CoursePriority(
      course: course,
      overdueCount: overdueCount,
      openTasks: openTasks,
      openDeadlines: openDeadlines,
      nearestDeadlineDays: nearestDays,
      studiedHours: studied,
      targetHours: targetHours,
      urgency: urgency,
      deficit: deficit,
      workload: workload,
      weight: weight,
      riskSignal: riskSignal,
      score: score,
    );
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final best = priorities.first;
  final secondCourseName = priorities.length > 1 ? priorities[1].course.courseName : null;
  final nextAction = DecisionNextAction(
    courseId: best.course.id,
    courseName: best.course.courseName,
    durationMinutes: _recommendedDurationV2(
      priority: best,
      studyAnalytics: studyAnalytics,
      burnoutLevelOverride: burnoutLevelOverride,
    ),
    reason: _reasonForPriority(
      best,
      higherPriorityThanCourseName: secondCourseName,
    ),
    confidence: _confidenceForPriority(best),
    higherPriorityThanCourseName: secondCourseName,
  );

  DecisionFocusRecommendation? focusRecommendation;
  if (priorities.length > 1 && (priorities[0].score - priorities[1].score) >= 0.1) {
    final second = priorities[1];
    focusRecommendation = DecisionFocusRecommendation(
      courseId: second.course.id,
      courseName: second.course.courseName,
      reason: _reasonForPriority(second),
    );
  }

  final whatChanged = DecisionWhatChanged(
    study: _changeLabel(trendData.studyChangePercent),
    taskLoad: _changeLabel(trendData.workloadChangePercent),
    performance: _performanceLabel(trendData.performanceChange),
  );

  final todayPlanSecondary = priorities.length > 1
      ? DecisionFocusRecommendation(
          courseId: priorities[1].course.id,
          courseName: priorities[1].course.courseName,
          reason: _reasonForPriority(priorities[1]),
        )
      : null;

  return DecisionSnapshot(
    nextAction: nextAction,
    focusRecommendation: focusRecommendation,
    todayPlanSecondaryRecommendation: todayPlanSecondary,
    whatChanged: whatChanged,
  );
}

int _recommendedDurationV2({
  required _CoursePriority priority,
  required StudyAnalytics studyAnalytics,
  BurnoutLevel? burnoutLevelOverride,
}) {
  var base = 60;

  if (priority.overdueCount > 0) {
    base = 90;
  } else if ((priority.nearestDeadlineDays ?? 99) <= 2) {
    base = 90;
  } else if ((priority.nearestDeadlineDays ?? 99) <= 4 || priority.score >= 0.72) {
    base = 75;
  }

  final level = burnoutLevelOverride ?? studyAnalytics.burnoutLevel;
  final cap = switch (level) {
    BurnoutLevel.highRisk => 60,
    BurnoutLevel.burnoutRisk => 60,
    BurnoutLevel.warning => 75,
    BurnoutLevel.stable => base,
  };

  final guarded = math.min(base, cap);
  return math.max(45, guarded);
}

String _reasonForPriority(
  _CoursePriority priority, {
  String? higherPriorityThanCourseName,
}) {
  final reasons = <String>[];

  if (priority.overdueCount > 0) {
    reasons.add('Overdue tasks need immediate attention');
  } else if (priority.nearestDeadlineDays != null) {
    reasons.add('Deadline in ${priority.nearestDeadlineDays} days');
  }

  if (priority.deficit >= 0.18) {
    reasons.add(
      'You studied ${priority.studiedHours.toStringAsFixed(1)}h of your ${priority.targetHours.toStringAsFixed(1)}h target',
    );
  }

  if (priority.weight >= 0.6) {
    reasons.add('Important course (${priority.course.ects} ECTS)');
  }

  if (priority.workload >= 0.45) {
    reasons.add('Heavy open workload in this course');
  }

  if (reasons.isEmpty) {
    reasons.add('Fallback recommendation: keep your consistency this week');
  }

  if (higherPriorityThanCourseName != null && higherPriorityThanCourseName.isNotEmpty) {
    reasons.add('More urgent than $higherPriorityThanCourseName');
  }

  return reasons.take(3).join('\n');
}

DecisionConfidence _confidenceForPriority(_CoursePriority priority) {
  final hasOverdue = priority.overdueCount > 0;
  final deadlineDays = priority.nearestDeadlineDays;
  final deficit = priority.deficit;

  if (hasOverdue) {
    return DecisionConfidence.high;
  }
  if (deadlineDays != null && deadlineDays <= 3) {
    return DecisionConfidence.high;
  }
  if (deficit > 0.60) {
    return DecisionConfidence.high;
  }
  if (deficit > 0.30) {
    return DecisionConfidence.medium;
  }
  return DecisionConfidence.low;
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
