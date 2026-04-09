import '../models/semester.dart';
import '../services/supabase/semester_service.dart';

class SemesterRepository {
  final SemesterService _service;

  SemesterRepository(this._service);

  Future<List<Semester>> getSemesters() async {
    final data = await _service.getSemesters();
    return data.map((json) => Semester.fromJson(json)).toList();
  }

  Future<Semester> createSemester(Semester semester) async {
    final data = await _service.createSemester(semester.toJson());
    return Semester.fromJson(data);
  }

  Future<Semester> updateSemester(Semester semester) async {
    final data = await _service.updateSemester(semester.id, semester.toJson());
    return Semester.fromJson(data);
  }

  Future<void> deleteSemester(String id) async {
    await _service.deleteSemester(id);
  }
}
