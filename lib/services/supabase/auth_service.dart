import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  // Expose the current user from auth system
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> sendPasswordResetOTP(String email) async {
    // In Supabase, resetPasswordForEmail sends an OTP if the project is configured for it,
    // or a link. For a purely OTP flow, verifyOTP will handle the code.
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyPasswordResetOTP({
    required String email,
    required String code,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
  }

  Future<UserResponse> updatePasswordAfterOTP({
    required String email,
    String? sessionToken,
    required String newPassword,
  }) async {
    // If we have a session token (e.g. from a separate flow), we could set it here.
    // However, verifyOTP usually handles session management.
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<AuthResponse> verifyOTP(
    String email,
    String token,
    OtpType type,
  ) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  Future<void> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    await _supabase.auth.resend(type: type, email: email);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateWeeklyStudyGoal(String userId, int goal) async {
    try {
      final updated = await _supabase
          .from('users')
          .update({'weekly_study_goal': goal})
          .eq('id', userId)
          .select('weekly_study_goal')
          .maybeSingle();

        // Temporary debug for weekly-goal persistence verification.
        print('SAVE RESPONSE: $updated');

      if (updated == null) {
        throw Exception('Failed to update weekly study goal for user.');
      }

      final saved = updated['weekly_study_goal'] as int?;
      if (saved != goal) {
        throw Exception('Weekly study goal was not saved correctly.');
      }
    } on PostgrestException catch (e) {
      // Backward compatibility: some environments may not have this column yet.
      if (e.code == 'PGRST204' ||
          (e.message).toLowerCase().contains('weekly_study_goal')) {
        return;
      }
      rethrow;
    } catch (e) {
      // Fallback safety for schema cache/driver variants.
      final message = e.toString().toLowerCase();
      if (message.contains('weekly_study_goal') &&
          (message.contains('pgrst204') || message.contains('schema cache'))) {
        return;
      }
      rethrow;
    }
  }
}
