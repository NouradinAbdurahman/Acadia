import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/prediction/prediction_engine.dart';
import '../domain/prediction/prediction_result.dart';
import 'analytics_provider.dart';
import 'deadlines_provider.dart';
import 'decision_provider.dart';
import 'locale_provider.dart';
import 'tasks_provider.dart';

final predictionProvider = Provider<PredictionResult>((ref) {
  final analyticsAsync = ref.watch(analyticsProvider);
  final analytics = analyticsAsync.value;
  final decision = ref.watch(decisionProvider);
  final studyAnalytics = ref.watch(studyAnalyticsProvider);
  final tasks = ref.watch(tasksProvider).value ?? const [];
  final deadlines = ref.watch(deadlinesProvider).value ?? const [];

  final appLocalizations = ref.watch(appLocalizationsProvider);

  // If analytics is still loading and has no value yet, return empty.
  // Note: AsyncValue.value preserves the previous data during refreshes.
  if (analytics == null) {
    return const PredictionResult.empty();
  }

  final result = PredictionEngine().evaluate(
    l10n: appLocalizations,
    analytics: analytics,
    decision: decision,
    studyAnalytics: studyAnalytics,
    tasks: tasks,
    deadlines: deadlines,
  );

  return result;
});
