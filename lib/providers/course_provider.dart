import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'app_providers.dart';
import 'semester_provider.dart';


final courseProvider = StateNotifierProvider<CourseNotifier, AsyncValue<List<Course>>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  final semesterIdAsync = ref.watch(activeSemesterProvider);
  final notifier = CourseNotifier(repo, ref: ref);
  
  semesterIdAsync.when(
    data: (id) {
      if (id != null) {
        debugPrint("[CourseProvider] Loading courses for semester: $id");
        notifier.loadCourses(semesterId: id);
        return;
      }
      notifier.setEmptyState();
    },
    loading: () => notifier.setEmptyState(),
    error: (e, _) => notifier.setEmptyState(),
  );
  
  return notifier;
});


class CourseNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final CourseRepository _repository;
  final Ref? ref;
  String? _lastLoadedSemesterId;
  CourseNotifier(this._repository, {this.ref}) : super(const AsyncValue.loading());

  void setEmptyState() {
    _lastLoadedSemesterId = null;
    state = const AsyncValue.data(<Course>[]);
  }


  Future<void> loadCourses({String? semesterId, bool force = false}) async {
    if (semesterId != null &&
        _lastLoadedSemesterId == semesterId &&
        state.hasValue &&
        !force) {
      return;
    }
    state = const AsyncValue<List<Course>>.loading();
    try {
      final courses = await _repository.getCourses(semesterId: semesterId);
      
      debugPrint('[CourseProvider] Loading for Semester: $semesterId | Data Count: ${courses.length}');

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
      _lastLoadedSemesterId = semesterId;
      state = AsyncValue.data(normalized);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCourse(Course course) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider).value;
      if (semesterId == null) return;
      final courseWithSemester = course.copyWith(semesterId: semesterId);
      await _repository.createCourse(courseWithSemester);
      await loadCourses(semesterId: semesterId, force: true);
    } catch (e) {
      // Handle error
    }
  }


  Future<void> updateCourse(Course course) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider).value;
      if (semesterId == null) return;
      await _repository.updateCourse(course.copyWith(semesterId: semesterId));
      await loadCourses(semesterId: semesterId, force: true);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      final semesterId = ref?.read(activeSemesterProvider).value;
      await _repository.deleteCourse(id);
      if (semesterId == null) return;
      await loadCourses(semesterId: semesterId, force: true);
    } catch (e) {
      // Handle error
    }
  }

}

final activeCoursesProvider = Provider<List<Course>>((ref) {
  final courses = ref.watch(courseProvider).value ?? [];
  return courses.where((c) => c.isActive).toList();
});
