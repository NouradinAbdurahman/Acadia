import 'package:supabase_flutter/supabase_flutter.dart';

class ExamService {
  final SupabaseClient _supabase;

  ExamService(this._supabase);

  Future<List<Map<String, dynamic>>> getExams() async {
    return await _supabase.from('exams').select().order('exam_date', ascending: true);
  }

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) async {
    return await _supabase.from('exams').insert(data).select().single();
  }

  Future<Map<String, dynamic>> updateExam(String id, Map<String, dynamic> data) async {
    return await _supabase.from('exams').update(data).eq('id', id).select().single();
  }

  Future<void> deleteExam(String id) async {
    await _supabase.from('exams').delete().eq('id', id);
  }
}
