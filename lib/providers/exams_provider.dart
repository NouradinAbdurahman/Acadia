import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exam.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'semester_provider.dart';

enum ExamUrgencyLevel { low, medium, high }

class ExamUrgencySummary {
  final ExamUrgencyLevel level;
  final int count;
  final int windowDays;

  const ExamUrgencySummary({
    required this.level,
    required this.count,
    required this.windowDays,
  });
}

class ExamsNotifier extends StateNotifier<AsyncValue<List<ExamModel>>> {
  ExamsNotifier({
    required Ref ref,
    required this.examRepository,
    required this.supabaseClient,
  }) : _ref = ref,
       super(const AsyncValue.loading());

  final Ref _ref;
  final dynamic examRepository;
  final SupabaseClient supabaseClient;

  void setEmptyState() {
    state = const AsyncValue.data(<ExamModel>[]);
  }

  Future<void> loadExams({required String userId, String? semesterId}) async {
    if (semesterId == null) {
      setEmptyState();
      return;
    }

    try {
      state = const AsyncValue<List<ExamModel>>.loading();
      final list = await examRepository.getExams(
            userId: userId,
            semesterId: semesterId,
          )
          as List<ExamModel>;
      if (!mounted) return;
      debugPrint('[Exams] Loaded ${list.length} exams for semester $semesterId');
      state = AsyncValue.data(list);
    } catch (e, st) {
      debugPrint('[ExamsProvider] loadExams failed: $e');
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = _ref.read(activeSemesterProvider).value;
    if (userId == null) return;
    await loadExams(userId: userId, semesterId: semesterId);
  }

  /// Fetches fresh data from Supabase without showing a loading state.
  /// Used after mutations to ensure the UI reflects server truth immediately.
  Future<void> silentRefresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = _ref.read(activeSemesterProvider).value;
    if (userId == null || semesterId == null) return;
    try {
      final list = await examRepository.getExams(
        userId: userId,
        semesterId: semesterId,
      ) as List<ExamModel>;
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (e) {
      debugPrint('[ExamsProvider] silentRefresh failed: $e');
    }
  }

  Future<void> createExam(ExamModel exam) async {
    final semesterId = _ref.read(activeSemesterProvider).value;
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot create exam.');
    }

    final scopedExam = exam.copyWith(semesterId: semesterId);
    final previous = state;
    try {
      final created = await examRepository.createExam(scopedExam) as ExamModel;
      state = state.whenData((items) {
        final next = [created, ...items];
        next.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
        return next;
      });
      try {
        await NotificationService.scheduleExamReminders(
          examId: created.id,
          title: created.title,
          examType: created.type,
          examDateTime: created.examDateTime,
          isOnline: created.isOnline,
          classroom: created.classroom,
        );
      } catch (e) {
        debugPrint('[ExamsProvider] Reminder scheduling failed (create): $e');
      }
    } catch (e, st) {
      debugPrint('[ExamsProvider] createExam failed: $e');
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateExam(String id, Map<String, dynamic> patch) async {
    final previous = state;
    try {
      final updated = await examRepository.updateExam(id, patch) as ExamModel;
      state = state.whenData((items) {
        final next = items.map((e) => e.id == id ? updated : e).toList();
        next.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
        return next;
      });

      try {
        await NotificationService.cancelExamReminders(id);
        await NotificationService.scheduleExamReminders(
          examId: updated.id,
          title: updated.title,
          examType: updated.type,
          examDateTime: updated.examDateTime,
          isOnline: updated.isOnline,
          classroom: updated.classroom,
        );
      } catch (e) {
        debugPrint('[ExamsProvider] Reminder scheduling failed (update): $e');
      }
    } catch (e, st) {
      debugPrint('[ExamsProvider] updateExam failed: $e');
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteExam(String id) async {
    final previous = state;
    try {
      await examRepository.deleteExam(id);
      state = state.whenData((items) => items.where((e) => e.id != id).toList());
      try {
        await NotificationService.cancelExamReminders(id);
      } catch (e) {
        debugPrint('[ExamsProvider] Reminder cancel failed (delete): $e');
      }
    } catch (e, st) {
      debugPrint('[ExamsProvider] deleteExam failed: $e');
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}

final examsProvider =
    StateNotifierProvider<ExamsNotifier, AsyncValue<List<ExamModel>>>((ref) {
      final repo = ref.watch(examRepositoryProvider);
      final supabase = Supabase.instance.client;
      final notifier = ExamsNotifier(
        ref: ref,
        examRepository: repo,
        supabaseClient: supabase,
      );

      ref.listen<AsyncValue<String?>>(activeSemesterProvider, (_, next) {
        final userId = ref.read(currentUserProvider)?.id;
        next.when(
          data: (id) {
            if (userId != null && id != null) {
              debugPrint(
                "[ExamsProvider] Loading exams for user: $userId, semester: $id",
              );
              notifier.loadExams(userId: userId, semesterId: id);
            } else {
              notifier.setEmptyState();
            }
          },
          loading: notifier.setEmptyState,
          error: (e, st) => notifier.setEmptyState(),
        );
      }, fireImmediately: true);

      return notifier;
    });

final nextUpcomingExamProvider = Provider<ExamModel?>((ref) {
  final examsAsync = ref.watch(examsProvider);
  final now = DateTime.now();
  final upcoming = examsAsync.valueOrNull
          ?.where((e) => !e.examDateTime.isBefore(now))
          .toList() ??
      <ExamModel>[];
  if (upcoming.isEmpty) return null;
  upcoming.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
  return upcoming.first;
});

final upcomingExamsProvider = Provider<List<ExamModel>>((ref) {
  final examsAsync = ref.watch(examsProvider);
  final now = DateTime.now();
  final upcoming = examsAsync.valueOrNull
          ?.where((e) => !e.examDateTime.isBefore(now))
          .toList() ??
      <ExamModel>[];
  upcoming.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
  return upcoming;
});

final examUrgencyProvider = Provider<ExamUrgencySummary>((ref) {
  final exams = ref.watch(examsProvider).valueOrNull ?? const <ExamModel>[];
  final now = DateTime.now();
  const windowDays = 3;
  final windowEnd = now.add(const Duration(days: windowDays));
  final upcoming = exams
      .where((e) => e.examDateTime.isAfter(now) && e.examDateTime.isBefore(windowEnd))
      .toList();

  if (upcoming.isEmpty) {
    return const ExamUrgencySummary(
      level: ExamUrgencyLevel.low,
      count: 0,
      windowDays: windowDays,
    );
  }
  if (upcoming.length >= 3) {
    return ExamUrgencySummary(
      level: ExamUrgencyLevel.high,
      count: upcoming.length,
      windowDays: windowDays,
    );
  }
  return ExamUrgencySummary(
    level: ExamUrgencyLevel.medium,
    count: upcoming.length,
    windowDays: windowDays,
  );
});
