import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_profile.dart';
import '../services/supabase/student_profile_service.dart';
import 'app_providers.dart';

final studentProfileServiceProvider = Provider((ref) => StudentProfileService());

final studentProfileProvider = StateNotifierProvider<StudentProfileNotifier, AsyncValue<StudentProfile?>>((ref) {
  // Watch currentUserProvider so the provider is recreated when the user changes
  ref.watch(currentUserProvider);
  return StudentProfileNotifier(ref.watch(studentProfileServiceProvider), ref);
});

class StudentProfileNotifier extends StateNotifier<AsyncValue<StudentProfile?>> {
  final StudentProfileService _service;
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
    final success = await _service.createOrUpdateProfile(profile);
    if (success) {
      state = AsyncValue.data(profile);
      _ref.invalidate(currentAppUserProvider);
    }
  }

  Future<void> completeOnboarding() async {
    final success = await _service.markOnboardingComplete();
    if (success && state.hasValue) {
      state = AsyncValue.data(state.value?.copyWith(onboardingComplete: true));
      _ref.invalidate(currentAppUserProvider);
    }
  }
}
