import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SemesterStateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getActiveSemesterId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('student_profiles')
          .select('active_semester_id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['active_semester_id'] as String?;
    } catch (e) {
      debugPrint('Error fetching active semester: $e');
      return null;
    }
  }

  Future<bool> updateActiveSemester(String semesterId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('student_profiles')
          .update({'active_semester_id': semesterId})
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error updating active semester: $e');
      return false;
    }
  }
}
