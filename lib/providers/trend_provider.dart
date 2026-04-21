import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trend_data.dart';
import 'semester_provider.dart';
import 'app_providers.dart';
import 'tasks_provider.dart';
import 'deadlines_provider.dart';
import 'study_sessions_provider.dart';

final trendDaysProvider = StateProvider<int>((ref) => 7);

final trendProvider = FutureProvider.family<TrendData, int>((ref, days) async {
  ref.watch(studySessionsProvider);
  ref.watch(tasksProvider);
  ref.watch(deadlinesProvider);

  final user = ref.watch(currentUserProvider);
  final activeSemesterId = ref.watch(activeSemesterProvider);
  
  if (user == null) {
    return const TrendData.empty();
  }

  final repo = ref.watch(trendRepositoryProvider);
  return repo.getTrendData(
    userId: user.id, 
    days: days,
    semesterId: activeSemesterId,
  );
});
