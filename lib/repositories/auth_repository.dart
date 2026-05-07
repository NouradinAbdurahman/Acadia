import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/oauth_env.dart';
import '../models/app_user.dart';
import '../services/supabase/auth_service.dart';
import '../services/supabase/student_profile_service.dart';

class AuthRepository {
  final AuthService _authService;
  final StudentProfileServiceBase _studentProfileService;
  final SupabaseClient _supabase = Supabase.instance.client;

  DateTime? _lastEmailRateLimit;
  DateTime? _lastAuthRateLimit;
  DateTime? _lastSignupSuccessTime;
  
  int _emailRateLimitCount = 0;
  int _authRateLimitCount = 0;

  AuthRepository(
    this._authService, {
    StudentProfileServiceBase? studentProfileService,
  }) : _studentProfileService = studentProfileService ?? StudentProfileService() {
    _loadLimits();
    // Clean up expired limits on start
    _syncLimits();
  }

  // Expose the current user from auth system
  User? get currentUser => _authService.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  void _loadLimits() {
    try {
      final box = Hive.box('settings');
      
      final emailSaved = box.get('lastEmailRateLimit');
      if (emailSaved != null) _lastEmailRateLimit = DateTime.parse(emailSaved);
      
      final authSaved = box.get('lastAuthRateLimit');
      if (authSaved != null) _lastAuthRateLimit = DateTime.parse(authSaved);
      
      final signupSaved = box.get('lastSignupSuccessTime');
      if (signupSaved != null) _lastSignupSuccessTime = DateTime.parse(signupSaved);
      
      _emailRateLimitCount = box.get('emailRateLimitCount', defaultValue: 0);
      _authRateLimitCount = box.get('authRateLimitCount', defaultValue: 0);
    } catch (e) {
      debugPrint('Error loading rate limits from Hive: $e');
    }
  }

  void _saveLimits() {
    try {
      final box = Hive.box('settings');
      box.put('lastEmailRateLimit', _lastEmailRateLimit?.toIso8601String());
      box.put('lastAuthRateLimit', _lastAuthRateLimit?.toIso8601String());
      box.put('lastSignupSuccessTime', _lastSignupSuccessTime?.toIso8601String());
      box.put('emailRateLimitCount', _emailRateLimitCount);
      box.put('authRateLimitCount', _authRateLimitCount);
    } catch (e) {
      debugPrint('Error saving rate limits to Hive: $e');
    }
  }

  void _syncLimits() {
    final now = DateTime.now();
    if (_lastEmailRateLimit != null && now.isAfter(_lastEmailRateLimit!)) {
       // Counter persists for a while to allow backoff to stick, but we clear it if it's very old
       if (now.difference(_lastEmailRateLimit!) > const Duration(minutes: 30)) {
         _emailRateLimitCount = 0;
       }
    }
    if (_lastAuthRateLimit != null && now.isAfter(_lastAuthRateLimit!)) {
       if (now.difference(_lastAuthRateLimit!) > const Duration(minutes: 30)) {
         _authRateLimitCount = 0;
       }
    }
    _saveLimits();
  }

  /// Marks a rate-limit event. Uses exponential backoff (60s -> 300s).
  void _markRateLimit({required bool isEmail}) {
    final now = DateTime.now();
    if (isEmail) {
      _emailRateLimitCount++;
      final cooldownSecs = (60 * _emailRateLimitCount).clamp(60, 300);
      _lastEmailRateLimit = now.add(Duration(seconds: cooldownSecs));
    } else {
      _authRateLimitCount++;
      final cooldownSecs = (60 * _authRateLimitCount).clamp(60, 300);
      _lastAuthRateLimit = now.add(Duration(seconds: cooldownSecs));
    }
    _saveLimits();
  }

  bool isAuthRateLimited() {
    if (_lastAuthRateLimit == null) return false;
    return DateTime.now().isBefore(_lastAuthRateLimit!);
  }

  bool isEmailRateLimited() {
    if (_lastEmailRateLimit == null) return false;
    return DateTime.now().isBefore(_lastEmailRateLimit!);
  }

