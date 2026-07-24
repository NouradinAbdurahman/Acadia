/// Central switchboard for auth methods available to the current release.
///
/// Google/Apple Sign-In are fully implemented (see [AuthRepository.signInWithOAuth],
/// `login_screen.dart`, `signup_screen.dart`) but hidden from the UI for the App
/// Store resubmission after the backend rebuild. Flip these back to `true` once
/// the providers are reconfigured in Supabase — no other code changes required.
class FeatureFlags {
  const FeatureFlags._();

  static const bool enableEmailAuth = true;

  // ======================================================
  // TEMPORARILY DISABLED
  //
  // Apple Sign-In is intentionally disabled for the current
  // App Store release.
  //
  // The implementation is preserved and must NOT be removed.
  //
  // To re-enable:
  // 1. Configure Apple OAuth in Supabase.
  // 2. Set enableAppleSignIn = true.
  // 3. Verify Apple Developer credentials.
  //
  // See docs/authentication/OAUTH_REENABLE_GUIDE.md
  // ======================================================
  static const bool enableAppleSignIn = false;

  // ======================================================
  // TEMPORARILY DISABLED
  //
  // Google Sign-In is intentionally disabled for the current
  // App Store release.
  //
  // The implementation is preserved and must NOT be removed.
  //
  // To re-enable:
  // 1. Configure Google OAuth in Supabase.
  // 2. Set enableGoogleSignIn = true.
  // 3. Verify OAuth credentials.
  //
  // See docs/authentication/OAUTH_REENABLE_GUIDE.md
  // ======================================================
  static const bool enableGoogleSignIn = false;

  static const bool enableAnyOAuth = enableAppleSignIn || enableGoogleSignIn;
}
