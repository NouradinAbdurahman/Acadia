import 'package:supabase_flutter/supabase_flutter.dart';

class StudyService {
  final SupabaseClient _supabase;

  StudyService(this._supabase);

  Future<List<Map<String, dynamic>>> getSessions({
    required String userId,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    return await _supabase
        .from('study_sessions')
        .select('''
          id,
          user_id,
          course_id,
          semester_id,
          session_type,
          duration_minutes,
          created_at,
          intent,
          completed,
          completed_cycles,
          skipped_breaks,
          is_pomodoro,
          total_focus_minutes,
          total_break_minutes,
          cycles_completed,
          total_cycles,
          mood,
          stress,

          courses:course_id (
            id,
            course_name,
            color,
            semester_id
          )
        ''')
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .order('created_at', ascending: false)
        .limit(50);
  }

  Future<Map<String, dynamic>> createSession(
    Map<String, dynamic> data,
  ) async {
    return _supabase
        .from('study_sessions')
        .insert(data)
        .select('''
          id,
          user_id,
          course_id,
          semester_id,
          session_type,
          duration_minutes,
          created_at,
          intent,
          completed,
          completed_cycles,
          skipped_breaks,
          is_pomodoro,
          total_focus_minutes,
          total_break_minutes,
          cycles_completed,
          total_cycles,
          mood,
          stress,

          courses:course_id (
            id,
            course_name,
            color,
            semester_id
          )
        ''')
        .single();
  }

  Future<Map<String, dynamic>> updateSession(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _supabase
        .from('study_sessions')
        .update(data)
        .eq('id', id)
        .select('''
          id,
          user_id,
          course_id,
          semester_id,
          session_type,
          duration_minutes,
          created_at,
          intent,
          completed,
          completed_cycles,
          skipped_breaks,
          is_pomodoro,
          total_focus_minutes,
          total_break_minutes,
          cycles_completed,
          total_cycles,
          mood,
          stress,
          courses:course_id (
            id,
            course_name,
            color,
            semester_id
          )
        ''')
        .single();
  }
}
