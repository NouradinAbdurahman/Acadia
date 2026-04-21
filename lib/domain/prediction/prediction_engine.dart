import '../../models/analytics_data.dart';
import '../../models/deadline.dart';
import '../../models/task.dart';
import '../../providers/analytics_provider.dart';
import '../decision/decision_result.dart';
import 'prediction_result.dart';

class PredictionEngine {
  PredictionResult evaluate({
    required AnalyticsData analytics,
    required DecisionResult decision,
    required StudyAnalytics studyAnalytics,
    required List<Task> tasks,
    required List<Deadline> deadlines,
  }) {
    final pendingTasks = (analytics.totalTasks - analytics.completedTasks).clamp(0, 9999);
    final normalizedInconsistency = (studyAnalytics.timeInconsistencyScore / 100.0).clamp(0.0, 1.0);
    final consistency = (1.0 - normalizedInconsistency).clamp(0.0, 1.0);

    final predictedStress = analytics.avgStress + (pendingTasks * 0.5) + (normalizedInconsistency * 2.0);
    final stressLevel = _levelFromScore(predictedStress);

    final stressReasons = <String>[];
    if (analytics.avgStress > 7) {
      stressReasons.add('predictionReasonHighStressToday');
    }
    if (consistency < 0.6) {
      stressReasons.add('predictionReasonLowConsistency');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasDeadlinesSoon = deadlines.any((d) {
      if (d.isCompleted) return false;
      final due = DateTime(d.deadlineDate.year, d.deadlineDate.month, d.deadlineDate.day);
      final diff = due.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    });
    final hasPendingTaskPressure = pendingTasks > 2;
    final hasUpcomingWorkload = hasDeadlinesSoon || pendingTasks >= 5;
    if (hasUpcomingWorkload) {
      stressReasons.add('predictionReasonUpcomingWorkload');
    }

    final explanationKeys = <String>[];
    if (analytics.avgStress > 7) {
      explanationKeys.add('predictionExplanationStressHigh');
    }
    if (consistency < 0.6) {
      explanationKeys.add('predictionExplanationLowConsistency');
    }
    if (hasPendingTaskPressure) {
      explanationKeys.add('predictionExplanationTasksPending');
    }
    if (hasDeadlinesSoon) {
      explanationKeys.add('predictionExplanationDeadlinesSoon');
    }

    final lowStudy = analytics.weeklyAverageStudyHours < 1.5 ? 25.0 : 0.0;
    final highStress = (analytics.avgStress / 10.0 * 40.0).clamp(0.0, 40.0);
    final incompleteTasks = analytics.totalTasks == 0
        ? 0.0
        : ((pendingTasks / analytics.totalTasks) * 35.0).clamp(0.0, 35.0);
    final performanceRiskScore = (lowStudy + highStress + incompleteTasks).clamp(0.0, 100.0);
    final performanceRiskLevel = _levelFromScore(performanceRiskScore / 10.0);

    final laggingCourses = _laggingCourses(tasks, deadlines);

    final plan = _buildPlan(
      now: now,
      stress: analytics.avgStress,
      deadlineSoon: hasDeadlinesSoon,
      burnoutScore: studyAnalytics.burnoutScore,
    );

    final confidence = _predictionConfidence(
      decisionConfidence: decision.confidence,
      studyAnalytics: studyAnalytics,
      suggestedMinutes: decision.suggestedSessionMinutes,
      sessionsCount: studyAnalytics.trackedSessionCount,
      pendingTasks: pendingTasks,
    );

    final filteredReasons = confidence >= 0.35 ? stressReasons : stressReasons.take(1).toList();
    final filteredExplanations =
      confidence >= 0.35 ? explanationKeys : explanationKeys.take(2).toList();

    return PredictionResult(
      predictedStress: predictedStress,
      stressLevel: stressLevel,
      stressReasons: filteredReasons,
      explanationKeys: filteredExplanations,
      performanceRiskScore: performanceRiskScore,
      performanceRiskLevel: performanceRiskLevel,
      laggingCourses: laggingCourses,
      recommendedPlan: plan,
      confidence: confidence,
    );
  }

  PredictionLevel _levelFromScore(double score) {
    if (score > 8) return PredictionLevel.high;
    if (score > 5) return PredictionLevel.medium;
    return PredictionLevel.low;
  }

  List<String> _laggingCourses(List<Task> tasks, List<Deadline> deadlines) {
    final scoreByCourse = <String, int>{};

    for (final task in tasks) {
      if (task.isCompleted) continue;
      final key = (task.course?.trim().isNotEmpty ?? false)
          ? task.course!.trim()
          : (task.courseId ?? 'Unknown');
      scoreByCourse[key] = (scoreByCourse[key] ?? 0) + 1;
    }

    for (final deadline in deadlines) {
      if (deadline.isCompleted) continue;
      final key = deadline.course.trim().isNotEmpty ? deadline.course.trim() : (deadline.courseId ?? 'Unknown');
      scoreByCourse[key] = (scoreByCourse[key] ?? 0) + 1;
    }

    final entries = scoreByCourse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(2).map((e) => e.key).where((name) => name != 'Unknown').toList();
  }

  List<StudyPlanItem> _buildPlan({
    required DateTime now,
    required double stress,
    required bool deadlineSoon,
    required double burnoutScore,
  }) {
    DateTime at(int dayOffset, int hour, int minute) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      return DateTime(day.year, day.month, day.day, hour, minute);
    }

    int cap(int minutes) {
      if (burnoutScore > 50) return minutes > 30 ? 30 : minutes;
      return minutes;
    }

    if (stress > 7) {
      return <StudyPlanItem>[
        StudyPlanItem(scheduledAt: at(0, 21, 0), durationMinutes: cap(25), focusKey: 'predictionPlanLightFocus'),
        StudyPlanItem(scheduledAt: at(1, 14, 0), durationMinutes: cap(30), focusKey: 'predictionPlanLightFocus'),
      ];
    }

    if (deadlineSoon) {
      return <StudyPlanItem>[
        StudyPlanItem(scheduledAt: at(0, 14, 0), durationMinutes: cap(45), focusKey: 'predictionPlanFocusExecution'),
        StudyPlanItem(scheduledAt: at(1, 14, 0), durationMinutes: cap(60), focusKey: 'predictionPlanDeepExecution'),
      ];
    }

    return <StudyPlanItem>[
      StudyPlanItem(scheduledAt: at(0, 14, 0), durationMinutes: cap(45), focusKey: 'predictionPlanFocusExecution'),
      StudyPlanItem(scheduledAt: at(1, 21, 0), durationMinutes: cap(30), focusKey: 'predictionPlanLightReview'),
    ];
  }

  double _predictionConfidence({
    required double decisionConfidence,
    required StudyAnalytics studyAnalytics,
    required int? suggestedMinutes,
    required int sessionsCount,
    required int pendingTasks,
  }) {
    var confidence = decisionConfidence.clamp(0.0, 1.0);

    // Behavior memory: repeated study timing for 3+ days boosts confidence.
    if (studyAnalytics.hasReliableBehaviorSignal && sessionsCount >= 6) {
      confidence += 0.15;
    }

    // Behavior memory: ignoring recommended duration reduces confidence.
    final target = suggestedMinutes;
    if (target != null && studyAnalytics.recentSessions.isNotEmpty) {
      final recent = studyAnalytics.recentSessions.take(3).toList();
      var ignores = 0;
      for (final session in recent) {
        if ((session.durationMinutes - target).abs() > 20) {
          ignores++;
        }
      }
      if (ignores >= 2) {
        confidence -= 0.2;
      }
    }

    if (pendingTasks >= 8) {
      confidence -= 0.05;
    }

    return confidence.clamp(0.0, 1.0);
  }
}