  Duration remainingAuthRateLimitTime() {
    if (_lastAuthRateLimit == null) return Duration.zero;
    final diff = _lastAuthRateLimit!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration remainingEmailRateLimitTime() {
    final now = DateTime.now();
    Duration emailLimit = Duration.zero;
    if (_lastEmailRateLimit != null) {
      emailLimit = _lastEmailRateLimit!.difference(now);
    }

    Duration signupCooldown = Duration.zero;
    if (_lastSignupSuccessTime != null) {
      final elapsed = now.difference(_lastSignupSuccessTime!);
      if (elapsed < const Duration(seconds: 180)) {
        signupCooldown = const Duration(seconds: 180) - elapsed;
      }
    }

    final total = emailLimit > signupCooldown ? emailLimit : signupCooldown;
    return total.isNegative ? Duration.zero : total;
  }

  bool isBlockedForEmail() {
    return isEmailRateLimited() || !canSignup();
  }

  bool canSignup() {
    if (_lastSignupSuccessTime == null) return true;
    final diff = DateTime.now().difference(_lastSignupSuccessTime!);
    return diff.inSeconds >= 180;
  }

  // --- Authenticated Methods ---

  /// Opens the provider’s OAuth page in a browser / Custom Tabs. Completion is
  /// observed via [authStateChanges] after the app receives the redirect URL.
  ///
  /// `redirectTo` comes from `.env` ([oauthRedirectForCurrentPlatform]) — must match
  /// Supabase Auth URL allowlist and Google Cloud **Web** OAuth redirect
  /// (`https://<project>.supabase.co/auth/v1/callback` is configured in Google,
  /// not in this string).
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    return _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: oauthRedirectForCurrentPlatform(),
      // iOS: external browser avoids in-app webview / canOpenUrl issues; Android Google same.
      authScreenLaunchMode: LaunchMode.externalApplication,
      queryParams: const {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );
  }

  /// Extracts the best available display name from Supabase Auth metadata.
  /// Handles Google (`full_name`, `name`), Apple (`full_name`, `given_name` +
  /// `family_name`), and email signup (`full_name`).
  String _extractDisplayName(User user) {
    final m = user.userMetadata ?? {};
    debugPrint('[extractName] metadata keys: ${m.keys.toList()}');

    final fullName = m['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();

    final name = m['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();

    final given = (m['given_name'] as String? ?? '').trim();
    final family = (m['family_name'] as String? ?? '').trim();
    final composed = '$given $family'.trim();
    if (composed.isNotEmpty) return composed;

    final emailPrefix = (user.email ?? '').split('@').first;
    if (emailPrefix.isNotEmpty) return emailPrefix;

    return '';
  }

  /// Ensures a `public.users` row AND a `student_profiles` row both exist for
  /// the signed-in user. Called on every `AuthChangeEvent.signedIn` so it is
  /// safe (and cheap) to call multiple times — the SELECT short-circuits when
  /// the row already exists.
  ///
  /// Also backfills empty display names on existing rows from OAuth metadata
  /// (covers users who signed up before this fix).
  Future<void> ensurePublicUserRowIfMissing() async {
    final user = _supabase.auth.currentUser;
    debugPrint('[ensurePublicUser] called — user: ${user?.id ?? 'null'}');
    if (user == null) return;

    final oauthName = _extractDisplayName(user);
    debugPrint('[ensurePublicUser] extracted name: "$oauthName"');

    // ── 1. public.users ─────────────────────────────────────────────────────
    final existing = await _supabase
        .from('users')
        .select('id, name')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      debugPrint('[ensurePublicUser] No users row found — inserting...');
      try {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'name': oauthName.isNotEmpty ? oauthName : user.email,
          'academic_profile_completed': false,
        });
        debugPrint('[ensurePublicUser] users row inserted ✓');
      } catch (e) {
        debugPrint('[ensurePublicUser] ERROR inserting users row: $e');
        rethrow;
      }
    } else {
      final existingName = (existing['name'] as String? ?? '').trim();
      if (existingName.isEmpty && oauthName.isNotEmpty) {
        debugPrint('[ensurePublicUser] Backfilling empty users.name...');
        await _supabase.from('users').update({
          'name': oauthName,
        }).eq('id', user.id);
      }
      debugPrint('[ensurePublicUser] users row ready ✓');
    }

