import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/decision/decision_engine.dart';
import '../domain/decision/decision_result.dart';
import 'analytics_provider.dart';
import 'deadlines_provider.dart';
import 'mood_provider.dart';
import 'tasks_provider.dart';
import 'study_sessions_provider.dart';
import 'locale_provider.dart';

final decisionProvider = Provider<DecisionResult>((ref) {
  final analyticsAsync = ref.watch(analyticsProvider);
  final analytics = analyticsAsync.value;
  final studyAnalytics = ref.watch(studyAnalyticsProvider);
  final dailyMoods = ref.watch(dailyMoodLogsProvider).value ?? const [];
  final sessionMoodLogs = ref.watch(sessionMoodLogsProvider).value ?? const [];
  final tasks = ref.watch(tasksProvider).value ?? const [];
  final deadlines = ref.watch(deadlinesProvider).value ?? const [];
  final appLocalizations = ref.watch(appLocalizationsProvider);
  final recentSessions = ref.watch(studySessionsProvider).value ?? const [];

  // If analytics is still loading and has no value yet, return empty.
  // Note: AsyncValue.value preserves the previous data during refreshes,
  // so cards won't disappear during pull-to-refresh.
  if (analytics == null) {
    return const DecisionResult.empty();
  }

  final result = DecisionEngine().evaluate(
    analytics: analytics,
    l10n: appLocalizations,
    dailyMoods: dailyMoods,
    sessionMoodLogs: sessionMoodLogs,
    tasks: tasks,
    deadlines: deadlines,
    recentSessions: recentSessions,
    burnoutScore: studyAnalytics.burnoutScore,
    consistencyScore: (100.0 - studyAnalytics.timeInconsistencyScore)
        .clamp(0.0, 100.0),
    weeklyDeficitHours: studyAnalytics.weeklyDeficitHours,
    baselineStress: studyAnalytics.baselineStress,
    baselineMood: studyAnalytics.baselineMood,
    successRate: studyAnalytics.successRate,
  );

  return result;
});
