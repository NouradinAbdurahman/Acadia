import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../services/supabase/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  // Expose the current user from auth system
  User? get currentUser => _authService.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  DateTime? _lastResendTime;

  Future<AuthResponse> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _authService
        .signUp(email, password)
        .timeout(const Duration(seconds: 20));
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> sendPasswordResetOTP(String email) async {
    await _authService.sendPasswordResetOTP(email);
  }

  Future<Map<String, dynamic>> verifyPasswordResetOTP({
    required String email,
    required String code,
  }) async {
    final response = await _authService.verifyPasswordResetOTP(email: email, code: code);
    return {
      'success': response.session != null,
      'session_token': response.session?.accessToken,
    };
  }

  Future<Map<String, dynamic>> updatePasswordAfterOTP({
    required String email,
    required String sessionToken,
    required String newPassword,
  }) async {
    final response = await _authService.updatePasswordAfterOTP(
      email: email,
      sessionToken: sessionToken,
      newPassword: newPassword,
    );
    return {
      'success': response.user != null,
    };
  }

  Future<UserResponse> resetPassword(String newPassword) async {
    return await _authService.updatePassword(newPassword);
  }

  Future<AuthResponse> verifyOTP(String email, String token, String fullName) async {
    final response = await _authService.verifyOTP(email, token, OtpType.signup)
        .timeout(const Duration(seconds: 20));
    
    // As instructed by PRD, after successful verification, create the user profile
    if (response.user != null) {
      // Create user profile directly into 'users' table
      await Supabase.instance.client.from('users').insert({
        'id': response.user!.id,
        'email': response.user!.email,
        'name': fullName,
        'academic_profile_completed': false,
      }).select().maybeSingle();
    }
    
    return response;
  }

  Future<void> resendOTP(String email, {OtpType type = OtpType.signup}) async {
    final now = DateTime.now();
    if (_lastResendTime != null && 
        now.difference(_lastResendTime!) < const Duration(seconds: 30)) {
      throw AuthException(
        'Please wait before requesting another code.',
        code: 'over_email_send_rate_limit',
      );
    }
    
    _lastResendTime = now;
    await _authService.resendOTP(email, type: type)
        .timeout(const Duration(seconds: 20));
  }

  Future<AppUser?> getUserProfile(String userId) async {
    final response = await _authService.getUserProfile(userId);
    if (response != null) {
      return AppUser.fromJson(response);
    }
    return null;
  }

  Future<void> updateWeeklyStudyGoal(String userId, int goal) async {
    await _authService.updateWeeklyStudyGoal(userId, goal);
  }
}
