import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Call after [dotenv.load]. Ensures required keys exist (values are non-empty).
/// Does not log or print secrets.
void validateRequiredEnv() {
  final missing = <String>[];
  void req(String key) {
    if ((dotenv.env[key] ?? '').trim().isEmpty) missing.add(key);
  }

  req('SUPABASE_URL');
  req('SUPABASE_ANON_KEY');
  req('OAUTH_REDIRECT_URL');
  req('PASSWORD_RESET_REDIRECT_URL');

  if (missing.isNotEmpty) {
    throw StateError(
      'Missing or empty in .env: ${missing.join(', ')}. '
      'Copy .env.example to .env and fill values.',
    );
  }
}
