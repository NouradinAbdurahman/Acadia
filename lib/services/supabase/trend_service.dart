import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrendService {
  final SupabaseClient supabase;
  static const bool _kTrendDebug = true;

  TrendService(this.supabase);

  List<Map<String, dynamic>> _asRows(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getStudySessions({
    required String userId,
    required DateTime since,
    String? semesterId,
  }) async {
    try {
      var query = supabase
          .from('study_sessions')
          .select('created_at,duration_minutes,course_id,courses!inner(semester_id)')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String());
      
      if (semesterId != null) {
        query = query.eq('courses.semester_id', semesterId);
      }
      
      final response = await query.order('created_at', ascending: true);
      return _asRows(response);
    } catch (e) {
      if (_kTrendDebug) debugPrint('TREND ERROR study_sessions: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedTasks({
    required String userId,
    required DateTime since,
    String? semesterId,
  }) async {
    try {
      var query = supabase
          .from('tasks')
          .select('updated_at,status,courses!inner(semester_id)')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .gte('updated_at', since.toIso8601String());

      if (semesterId != null) {
        query = query.eq('courses.semester_id', semesterId);
      }

      final response = await query.order('updated_at', ascending: true);
      return _asRows(response);
    } catch (e) {
      if (_kTrendDebug) debugPrint('TREND ERROR tasks completed: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getCreatedTasks({
    required String userId,
    required DateTime since,
    String? semesterId,
  }) async {
    try {
      var query = supabase
          .from('tasks')
          .select('created_at,courses!inner(semester_id)')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String());

      if (semesterId != null) {
        query = query.eq('courses.semester_id', semesterId);
      }

      final response = await query.order('created_at', ascending: true);
      return _asRows(response);
    } catch (e) {
      if (_kTrendDebug) debugPrint('TREND ERROR tasks created: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getCreatedDeadlines({
    required String userId,
    required DateTime since,
    String? semesterId,
  }) async {
    try {
      var query = supabase
          .from('academic_deadlines')
          .select('created_at,courses!inner(semester_id)')
          .eq('user_id', userId)
          .eq('is_completed', false)
          .gte('created_at', since.toIso8601String());

      if (semesterId != null) {
        query = query.eq('courses.semester_id', semesterId);
      }

      final response = await query.order('created_at', ascending: true);
      return _asRows(response);
    } catch (e) {
      if (_kTrendDebug) debugPrint('TREND WARN academic_deadlines failed: $e');
      try {
        final fallbackResponse = await supabase
            .from('deadlines')
            .select('created_at')
            .eq('user_id', userId)
            .gte('created_at', since.toIso8601String())
            .order('created_at', ascending: true);
        return _asRows(fallbackResponse);
      } catch (fallbackError) {
        if (_kTrendDebug) {
          debugPrint('TREND ERROR deadlines fallback failed: $fallbackError');
        }
        return const <Map<String, dynamic>>[];
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCourseResults({
    required String userId,
    required DateTime since,
  }) async {
    try {
      final response = await supabase
          .from('course_results')
          .select('created_at,letter_grade')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: true);
      return _asRows(response);
    } catch (e) {
      if (_kTrendDebug) debugPrint('TREND ERROR course_results: $e');
      return const <Map<String, dynamic>>[];
    }
  }
}
