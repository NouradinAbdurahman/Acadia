import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/prediction/prediction_engine.dart';
import '../domain/prediction/prediction_result.dart';
import 'analytics_provider.dart';
import 'deadlines_provider.dart';
import 'decision_provider.dart';
import 'tasks_provider.dart';

final _lastPredictionResult = StateProvider<PredictionResult?>((ref) => null);

final predictionProvider = Provider<PredictionResult>((ref) {
  final analyticsAsync = ref.watch(analyticsProvider);
  final analytics = analyticsAsync.value;
  final decision = ref.watch(decisionProvider);
  final studyAnalytics = ref.watch(studyAnalyticsProvider);
  final tasks = ref.watch(tasksProvider).value ?? const [];
  final deadlines = ref.watch(deadlinesProvider).value ?? const [];

  // If analytics is still loading (e.g. during pull-to-refresh), hold the
  // previous result so prediction cards don't disappear.
  if (analytics == null) {
    return ref.read(_lastPredictionResult) ?? const PredictionResult.empty();
  }

  final result = PredictionEngine().evaluate(
    analytics: analytics,
    decision: decision,
    studyAnalytics: studyAnalytics,
    tasks: tasks,
    deadlines: deadlines,
  );

  // Cache for use during next reload.
  Future.microtask(() => ref.read(_lastPredictionResult.notifier).state = result);
  return result;
});