    // ── 2. student_profiles ──────────────────────────────────────────────────
    final existingProfile = await _supabase
        .from('student_profiles')
        .select('user_id, full_name')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      debugPrint('[ensurePublicUser] No student_profiles row — upserting...');
      try {
        await _studentProfileService.upsertInitialProfile(
          userId: user.id,
          fullName: oauthName,
        );
        debugPrint('[ensurePublicUser] student_profiles row upserted ✓');
      } catch (e) {
        debugPrint('[ensurePublicUser] ERROR upserting student_profiles: $e');
      }
    } else {
      final existingFullName = (existingProfile['full_name'] as String? ?? '').trim();
      if (existingFullName.isEmpty && oauthName.isNotEmpty) {
        debugPrint('[ensurePublicUser] Backfilling empty student_profiles.full_name...');
        await _supabase.from('student_profiles').update({
          'full_name': oauthName,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', user.id);
      }
      debugPrint('[ensurePublicUser] student_profiles row ready ✓');
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    if (isAuthRateLimited()) {
      throw AuthApiException('Please wait before trying to login again.', code: 'too_many_requests');
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 45));
      
      // Reset counter on success
      _authRateLimitCount = 0;
      _lastAuthRateLimit = null;
      _saveLimits();
      
      return response;
    } on AuthApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
        _markRateLimit(isEmail: true);
      } else if (e.code == 'too_many_requests' || msg.contains('too many requests')) {
        _markRateLimit(isEmail: false);
      }
      debugPrint("LOGIN REAL ERROR: $e");
      rethrow;
    } catch (e) {
      debugPrint("LOGIN REAL ERROR: $e");
      rethrow;
    }
  }

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    if (isBlockedForEmail()) {
      throw AuthApiException('Too many signup attempts. Please wait a few minutes.', code: 'over_email_send_rate_limit');
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      ).timeout(const Duration(seconds: 15));
      
      _lastSignupSuccessTime = DateTime.now();
      _saveLimits();
      
      return response;
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate limit')) {
        _markRateLimit(isEmail: true);
      }
      rethrow;
    }
  }

  Future<void> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    if (isBlockedForEmail()) {
      throw AuthApiException('Check and wait a few minutes before resending.', code: 'over_email_send_rate_limit');
    }

    try {
      await _supabase.auth.resend(
        type: type,
        email: email,
      ).timeout(const Duration(seconds: 15));
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate limit')) {
        _markRateLimit(isEmail: true);
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetOTP(String email) async {
    if (isEmailRateLimited()) {
      throw AuthApiException('Too many requests. Please wait a few minutes.', code: 'over_email_send_rate_limit');
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: passwordResetRedirectUrlFromEnv(),
      ).timeout(const Duration(seconds: 15));
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate limit')) {
        _markRateLimit(isEmail: true);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOTP({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );
      
      return {
        'success': response.session != null,
        'session_token': response.session?.accessToken,
      };
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate limit')) {
        _markRateLimit(isEmail: true);
      }
      return {
        'success': false,
        'error': e.message,
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<AuthResponse> verifyOTP(String email, String token, String fullName) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      ).timeout(const Duration(seconds: 20));
      
      if (response.user != null) {
        // Keep auth-linked app row for routing/system flags.
        await _supabase.from('users').upsert({
          'id': response.user!.id,
          'academic_profile_completed': false,
        }, onConflict: 'id');

        // Single source of truth for display name via profile service layer.
        await _studentProfileService.upsertInitialProfile(
          userId: response.user!.id,
          fullName: fullName,
        );
      }
      
      return response;
    } on AuthApiException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate limit')) {
        _markRateLimit(isEmail: true);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePasswordAfterOTP({
    required String email,
    required String sessionToken,
    required String newPassword,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return {'success': response.user != null};
    } catch (e) {
      debugPrint('Error updating password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<UserResponse> resetPassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<AppUser?> getUserProfile(String userId) async {
    final response = await _authService.getUserProfile(userId);
    if (response != null) {
      return AppUser.fromJson(response);
    }
    return null;
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
