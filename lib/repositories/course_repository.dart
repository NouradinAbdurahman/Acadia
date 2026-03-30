import '../models/course.dart';
import '../services/supabase/course_service.dart';

class CourseRepository {
  final CourseService _service;

  CourseRepository(this._service);

  Future<List<Course>> getCourses() async {
    final data = await _service.getCourses();
    return data.map((json) => Course.fromJson(json)).toList();
  }

  Future<Course> createCourse(Course course) async {
    final data = await _service.createCourse(course.toJson());
    return Course.fromJson(data);
  }

  Future<Course> updateCourse(Course course) async {
    final data = await _service.updateCourse(course.id, course.toJson());
    return Course.fromJson(data);
  }

  Future<void> deleteCourse(String id) async {
    await _service.deleteCourse(id);
  }
}
