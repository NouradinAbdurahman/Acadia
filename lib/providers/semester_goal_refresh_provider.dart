import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'semester_provider.dart';

final semesterGoalRefreshProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<String?>>(activeSemesterProvider, (previous, next) {
    if (previous?.value == next.value) return;

    ref.invalidate(weeklyStudyGoalHoursProvider);
  });
});
