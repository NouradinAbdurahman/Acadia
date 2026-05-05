import '../../models/exam.dart';
import '../../services/supabase/exam_service.dart';

class ExamRepository {
  final ExamService _examService;

  ExamRepository(this._examService);

  Future<List<ExamModel>> getExams({
    required String userId,
    required String semesterId,
  }) async {
    final data = await _examService.getExams(
      userId: userId,
      semesterId: semesterId,
    );
    return data.map((json) => ExamModel.fromJson(json)).toList();
  }

  Future<ExamModel> createExam(ExamModel exam) async {
    final data = exam.toJson()
      ..remove('id')
      ..remove('created_at');
    final response = await _examService.createExam(data);
    return ExamModel.fromJson(response);
  }

  Future<ExamModel> updateExam(String id, Map<String, dynamic> patch) async {
    final response = await _examService.updateExam(id, patch);
    return ExamModel.fromJson(response);
  }

  Future<void> deleteExam(String examId) async {
    await _examService.deleteExam(examId);
  }
}
