import '../../core/services/risk_engine.dart';
import '../../domain/decision/decision_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../models/analytics_data.dart';
import '../../models/deadline.dart';
import '../../models/task.dart';
import '../../providers/analytics_provider.dart';
import '../decision/decision_result.dart';
import 'prediction_result.dart';

class PredictionEngine {
  PredictionResult evaluate({
    required AppLocalizations l10n,
    required AnalyticsData analytics,
    required DecisionResult decision,
    required StudyAnalytics studyAnalytics,
    required List<Task> tasks,
    required List<Deadline> deadlines,
  }) {
    final pendingTasks = (analytics.totalTasks - analytics.completedTasks).clamp(0, 9999);
    final consistency = studyAnalytics.consistency;

    final dailyStress = analytics.avgDailyStress;
    final sessionStress = analytics.avgSessionStress;
    final stressTrend = analytics.stressTrend;
    final studyDeficit = analytics.studyDeficit;

    final workloadImpact = studyDeficit > 10 ? 1.5 : 0.0;
    final predictedStress = (dailyStress + (stressTrend * 2) + workloadImpact).clamp(1.0, 10.0);
    final blendedStress = (dailyStress + sessionStress) / 2.0;
    final stressLevel = _levelFromScore(predictedStress);

    final stressReasons = <String>[];
    if (dailyStress >= 7 || sessionStress >= 7) {
      final val = (dailyStress >= 7 ? dailyStress : sessionStress).toStringAsFixed(1);
      stressReasons.add(l10n.predictionReasonHighStressToday(val));
    }
    if (blendedStress >= 5 && studyAnalytics.weeklyDeficitHours > 5) {
      stressReasons.add(l10n.predictionPressureLikelyToIncrease(studyAnalytics.weeklyDeficitHours.toStringAsFixed(1)));
    }
    if (consistency < 0.6) {
      stressReasons.add(l10n.predictionReasonLowConsistency((consistency * 100).toStringAsFixed(0)));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDeadlinesCount = deadlines.where((d) {
      if (d.isCompleted) return false;
      final due = DateTime(d.deadlineDate.year, d.deadlineDate.month, d.deadlineDate.day);
      final diff = due.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    }).length;

    final hasDeadlinesSoon = upcomingDeadlinesCount > 0;
    final hasPendingTaskPressure = pendingTasks >= 5;
    
    // Threshold-based workload reason (as requested)
    final hasUpcomingWorkload = upcomingDeadlinesCount >= 2 || pendingTasks >= 5;
    if (hasUpcomingWorkload) {
      if (upcomingDeadlinesCount >= 2) {
        stressReasons.add(l10n.predictionReasonUpcomingWorkload(upcomingDeadlinesCount));
      } else {
        stressReasons.add(l10n.predictionReasonTasksPending(pendingTasks));
      }
    }

    final explanationKeys = <String>[];
    if (dailyStress >= 7 || sessionStress >= 7) {
      final val = (dailyStress >= 7 ? dailyStress : sessionStress).toStringAsFixed(1);
      explanationKeys.add(l10n.predictionReasonStressHigh(val));
    }
    if (consistency < 0.6) {
      // Show consistency delta if possible, or current consistency
      explanationKeys.add(l10n.predictionReasonLowConsistencyDetail((consistency * 100).toStringAsFixed(0)));
    }
    if (hasPendingTaskPressure) {
      explanationKeys.add(l10n.predictionReasonTasksPending(pendingTasks));
    }
    if (hasDeadlinesSoon) {
      explanationKeys.add(l10n.predictionReasonDeadlinesSoon(upcomingDeadlinesCount));
    }

    final riskResult = RiskEngine.calculate(
      overdueTasks: analytics.overdueTasks,
      dueSoonTasks: analytics.dueSoonTasks,
      studyDeficitHours: analytics.studyDeficit,
      stressLevel: blendedStress,
      consistency: consistency,
      hasStressData: analytics.hasStressData,
    );
    
    final performanceRiskScore = riskResult.score;
    final performanceRiskLevel = _levelFromScore(performanceRiskScore / 10.0);

    final laggingCourses = _laggingCourses(tasks, deadlines);

    final plan = _buildPlan(
      l10n: l10n,
      now: now,
      stress: decision.avgStress,
      mood: decision.avgMood,
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
    if (score >= 7.5) return PredictionLevel.high;
    if (score >= 4.5) return PredictionLevel.medium;
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
    required AppLocalizations l10n,
    required DateTime now,
    required double stress,
    required double mood,
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

    final recommended = DecisionRules.getRecommendedSessionLength(stress);

    if (stress >= 7) {
      return <StudyPlanItem>[
        StudyPlanItem(scheduledAt: at(0, 21, 0), durationMinutes: cap(20), focusKey: l10n.predictionPlanLightFocus),
        StudyPlanItem(scheduledAt: at(1, 14, 0), durationMinutes: cap(25), focusKey: l10n.predictionPlanLightFocus),
        StudyPlanItem(scheduledAt: at(2, 21, 0), durationMinutes: cap(20), focusKey: l10n.predictionPlanLightReview),
      ];
    }

    if (mood <= 2.5) {
      return <StudyPlanItem>[
        StudyPlanItem(scheduledAt: at(0, 18, 0), durationMinutes: cap(20), focusKey: l10n.predictionPlanLightReview),
        StudyPlanItem(scheduledAt: at(1, 10, 0), durationMinutes: cap(20), focusKey: l10n.predictionPlanLightFocus),
        StudyPlanItem(scheduledAt: at(2, 14, 0), durationMinutes: cap(20), focusKey: l10n.predictionPlanLightFocus),
      ];
    }

    if (deadlineSoon) {
      return <StudyPlanItem>[
        StudyPlanItem(scheduledAt: at(0, 14, 0), durationMinutes: cap(recommended), focusKey: l10n.predictionPlanFocusExecution),
        StudyPlanItem(scheduledAt: at(1, 14, 0), durationMinutes: cap(60), focusKey: l10n.predictionPlanDeepExecution),
        StudyPlanItem(scheduledAt: at(2, 16, 0), durationMinutes: cap(recommended), focusKey: l10n.predictionPlanFocusExecution),
      ];
    }

    return <StudyPlanItem>[
      StudyPlanItem(scheduledAt: at(0, 14, 0), durationMinutes: cap(recommended), focusKey: l10n.predictionPlanFocusExecution),
      StudyPlanItem(scheduledAt: at(1, 21, 0), durationMinutes: cap(30), focusKey: l10n.predictionPlanLightReview),
      StudyPlanItem(scheduledAt: at(2, 14, 0), durationMinutes: cap(recommended), focusKey: l10n.predictionPlanFocusExecution),
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
