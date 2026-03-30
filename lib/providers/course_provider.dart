import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'app_providers.dart';

final courseProvider = StateNotifierProvider<CourseNotifier, AsyncValue<List<Course>>>((ref) {
  return CourseNotifier(ref.watch(courseRepositoryProvider));
});

class CourseNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final CourseRepository _repository;
  CourseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    state = const AsyncValue.loading();
    try {
      final courses = await _repository.getCourses();
      state = AsyncValue.data(courses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCourse(Course course) async {
    try {
      await _repository.createCourse(course);
      await loadCourses();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _repository.updateCourse(course);
      await loadCourses();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _repository.deleteCourse(id);
      await loadCourses();
    } catch (e) {
      // Handle error
    }
  }
}

final activeCoursesProvider = Provider<List<Course>>((ref) {
  final courses = ref.watch(courseProvider).value ?? [];
  return courses.where((c) => c.isActive).toList();
});
