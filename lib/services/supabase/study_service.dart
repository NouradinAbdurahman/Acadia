import 'package:supabase_flutter/supabase_flutter.dart';

class StudyService {
  final SupabaseClient _supabase;

  StudyService(this._supabase);

  Future<List<Map<String, dynamic>>> getSessions(String userId) async {
    // Join with courses to get name and color
    return _supabase
        .from('study_sessions')
        .select('''
          *,
          courses (
            *
          )
        ''')
        .eq('user_id', userId)
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
