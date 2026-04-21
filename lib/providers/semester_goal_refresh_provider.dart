import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'prediction_provider.dart';
import 'risk_provider.dart';
import 'semester_provider.dart';

final semesterGoalRefreshProvider = Provider<void>((ref) {
  ref.listen<String?>(activeSemesterProvider, (previous, next) {
    if (previous == next) return;

    ref.invalidate(weeklyStudyGoalHoursProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(riskProvider);
    ref.invalidate(predictionProvider);
  });
});
