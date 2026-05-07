import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import '../models/app_user.dart';

/// Resolves the best display name from available sources.
///
/// Priority: profile fullName > AppUser name > auth metadata > email prefix > empty
String resolveDisplayName(
  StudentProfile? profile,
  AppUser? appUser,
  User? authUser,
) {
  final profileName = (profile?.fullName ?? '').trim();
  if (profileName.isNotEmpty) return profileName;

  final appUserName = (appUser?.name ?? '').trim();
  if (appUserName.isNotEmpty) return appUserName;

  if (authUser != null) {
    final m = authUser.userMetadata ?? {};
    final fullName = (m['full_name'] as String? ?? '').trim();
    if (fullName.isNotEmpty) return fullName;

    final name = (m['name'] as String? ?? '').trim();
    if (name.isNotEmpty) return name;

    final given = (m['given_name'] as String? ?? '').trim();
    final family = (m['family_name'] as String? ?? '').trim();
    final composed = '$given $family'.trim();
    if (composed.isNotEmpty) return composed;

    final emailPrefix = (authUser.email ?? '').split('@').first;
    if (emailPrefix.isNotEmpty) return emailPrefix;
  }

  return '';
}
