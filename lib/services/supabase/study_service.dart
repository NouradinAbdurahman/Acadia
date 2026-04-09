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
          *,
          courses!inner (
            *
          )
        ''')
        .eq('user_id', userId)
        .eq('courses.semester_id', semesterId)
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
          *,
          courses (
            *
          )
        ''')
        .single();
  }
}
