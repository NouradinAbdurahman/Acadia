import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient supabase;

  AnalyticsService(this.supabase);

  Future<List<Map<String, dynamic>>> getStudySessions({
    required String userId,
    DateTime? startDate,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    var query = supabase
        .from('study_sessions')
        .select('''
          id,
          duration_minutes,
          course_id,
          courses:course_id (
            id,
            course_name,
            color
          )
        ''')
        .eq('user_id', userId)
        .eq('semester_id', semesterId);
    
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    return await query;
  }


  Future<List<Map<String, dynamic>>> getTasks({
    required String userId,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    return await supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('semester_id', semesterId);
  }

  Future<List<Map<String, dynamic>>> getCourses({
    required String? semesterId,
  }) async {
    if (semesterId == null) return [];
    return await supabase.from('courses').select().eq('semester_id', semesterId);
  }

  Future<List<Map<String, dynamic>>> getCourseResults({
    required String userId,
    required String semesterId,
  }) async {
    return await supabase
        .from('course_results')
        .select('course_id, letter_grade, updated_at, created_at')
        .eq('user_id', userId)
        .eq('semester_id', semesterId);
  }

  Future<List<Map<String, dynamic>>> getAllCoursesByUser({
    required String userId,
  }) async {
    return await supabase
        .from('courses')
        .select('id, credits, ects')
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getAllCourseResultsByUser({
    required String userId,
  }) async {
    return await supabase
        .from('course_results')
        .select('course_id, letter_grade, updated_at, created_at')
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>?> getSemester(String semesterId) async {
    return await supabase
        .from('semesters')
        .select()
        .eq('id', semesterId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getMoodLogs({
    required String userId,
    required DateTime startDate,
  }) async {
    return await supabase
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .gte('created_at', startDate.toIso8601String());
  }

}
