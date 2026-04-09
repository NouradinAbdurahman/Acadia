import 'package:supabase_flutter/supabase_flutter.dart';

class CourseResultService {
  CourseResultService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Map<String, dynamic>>> getResultsBySemester({
    required String userId,
    required String semesterId,
  }) async {
    return await _supabase
        .from('course_results')
        .select('*, course_result_components(*), courses:course_id(course_name,course_code)')
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .order('updated_at', ascending: false);
  }

  Future<Map<String, dynamic>?> getResultById({
    required String userId,
    required String resultId,
  }) async {
    return await _supabase
        .from('course_results')
        .select('*, course_result_components(*), courses:course_id(course_name,course_code)')
        .eq('id', resultId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<String> saveResultWithComponents({
    required String userId,
    required String courseId,
    required String semesterId,
    required double? finalAverage,
    required String letterGrade,
    required String? resultStatus,
    required List<Map<String, dynamic>> components,
    String? resultId,
  }) async {
    final dynamic result = await _supabase.rpc(
      'save_course_result_with_components',
      params: {
        'p_user_id': userId,
        'p_course_id': courseId,
        'p_semester_id': semesterId,
        'p_final_average': finalAverage,
        'p_letter_grade': letterGrade,
        'p_result_status': resultStatus,
        'p_components': components,
        'p_result_id': resultId,
      },
    );
    return result as String;
  }

  Future<void> deleteResult({
    required String userId,
    required String resultId,
  }) async {
    await _supabase
        .from('course_results')
        .delete()
        .eq('id', resultId)
        .eq('user_id', userId);
  }
}
