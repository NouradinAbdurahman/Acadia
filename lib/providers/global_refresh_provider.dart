import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'app_providers.dart';
import 'course_provider.dart';
import 'course_results_provider.dart';
import 'dashboard_provider.dart';
import 'deadlines_provider.dart';
import 'derived_invalidation.dart' show invalidateTrendCharts;
import 'risk_provider.dart';
import 'semester_provider.dart';
import 'student_profile_provider.dart';
import 'study_sessions_provider.dart';
import 'tasks_provider.dart';

final globalRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(semesterProvider.notifier).loadSemesters();

    final semesters = ref.read(semesterProvider).value ?? const [];
    String? semesterId = ref.read(selectedResultsSemesterProvider);
    if (semesterId == null && semesters.isNotEmpty) {
      String resolvedSemesterId = semesters.first.id;
      for (final semester in semesters) {
        if (semester.isCurrent) {
          resolvedSemesterId = semester.id;
          break;
        }
      }
      semesterId = resolvedSemesterId;
      ref.read(selectedResultsSemesterProvider.notifier).state =
          resolvedSemesterId;
    }

    await Future.wait([
      ref.read(courseProvider.notifier).loadCourses(),
      ref.read(tasksProvider.notifier).refresh(),
      ref.read(deadlinesProvider.notifier).refresh(),
      ref.read(studySessionsProvider.notifier).refresh(),
      ref.read(studentProfileProvider.notifier).loadProfile(),
      if (semesterId != null)
        ref
            .read(courseResultsProvider.notifier)
            .loadForSemester(semesterId, forceRefresh: true),
    ]);

    await ref
        .read(analyticsProvider.notifier)
        .loadAnalytics(user.id, semesterId: semesterId);

    invalidateTrendCharts(ref);
    await ref.read(riskProvider.future);

    ref.invalidate(dashboardProvider);
  };
});
