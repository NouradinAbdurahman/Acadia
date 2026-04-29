import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_profile.dart';

abstract class StudentProfileServiceBase {
  Future<StudentProfile?> getProfile();
  Future<bool> createOrUpdateProfile(StudentProfile profile);
  Future<bool> upsertInitialProfile({
    required String userId,
    required String fullName,
  });
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

      return true;
    } catch (e) {
      debugPrint('Error updating student profile: $e');
      return false;
    }
  }

  @override
  Future<bool> upsertInitialProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      await _supabase.from('student_profiles').upsert({
        'user_id': userId,
        'full_name': fullName.trim(),
        'onboarding_complete': false,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      debugPrint('Error upserting initial student profile: $e');
      return false;
    }
  }

  @override
  Future<bool> markOnboardingComplete() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Update users table (Source of Truth for routing)
      await _supabase.from('users').update({
        'academic_profile_completed': true,
      }).eq('id', user.id);

      // 2. Create a default semester for the user
      final semesterResponse = await _supabase.from('semesters').insert({
        'user_id': user.id,
        'name': 'Semester 1',
        'is_active': true,
        'start_date': DateTime.now().toIso8601String(),
      }).select().single();

      final semesterId = semesterResponse['id'];

      // 3. Update profiles table with completion status AND active semester
      await _supabase.from('student_profiles').update({
        'onboarding_complete': true,
        'active_semester_id': semesterId,
      }).eq('user_id', user.id);
          
      return true;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      return false;
    }
  }
}
