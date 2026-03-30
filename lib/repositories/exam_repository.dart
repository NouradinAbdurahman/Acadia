import '../../models/exam.dart';
import '../../services/supabase/exam_service.dart';

class ExamRepository {
  final ExamService _examService;

  ExamRepository(this._examService);

  Future<List<ExamModel>> getExams() async {
    final data = await _examService.getExams();
    return data.map((json) => ExamModel.fromJson(json)).toList();
  }

  Future<ExamModel> createExam(ExamModel exam) async {
    final data = exam.toJson();
    data.remove('id');
    final response = await _examService.createExam(data);
    return ExamModel.fromJson(response);
  }

  Future<ExamModel> updateExam(ExamModel exam) async {
    final response = await _examService.updateExam(exam.id, exam.toJson());
    return ExamModel.fromJson(response);
  }

  Future<void> deleteExam(String examId) async {
    await _examService.deleteExam(examId);
  }
}
