import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/decision/decision_engine.dart';
import '../domain/decision/decision_result.dart';
import 'analytics_provider.dart';
import 'deadlines_provider.dart';
import 'mood_provider.dart';
import 'tasks_provider.dart';

final _lastDecisionResult = StateProvider<DecisionResult?>((ref) => null);

final decisionProvider = Provider<DecisionResult>((ref) {
  final analyticsAsync = ref.watch(analyticsProvider);
  final analytics = analyticsAsync.value;
  final studyAnalytics = ref.watch(studyAnalyticsProvider);
  final moods = ref.watch(moodLogsProvider).value ?? const [];
  final tasks = ref.watch(tasksProvider).value ?? const [];
  final deadlines = ref.watch(deadlinesProvider).value ?? const [];

  // If analytics is still loading (e.g. during pull-to-refresh), hold the
  // previous result so cards don't disappear.
  if (analytics == null) {
    return ref.read(_lastDecisionResult) ?? const DecisionResult.empty();
  }

  final result = DecisionEngine().evaluate(
    analytics: analytics,
    moods: moods,
    tasks: tasks,
    deadlines: deadlines,
    burnoutScore: studyAnalytics.burnoutScore,
    consistencyScore: (100.0 - studyAnalytics.timeInconsistencyScore)
        .clamp(0.0, 100.0),
  );

  // Cache for use during next reload.
  Future.microtask(() => ref.read(_lastDecisionResult.notifier).state = result);
  return result;
});
