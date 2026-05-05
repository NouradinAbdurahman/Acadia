import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase;

  TaskService(this._supabase);

  Future<List<Map<String, dynamic>>> getTasks({
    required String userId,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    return await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .order('created_at', ascending: false);
  }


  Future<List<Map<String, dynamic>>> getTasksByDeadline({
    required String userId,
    required String deadlineId,
    String? semesterId,
  }) async {
    if (semesterId == null) return [];

    final query = _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('deadline_id', deadlineId)
        .eq('semester_id', semesterId);

    return await query.order('created_at', ascending: false);
  }


  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    return await _supabase.from('tasks').insert(data).select().single();
  }

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    final query = _supabase.from('tasks').update(data).eq('id', id);

    // Safety: Ensure we only update rows belonging to the current user if user_id is in data
    if (data.containsKey('user_id')) {
      query.eq('user_id', data['user_id']);
    }

    return await query.select().single();
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }

  /// Marks every non-completed task linked to [deadlineId] as completed.
  /// Used when the parent academic deadline is completed so progress counts stay aligned.
  Future<void> completeAllTasksForDeadline({
    required String userId,
    required String semesterId,
    required String deadlineId,
  }) async {
    await _supabase
        .from('tasks')
        .update({
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .eq('deadline_id', deadlineId)
        .neq('status', 'completed');
  }
}
