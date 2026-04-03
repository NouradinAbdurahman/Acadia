import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_providers.dart';
import 'course_provider.dart';
import 'course_results_provider.dart';
import 'deadlines_provider.dart';
import 'derived_invalidation.dart';
import 'risk_provider.dart';
import 'study_sessions_provider.dart';
import 'tasks_provider.dart';

const bool _kRealtimeDebug = false;

final realtimeProvider = Provider.autoDispose<void>((ref) {
  ref.keepAlive();
  final supabase = ref.read(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  Timer? taskDebounce;
  Timer? studyDebounce;
  Timer? courseResultsDebounce;
  Timer? coursesDebounce;
  Timer? deadlinesDebounce;

  Map<String, dynamic>? payloadRecord(PostgresChangePayload payload) {
    if (payload.newRecord.isNotEmpty) return payload.newRecord;
    if (payload.oldRecord.isNotEmpty) return payload.oldRecord;
    return null;
  }

  bool payloadBelongsToUser(PostgresChangePayload payload) {
    final record = payloadRecord(payload);
    if (record == null) return false;
    final newUserId = payload.newRecord['user_id']?.toString();
    final oldUserId = payload.oldRecord['user_id']?.toString();
    final recordUserId = record['user_id']?.toString();
    return newUserId == user.id || oldUserId == user.id || recordUserId == user.id;
  }

  bool shouldRefreshSelectedSemesterResults(PostgresChangePayload payload) {
    final selectedSemesterId = ref.read(selectedResultsSemesterProvider);
    if (selectedSemesterId == null) return false;

    final newSemesterId = payload.newRecord['semester_id']?.toString();
    final oldSemesterId = payload.oldRecord['semester_id']?.toString();
    return newSemesterId == selectedSemesterId || oldSemesterId == selectedSemesterId;
  }

  bool didCourseChangeAffectRisk(PostgresChangePayload payload) {
    final oldRecord = payload.oldRecord;
    final newRecord = payload.newRecord;
    if (oldRecord.isEmpty || newRecord.isEmpty) return true;
    return oldRecord['ects']?.toString() != newRecord['ects']?.toString();
  }

  void debugLog(String message) {
    if (_kRealtimeDebug) print(message);
  }

  void scheduleTaskRefresh() {
    taskDebounce?.cancel();
    taskDebounce = Timer(const Duration(milliseconds: 250), () {
      debugLog('Realtime: tasks changed');
      ref.invalidate(tasksProvider);
      invalidateAnalyticsAndTrend(ref);
    });
  }

  void scheduleStudyRefresh() {
    studyDebounce?.cancel();
    studyDebounce = Timer(const Duration(milliseconds: 250), () {
      debugLog('Realtime: study sessions changed');
      ref.invalidate(studySessionsProvider);
      invalidateAnalyticsAndTrend(ref);
    });
  }

  void scheduleDeadlinesRefresh() {
    deadlinesDebounce?.cancel();
    deadlinesDebounce = Timer(const Duration(milliseconds: 250), () {
      debugLog('Realtime: academic_deadlines changed');
      ref.invalidate(deadlinesProvider);
      invalidateAnalyticsAndTrend(ref);
    });
  }

  void scheduleCourseResultsRefresh(String eventSemesterId) {
    courseResultsDebounce?.cancel();
    courseResultsDebounce = Timer(const Duration(milliseconds: 250), () async {
      final selectedSemesterId = ref.read(selectedResultsSemesterProvider);
      if (selectedSemesterId != null && selectedSemesterId == eventSemesterId) {
        debugLog('Realtime: course results changed (selected semester)');
        await ref
            .read(courseResultsProvider.notifier)
            .loadForSemester(selectedSemesterId, forceRefresh: true);
      }
      ref.invalidate(riskProvider);
      invalidateAnalyticsAndTrend(ref);
    });
  }

  void scheduleCoursesRefresh() {
    coursesDebounce?.cancel();
    coursesDebounce = Timer(const Duration(milliseconds: 250), () {
      debugLog('Realtime: courses changed');
      ref.invalidate(courseProvider);
    });
  }

  final channel = supabase
      .channel('core-live-${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tasks',
        callback: (payload) {
          if (!payloadBelongsToUser(payload)) return;
          scheduleTaskRefresh();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'academic_deadlines',
        callback: (payload) {
          if (!payloadBelongsToUser(payload)) return;
          scheduleDeadlinesRefresh();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'study_sessions',
        callback: (payload) {
          if (!payloadBelongsToUser(payload)) return;
          scheduleStudyRefresh();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'course_results',
        callback: (payload) {
          if (!payloadBelongsToUser(payload)) return;
          if (!shouldRefreshSelectedSemesterResults(payload)) return;
          final eventSemesterId =
              payload.newRecord['semester_id']?.toString() ??
              payload.oldRecord['semester_id']?.toString();
          if (eventSemesterId == null || eventSemesterId.isEmpty) return;
          scheduleCourseResultsRefresh(eventSemesterId);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'courses',
        callback: (payload) {
          if (!payloadBelongsToUser(payload)) return;
          scheduleCoursesRefresh();
          if (didCourseChangeAffectRisk(payload)) {
            ref.invalidate(riskProvider);
          }
        },
      )
      .subscribe();

  ref.onDispose(() async {
    taskDebounce?.cancel();
    studyDebounce?.cancel();
    courseResultsDebounce?.cancel();
    coursesDebounce?.cancel();
    deadlinesDebounce?.cancel();
    await supabase.removeChannel(channel);
  });
});
