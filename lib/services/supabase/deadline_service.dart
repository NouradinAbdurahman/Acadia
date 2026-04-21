import 'package:supabase_flutter/supabase_flutter.dart';

class DeadlineService {
  final SupabaseClient _supabase;

  DeadlineService(this._supabase);

  Future<List<Map<String, dynamic>>> getDeadlines({
    required String userId,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    return await _supabase
        .from('academic_deadlines')
        .select()
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .order('deadline_date', ascending: true);
  }

  Future<Map<String, dynamic>> createDeadline(Map<String, dynamic> data) async {
    return _supabase.from('academic_deadlines').insert(data).select().single();
  }

  Future<Map<String, dynamic>> updateDeadline(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _supabase
        .from('academic_deadlines')
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }

  Future<void> deleteDeadline(String id) async {
    await _supabase.from('academic_deadlines').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> markDeadlineCompleted({
    required String id,
    required bool isCompleted,
  }) async {
    return _supabase
        .from('academic_deadlines')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', id)
        .select()
        .single();
  }
}
