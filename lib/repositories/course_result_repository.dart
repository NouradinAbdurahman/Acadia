import '../models/course_result.dart';
import '../services/supabase/course_result_service.dart';

class CourseResultRepository {
  CourseResultRepository(this._service);

  final CourseResultService _service;

  Future<List<CourseResult>> getResultsBySemester({
    required String userId,
    required String semesterId,
  }) async {
    final data = await _service.getResultsBySemester(
      userId: userId,
      semesterId: semesterId,
    );
    return data.map((item) => CourseResult.fromJson(item)).toList();
  }

  Future<CourseResult?> getResultById({
    required String userId,
    required String resultId,
  }) async {
    final data = await _service.getResultById(
      userId: userId,
      resultId: resultId,
    );
    if (data == null) return null;
    return CourseResult.fromJson(data);
  }

  Future<CourseResult> saveResult({
    required String userId,
    required CourseResult result,
  }) async {
    final savedResultId = await _service.saveResultWithComponents(
      userId: userId,
      courseId: result.courseId,
      semesterId: result.semesterId,
      finalAverage: result.finalAverage,
      letterGrade: result.letterGrade,
      resultStatus: result.resultStatus,
      components: result.components
          .map(
            (component) => {
              'title': component.title,
              'score': component.score,
              'percentage': component.percentage,
            },
          )
          .toList(),
      resultId: result.id.isEmpty ? null : result.id,
    );

    final reloaded = await _service.getResultById(
      userId: userId,
      resultId: savedResultId,
    );
    return CourseResult.fromJson(reloaded!);
  }

  Future<void> deleteResult({
    required String userId,
    required String resultId,
  }) async {
    await _service.deleteResult(userId: userId, resultId: resultId);
  }
}
