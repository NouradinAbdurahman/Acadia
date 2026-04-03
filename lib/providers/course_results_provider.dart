import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_result.dart';
import 'app_providers.dart';

final selectedResultsSemesterProvider = StateProvider<String?>((ref) => null);

final courseResultsProvider =
    StateNotifierProvider<
      CourseResultsNotifier,
      AsyncValue<List<CourseResult>>
    >((ref) {
      final repository = ref.watch(courseResultRepositoryProvider);
      final supabase = ref.watch(supabaseProvider);
      return CourseResultsNotifier(
        repository: repository,
        supabaseClient: supabase,
      );
    });

class CourseResultsNotifier
    extends StateNotifier<AsyncValue<List<CourseResult>>> {
  CourseResultsNotifier({
    required this.repository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading());

  final dynamic repository;
  final SupabaseClient supabaseClient;
  String? _lastLoadedSemesterId;

  Future<void> loadForSemester(
    String semesterId, {
    bool forceRefresh = false,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    if (!forceRefresh &&
        _lastLoadedSemesterId == semesterId &&
        state.hasValue) {
      return;
    }

    try {
      final items =
          await repository.getResultsBySemester(
                userId: userId,
                semesterId: semesterId,
              )
              as List<CourseResult>;
      _lastLoadedSemesterId = semesterId;
      state = AsyncValue.data(items);
    } catch (e, st) {
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
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await repository.saveResult(userId: userId, result: result);
      await loadForSemester(semesterId, forceRefresh: true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteResult({
    required String resultId,
    required String semesterId,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await repository.deleteResult(userId: userId, resultId: resultId);
      await loadForSemester(semesterId, forceRefresh: true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
