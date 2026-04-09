import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'risk_provider.dart';
import 'trend_provider.dart';

/// Analytics and trend charts read from repositories, not from [tasksProvider].
/// Call after task/deadline/study mutations and matching realtime events.
void invalidateAnalyticsAndTrend(Ref ref) {
  ref.read(analyticsProvider.notifier).refreshSilently();
  ref.invalidate(riskProvider);
  invalidateTrendCharts(ref);
}

void invalidateTrendCharts(Ref ref) {
  final days = ref.read(trendDaysProvider);
  ref.invalidate(trendProvider(days));
}
