import 'package:acadia/models/student_profile.dart';
import 'package:acadia/providers/app_providers.dart';
import 'package:acadia/providers/student_profile_provider.dart';
import 'package:acadia/services/supabase/student_profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudentProfileService implements StudentProfileServiceBase {
  StudentProfile? storedProfile;

  @override
  Future<StudentProfile?> getProfile() async => storedProfile;

  @override
  Future<bool> createOrUpdateProfile(StudentProfile profile) async {
    storedProfile = profile;
    return true;
  }

  @override
  Future<bool> markOnboardingComplete() async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(onboardingComplete: true);
    }
    return true;
  }
}

class _FakeSemesterState {
  String? activeSemesterId;

  Future<void> selectSemester(String semesterId) async {
    activeSemesterId = semesterId;
  }
}

void main() {
  group('Active semester ownership regression', () {
    test('select semester then update profile keeps active semester unchanged', () async {
      final profileService = _FakeStudentProfileService();
      final semesterState = _FakeSemesterState();

      await semesterState.selectSemester('sem-2026-spring');
      expect(semesterState.activeSemesterId, 'sem-2026-spring');

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          studentProfileServiceProvider.overrideWithValue(profileService),
        ],
      );
      addTearDown(container.dispose);

      final profile = StudentProfile(
        id: 'p1',
        userId: 'u1',
        fullName: 'Nouradin',
        universityName: 'Acadia University',
        degreeType: 'Bachelor',
        major: 'Computer Science',
        academicYear: null,
        currentSemester: 7,
        expectedGraduationYear: 2028,
        studyHoursPerWeek: 18,
        preferredStudyTime: 'Evening',
        breakPattern: '50/10',
        timezone: 'UTC',
        country: 'CA',
        onboardingComplete: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await container.read(studentProfileProvider.notifier).updateProfile(profile);

      expect(semesterState.activeSemesterId, 'sem-2026-spring');
      expect(profileService.storedProfile?.currentSemester, 7);
      expect(profileService.storedProfile?.toJson().containsKey('active_semester_id'), isFalse);
    });
  });
}
