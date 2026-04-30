import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OAuth callback used by Supabase browser flow on **mobile** (`signInWithOAuth`).
/// Must match Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
/// Example: `com.acadia.app://auth-callback`
String oauthRedirectUrlFromEnv() {
  final v = dotenv.env['OAUTH_REDIRECT_URL']?.trim();
  if (v == null || v.isEmpty) {
    throw StateError(
      'Missing OAUTH_REDIRECT_URL in .env. Use the same value you allowlisted in '
      'Supabase (e.g. com.acadia.app://auth-callback).',
    );
  }
  return v;
}

/// Deep link used by password-reset emails (`resetPasswordForEmail`).
/// Must be allowlisted in Supabase redirect URLs.
/// Example: `com.acadia.app://reset-password`
String passwordResetRedirectUrlFromEnv() {
  final v = dotenv.env['PASSWORD_RESET_REDIRECT_URL']?.trim();
  if (v == null || v.isEmpty) {
    throw StateError(
      'Missing PASSWORD_RESET_REDIRECT_URL in .env (e.g. com.acadia.app://reset-password).',
    );
  }
  return v;
}

/// Redirect passed to `signInWithOAuth`: mobile uses [oauthRedirectUrlFromEnv];
/// web uses `WEB_OAUTH_REDIRECT_URL` if set, otherwise the current origin (add that URL in Supabase).
String oauthRedirectForCurrentPlatform() {
  if (kIsWeb) {
    final custom = dotenv.env['WEB_OAUTH_REDIRECT_URL']?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final u = Uri.base;
    final port = u.hasPort ? ':${u.port}' : '';
    return '${u.scheme}://${u.host}$port/';
  }
  return oauthRedirectUrlFromEnv();
}
