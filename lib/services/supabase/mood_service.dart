import 'package:supabase_flutter/supabase_flutter.dart';

class MoodService {
  final SupabaseClient _supabase;

  MoodService(this._supabase);

  Future<Map<String, dynamic>> insertMood(Map<String, dynamic> data) async {
    try {
      return await _supabase.from('mood_logs').insert(data).select().single();
    } on PostgrestException catch (e) {
      // Backward compatibility for databases that still use the legacy mood_logs shape.
      if (e.code != '42703') rethrow;

      final legacyPayload = <String, dynamic>{
        'user_id': data['user_id'],
        'stress_level': data['stress_level'],
        'note': data['note'],
        'created_at': data['created_at'],
        'mood': _legacyMoodLabel((data['mood_level'] as num?)?.toInt() ?? 3),
      };

      final response = await _supabase
          .from('mood_logs')
          .insert(legacyPayload)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    }
  }

  Future<List<Map<String, dynamic>>> getMoodLogs({
    required String semesterId,
  }) async {
    try {
      final response = await _supabase
          .from('mood_logs')
          .select()
          .eq('semester_id', semesterId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      // If semester_id doesn't exist yet, fall back to legacy table shape.
      if (e.code != '42703') rethrow;

      final response = await _supabase
          .from('mood_logs')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    }
  }

  Future<Map<String, dynamic>?> getMoodSettings({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('mood_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      // mood_settings may not exist yet on older databases.
      if (e.code == '42P01') return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upsertMoodSettings(
    Map<String, dynamic> data,
  ) async {
    try {
      return await _supabase
          .from('mood_settings')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();
    } on PostgrestException catch (e) {
      if (e.code == '42703' && data.containsKey('tracking_enabled')) {
        final fallback = Map<String, dynamic>.from(data)
          ..remove('tracking_enabled');
        return await _supabase
            .from('mood_settings')
            .upsert(fallback, onConflict: 'user_id')
            .select()
            .single();
      }
      // Ignore silently when table doesn't exist yet; caller still gets a typed object.
      if (e.code == '42P01') {
        return Map<String, dynamic>.from(data);
      }
      rethrow;
    }
  }

  String _legacyMoodLabel(int level) {
    switch (level) {
      case 1:
        return 'very_bad';
      case 2:
        return 'bad';
      case 3:
        return 'neutral';
      case 4:
        return 'good';
      default:
        return 'very_good';
    }
  }
}
