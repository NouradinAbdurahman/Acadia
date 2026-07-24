# OAuth Re-Enable Guide

## Current Status

* Email Authentication ✅ Enabled
* Apple Sign-In ❌ Temporarily Disabled
* Google Sign-In ❌ Temporarily Disabled

**Reason:** OAuth providers were intentionally hidden for this release to simplify
deployment after rebuilding the Supabase backend (the new project has no OAuth
provider configured yet).

**No implementation has been removed.** Every OAuth code path still exists; it is
gated behind two `const bool` flags in `lib/core/config/feature_flags.dart`:

```dart
static const bool enableAppleSignIn = false;
static const bool enableGoogleSignIn = false;
```

---

## Files Related to OAuth

| File | Role |
|---|---|
| `lib/core/config/feature_flags.dart` | `FeatureFlags.enableAppleSignIn` / `enableGoogleSignIn` / `enableAnyOAuth` — the single switchboard controlling everything below. |
| `lib/repositories/auth_repository.dart` | `signInWithOAuth(OAuthProvider provider)` — calls `Supabase.auth.signInWithOAuth`. Guarded at the top: throws `StateError` if the requested provider's flag is `false`. Also builds redirect URLs via `oauthRedirectForCurrentPlatform()`. |
| `lib/core/config/oauth_env.dart` | Reads `OAUTH_REDIRECT_URL` / `WEB_OAUTH_REDIRECT_URL` from `.env` and resolves the correct redirect URL per platform. Not flag-gated — pure config, always available. |
| `lib/core/config/env_validation.dart` | Requires `OAUTH_REDIRECT_URL` and `PASSWORD_RESET_REDIRECT_URL` to be present in `.env` at startup, regardless of the feature flags. |
| `lib/screens/auth/login_screen.dart` | `_signInWithOAuth()` handler + the "Or continue with" divider and Google/Apple `OutlinedButton`s. UI only renders when `FeatureFlags.enableAnyOAuth` is `true`; each button additionally checks its own flag. |
| `lib/screens/auth/signup_screen.dart` | Identical structure to `login_screen.dart`. |
| `ios/Runner/Runner.entitlements` | `com.apple.developer.applesignin` capability (`Default`). Untouched — required for Apple Sign-In regardless of the Dart-level flag. |
| `ios/Runner/Info.plist` | `CFBundleURLSchemes` includes `com.acadia.app` (used for the OAuth redirect deep link). Untouched. |
| `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json` | Firebase/Google config files. Untouched — also used by Firebase Messaging, not OAuth-exclusive. |

No `handle_new_user`-style Postgres trigger creates the `public.users` row on
OAuth sign-in — `AuthRepository.ensurePublicUserRowIfMissing()` does this
client-side for *all* auth methods (email and OAuth alike) and is unaffected by
these flags.

---

## Re-enable Apple

1. **Apple Developer**
   - Confirm the App ID (`com.acadia.studentapp`) has **Sign In with Apple** enabled in the Apple Developer portal.
   - Confirm a Services ID exists with the redirect URL registered (see Supabase step below).
2. **Supabase**
   - Dashboard → Authentication → Providers → Apple → enable, and fill in Services ID, Team ID, Key ID, and the private key.
   - Confirm the redirect URL Supabase shows (`https://<project>.supabase.co/auth/v1/callback`) is registered in the Apple Services ID configuration.
3. **Redirect URLs**
   - `OAUTH_REDIRECT_URL` in `.env` (e.g. `com.acadia.app://auth-callback/`) must be allowlisted in Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
4. **Bundle ID / Associated Domains**
   - Bundle ID: `com.acadia.studentapp` (`ios/Runner.xcodeproj/project.pbxproj`).
   - `ios/Runner/Runner.entitlements` already declares `com.apple.developer.applesignin` — no change needed unless the capability was removed from the Apple Developer portal.
5. **Feature flag**
   - Set `FeatureFlags.enableAppleSignIn = true` in `lib/core/config/feature_flags.dart`.

## Re-enable Google

1. **Google Cloud Console**
   - Create/confirm an OAuth 2.0 Client ID (Web application type — Supabase's OAuth flow uses the Web client, not the native Android/iOS client IDs).
   - Add `https://<project>.supabase.co/auth/v1/callback` as an authorized redirect URI on that Web client.
2. **Supabase**
   - Dashboard → Authentication → Providers → Google → enable, paste the Web Client ID and Client Secret.
3. **Redirect URLs**
   - Same `OAUTH_REDIRECT_URL` allowlist entry as Apple (`lib/core/config/oauth_env.dart` resolves the same redirect for every provider).
4. **Feature flag**
   - Set `FeatureFlags.enableGoogleSignIn = true` in `lib/core/config/feature_flags.dart`.

---

## Checklist

- [ ] Configure provider in Supabase (Apple and/or Google)
- [ ] Configure provider credentials (Apple Services ID/Key, or Google OAuth Client ID/Secret)
- [ ] Confirm `OAUTH_REDIRECT_URL` is allowlisted in Supabase
- [ ] Enable feature flag(s) in `lib/core/config/feature_flags.dart`
- [ ] Test Sign Up via the re-enabled provider(s)
- [ ] Test Login via the re-enabled provider(s)
- [ ] Test Existing Accounts (users created via email, confirm they aren't duplicated if they later use OAuth with the same email)
- [ ] Test Session Restore (kill and relaunch the app after OAuth login)
- [ ] Test Password Reset still works for email accounts
- [ ] Submit new App Store build
