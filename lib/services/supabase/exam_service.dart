import 'package:supabase_flutter/supabase_flutter.dart';

class ExamService {
  final SupabaseClient _supabase;

  ExamService(this._supabase);

  Future<List<Map<String, dynamic>>> getExams({
    required String userId,
    required String semesterId,
  }) async {
    return await _supabase
        .from('exams')
        .select(
          'id,user_id,semester_id,title,course_id,exam_datetime,classroom,is_online,instructor_name,type,notes,courses:course_id(course_name)',
        )
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .order('exam_datetime', ascending: true);
  }

  static const _examSelect =
      'id,user_id,semester_id,title,course_id,exam_datetime,classroom,is_online,instructor_name,type,notes,created_at,courses:course_id(course_name)';

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) async {
    return await _supabase.from('exams').insert(data).select(_examSelect).single();
  }

  Future<Map<String, dynamic>> updateExam(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _supabase
        .from('exams')
        .update(data)
        .eq('id', id)
        .select(_examSelect)
        .single();
  }

  Future<void> deleteExam(String id) async {
    await _supabase.from('exams').delete().eq('id', id);
  }
}
