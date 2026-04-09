import 'package:supabase_flutter/supabase_flutter.dart';

class CourseService {
  final SupabaseClient _supabase;

  CourseService(this._supabase);

  Future<List<Map<String, dynamic>>> getCourses({String? semesterId}) async {
    if (semesterId == null) return [];
    
    return await _supabase
        .from('courses')
        .select()
        .eq('semester_id', semesterId)
        .order('course_name', ascending: true);
  }


  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    return await _supabase.from('courses').insert(data).select().single();
  }

  Future<Map<String, dynamic>> updateCourse(String id, Map<String, dynamic> data) async {
    return await _supabase.from('courses').update(data).eq('id', id).select().single();
  }

  Future<void> deleteCourse(String id) async {
    await _supabase.from('courses').delete().eq('id', id);
  }
}
