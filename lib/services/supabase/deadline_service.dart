import 'package:supabase_flutter/supabase_flutter.dart';

class DeadlineService {
  final SupabaseClient _supabase;

  DeadlineService(this._supabase);

  Future<List<Map<String, dynamic>>> getDeadlines(String userId) async {
    return _supabase
        .from('academic_deadlines')
        .select()
        .eq('user_id', userId)
        .order('deadline_date', ascending: true);
  }

  Future<Map<String, dynamic>> createDeadline(
    Map<String, dynamic> data,
  ) async {
    return _supabase
        .from('academic_deadlines')
        .insert(data)
        .select()
        .single();
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
}

