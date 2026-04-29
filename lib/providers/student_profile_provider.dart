import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_profile.dart';
import '../services/supabase/student_profile_service.dart';
import 'app_providers.dart';

final studentProfileServiceProvider = Provider<StudentProfileServiceBase>((ref) => StudentProfileService());

final studentProfileProvider = StateNotifierProvider<StudentProfileNotifier, AsyncValue<StudentProfile?>>((ref) {
  // Watch currentUserProvider so the provider is recreated when the user changes
  ref.watch(currentUserProvider);
  return StudentProfileNotifier(ref.watch(studentProfileServiceProvider), ref);
});

class StudentProfileNotifier extends StateNotifier<AsyncValue<StudentProfile?>> {
  final StudentProfileServiceBase _service;
  final Ref _ref;

  StudentProfileNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    final profile = await _service.getProfile();
    state = AsyncValue.data(profile);
  }

  Future<void> updateProfile(StudentProfile profile) async {
    final payload = profile.toJson();
    if (payload.containsKey('active_semester_id')) {
      throw Exception('Profile must not control active semester');
    }

    final success = await _service.createOrUpdateProfile(profile);
    if (success) {
      state = AsyncValue.data(profile);
      _ref.invalidate(currentAppUserProvider);
    }
  }

  Future<void> completeOnboarding() async {
    final success = await _service.markOnboardingComplete();
    if (success) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value?.copyWith(onboardingComplete: true));
      }
      // Always invalidate app user to ensure router re-evaluates with fresh DB state
      _ref.invalidate(currentAppUserProvider);
    }
  }
}
