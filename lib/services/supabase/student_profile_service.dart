import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_profile.dart';

abstract class StudentProfileServiceBase {
  Future<StudentProfile?> getProfile();
  Future<bool> createOrUpdateProfile(StudentProfile profile);
  Future<bool> markOnboardingComplete();
}

class StudentProfileService implements StudentProfileServiceBase {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<StudentProfile?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('student_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return StudentProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting student profile: $e');
      return null;
    }
  }

  @override
  Future<bool> createOrUpdateProfile(StudentProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final data = profile.toJson();
      assert(!data.containsKey('active_semester_id'));

      if (data.containsKey('active_semester_id')) {
        debugPrint('Blocked illegal active_semester_id write from profile');
        data.remove('active_semester_id');
      }

      data['user_id'] = user.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('student_profiles').upsert(data, onConflict: 'user_id');

      await _supabase.from('users').update({
        'name': profile.fullName,
      }).eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error updating student profile: $e');
      return false;
    }
  }

  @override
  Future<bool> markOnboardingComplete() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Update profiles table
      await _supabase
          .from('student_profiles')
          .update({'onboarding_complete': true})
          .eq('user_id', user.id);

      // 2. Update users table (Source of Truth for routing)
      await _supabase
          .from('users')
          .update({
            'academic_profile_completed': true,
          })
          .eq('id', user.id);
          
      return true;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      return false;
    }
  }
}
