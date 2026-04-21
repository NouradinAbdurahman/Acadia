import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'app_providers.dart';
import 'semester_provider.dart';


final courseProvider = StateNotifierProvider<CourseNotifier, AsyncValue<List<Course>>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  final semesterId = ref.watch(activeSemesterProvider);
  final notifier = CourseNotifier(repo, ref: ref);
  notifier.loadCourses(semesterId: semesterId);
  return notifier;
});


class CourseNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final CourseRepository _repository;
  final Ref? ref;
  CourseNotifier(this._repository, {this.ref}) : super(const AsyncValue.loading());


  // Holds the last non-empty result so we never show a false empty state during refresh.
  List<Course>? _lastKnownCourses;

  Future<void> loadCourses({String? semesterId}) async {
    // Preserve previous data during refresh so UI doesn't blank/flicker.
    state = const AsyncValue<List<Course>>.loading().copyWithPrevious(state);
    try {
      final courses = await _repository.getCourses(semesterId: semesterId);

      // Migration safety: if legacy rows are missing semesterId, backfill to active semester.
      if (semesterId != null) {
        for (final course in courses.where((c) => c.semesterId == null)) {
          debugPrint(
            '[SemesterMigration] Backfilling course ${course.id} with semesterId=$semesterId',
          );
          try {
            await _repository.updateCourse(course.copyWith(semesterId: semesterId));
          } catch (_) {
            // Ignore per-row failures to avoid blocking the screen load.
          }
        }
      }

      final normalized = semesterId == null
          ? courses
          : courses
                .map((course) => course.copyWith(semesterId: course.semesterId ?? semesterId))
                .where((course) => course.semesterId == semesterId)
                .toList();

      if (!mounted) return;

      // 🛡️ Empty-result guard: if the DB momentarily returns [] during a refresh,
      // keep showing the last known data rather than flashing an empty state.
      // An empty result is only trusted when there is no previous data (first load).
      if (normalized.isEmpty && _lastKnownCourses != null && _lastKnownCourses!.isNotEmpty) {
        debugPrint('[CourseNotifier] Refresh returned empty — keeping last known courses (${_lastKnownCourses!.length})');
        state = AsyncValue.data(_lastKnownCourses!);
        return;
      }

      _lastKnownCourses = normalized;
      state = AsyncValue.data(normalized);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCourse(Course course) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider);
      if (semesterId == null) return;
      final courseWithSemester = course.copyWith(semesterId: semesterId);
      await _repository.createCourse(courseWithSemester);
      await loadCourses(semesterId: semesterId);
    } catch (e) {
      // Handle error
    }
  }


  Future<void> updateCourse(Course course) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider);
      if (semesterId == null) return;
      await _repository.updateCourse(course.copyWith(semesterId: semesterId));
      await loadCourses(semesterId: semesterId);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider);
      await _repository.deleteCourse(id);
      await loadCourses(semesterId: semesterId);
    } catch (e) {
      // Handle error
    }
  }

}

final activeCoursesProvider = Provider<List<Course>>((ref) {
  final courses = ref.watch(courseProvider).value ?? [];
  return courses.where((c) => c.isActive).toList();
});
