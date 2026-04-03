import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient supabase;

  AnalyticsService(this.supabase);

  Future<List<Map<String, dynamic>>> getStudySessions(
    String userId,
    DateTime startOfWeek,
  ) async {
    return await supabase
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .gte('created_at', startOfWeek.toIso8601String());
  }

  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    return await supabase.from('tasks').select().eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getCourseResults({
    required String userId,
    required String semesterId,
  }) async {
    return await supabase
        .from('course_results')
        .select('letter_grade')
        .eq('user_id', userId)
        .eq('semester_id', semesterId);
  }
}
