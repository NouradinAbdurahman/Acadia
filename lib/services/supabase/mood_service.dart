import 'package:supabase_flutter/supabase_flutter.dart';

class MoodService {
  final SupabaseClient _supabase;

  MoodService(this._supabase);

  Future<List<Map<String, dynamic>>> getMoods() async {
    return await _supabase.from('mood_logs').select().order('date', ascending: false);
  }

  Future<Map<String, dynamic>> createMood(Map<String, dynamic> data) async {
    return await _supabase.from('mood_logs').insert(data).select().single();
  }
}
