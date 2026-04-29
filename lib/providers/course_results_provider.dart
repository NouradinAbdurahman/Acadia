import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_result.dart';
import 'app_providers.dart';
import 'semester_provider.dart';

final courseResultsProvider =
    StateNotifierProvider<CourseResultsNotifier, AsyncValue<List<CourseResult>>>(
      (ref) {
        final repository = ref.watch(courseResultRepositoryProvider);
        final supabase = ref.watch(supabaseProvider);
        final semesterIdAsync = ref.watch(activeSemesterProvider);

        final notifier = CourseResultsNotifier(
          repository: repository,
          supabaseClient: supabase,
        );

        semesterIdAsync.when(
          data: (id) {
            if (id != null) {
              notifier.loadForSemester(id, forceRefresh: true);
            } else {
              notifier.clear();
            }
          },
          loading: () => {},
          error: (_, __) => notifier.clear(),
        );

        return notifier;
      },
    );

class CourseResultsNotifier extends StateNotifier<AsyncValue<List<CourseResult>>> {
  CourseResultsNotifier({required this.repository, required this.supabaseClient})
      : super(const AsyncValue.loading());

  final dynamic repository;
  final SupabaseClient supabaseClient;
  String? _lastLoadedSemesterId;
  String? _activeRequestSemesterId;

  void clear() {
    _lastLoadedSemesterId = null;
    _activeRequestSemesterId = null;
    if (!mounted) return;
    state = const AsyncValue.data([]);
  }

  Future<void> loadForSemester(
    String semesterId, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      state = const AsyncValue.data([]);
      return;
    }

    if (!forceRefresh && _lastLoadedSemesterId == semesterId && state.hasValue) {
      return;
    }

    _activeRequestSemesterId = semesterId;
    final requestSemesterId = semesterId;

    try {
      final items = await repository.getResultsBySemester(
            userId: userId,
            semesterId: semesterId,
          )
          as List<CourseResult>;
      if (!mounted || _activeRequestSemesterId != requestSemesterId) return;
      _lastLoadedSemesterId = semesterId;
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!mounted || _activeRequestSemesterId != requestSemesterId) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<CourseResult?> getResultById(String resultId) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return await repository.getResultById(userId: userId, resultId: resultId)
          as CourseResult?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveResult({
    required CourseResult result,
    required String semesterId,
  }) async {
    if (!mounted) return;
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await repository.saveResult(userId: userId, result: result);
      if (!mounted) return;
      await loadForSemester(semesterId, forceRefresh: true);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteResult({
    required String resultId,
    required String semesterId,
  }) async {
    if (!mounted) return;
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await repository.deleteResult(userId: userId, resultId: resultId);
      if (!mounted) return;
      await loadForSemester(semesterId, forceRefresh: true);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}
