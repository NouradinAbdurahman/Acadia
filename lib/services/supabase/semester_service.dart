import 'package:supabase_flutter/supabase_flutter.dart';

class SemesterService {
  final SupabaseClient _supabase;

  SemesterService(this._supabase);

  Future<List<Map<String, dynamic>>> getSemesters() async {
    return await _supabase
        .from('semesters')
        .select()
        .order('start_date', ascending: false);
  }

  Future<Map<String, dynamic>> createSemester(Map<String, dynamic> data) async {
    return await _supabase.from('semesters').insert(data).select().single();
  }

  Future<Map<String, dynamic>> updateSemester(String id, Map<String, dynamic> data) async {
    return await _supabase.from('semesters').update(data).eq('id', id).select().single();
  }

  Future<void> deleteSemester(String id) async {
    await _supabase.from('semesters').delete().eq('id', id);
  }

  Future<void> setCurrentSemester(String id) async {
    // Transactional update: set all others to false, this one to true
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('semesters')
        .update({'is_current': false})
        .eq('user_id', user.id);
        
    await _supabase
        .from('semesters')
        .update({'is_current': true})
        .eq('id', id);
  }
}
