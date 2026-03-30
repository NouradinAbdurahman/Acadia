import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    return _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    return _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .select()
        .single();
  }

  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> payload,
  ) async {
    return _supabase
        .from('notifications')
        .insert(payload)
        .select()
        .single();
  }
}
