import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../repositories/semester_repository.dart';
import 'app_providers.dart';

final semesterProvider = StateNotifierProvider<SemesterNotifier, AsyncValue<List<Semester>>>((ref) {
  return SemesterNotifier(ref.watch(semesterRepositoryProvider), ref);
});

class SemesterNotifier extends StateNotifier<AsyncValue<List<Semester>>> {
  final SemesterRepository _repository;

  SemesterNotifier(this._repository, Ref _) : super(const AsyncValue.loading()) {
    loadSemesters();
  }

  Future<void> loadSemesters() async {
    state = const AsyncValue.loading();
    try {
      final semesters = await _repository.getSemesters();
      state = AsyncValue.data(semesters);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSemester(Semester semester) async {
    try {
      await _repository.createSemester(semester);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateSemester(Semester semester) async {
    try {
      await _repository.updateSemester(semester);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteSemester(String id) async {
    try {
      await _repository.deleteSemester(id);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> setCurrentSemester(String id) async {
    try {
      await _repository.setCurrentSemester(id);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }
}
