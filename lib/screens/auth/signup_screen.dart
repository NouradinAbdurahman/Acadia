import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/app_glass_card.dart';
import 'password_validation.dart';
import '../../providers/app_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Periodically update UI to show countdown if rate limited
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo.isBlockedForEmail() || !authRepo.canSignup()) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    final authRepo = ref.read(authRepositoryProvider);
    if (_isLoading) return;

    // 1. Check Global Rate Limit
    if (authRepo.isBlockedForEmail()) {
      final remaining = authRepo.remainingEmailRateLimitTime();
      if (remaining != Duration.zero) {
        final timeStr = '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, "0")}';
        setState(() => _errorMessage = l10n?.emailRateLimitWithTimer(timeStr) ?? 'Try again in $timeStr');
      } else {
        setState(() => _errorMessage = l10n?.emailRateLimit ?? 'Too many attempts. Please wait a few minutes.');
      }
      return;
    }

    // 2. Check Signup Success Cooldown
    if (!authRepo.canSignup()) {
      setState(() => _errorMessage = l10n?.pleaseWait ?? 'Please wait a moment before trying again.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('SIGNUP START');
      final response = await authRepo.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      
      Haptics.vibrate(HapticsType.success);
      
      if (mounted) {
        // Handle existing email even if enumeration protection is on
        final user = response.user;
        if (user != null && user.identities != null && user.identities!.isEmpty) {
          setState(() {
            _errorMessage = l10n?.emailAlreadyInUse ?? 'Email already in use';
          });
          debugPrint('SIGNUP ERROR: email_already_in_use');
          Haptics.vibrate(HapticsType.error);
          return;
        }

        debugPrint('SIGNUP SUCCESS');
        context.push('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}&fullName=${Uri.encodeComponent(_nameController.text.trim())}');
      }
    } on TimeoutException {
      Haptics.vibrate(HapticsType.error);
      debugPrint('SIGNUP ERROR: timeout');
      if (mounted) {
        setState(() => _errorMessage = l10n?.requestTimedOut ?? 'Request timed out');
      }
    } on AuthApiException catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        String msg = l10n?.networkError ?? 'Authentication error';
        final lower = e.message.toLowerCase();
        
        if (e.code == 'over_email_send_rate_limit' || lower.contains('rate limit')) {
          debugPrint('SIGNUP ERROR: rate_limit detected');
          msg = l10n?.emailRateLimit ?? 'Too many attempts. Please wait a few minutes.';
        } else if (lower.contains('already registered') || e.code == 'user_already_exists') {
          msg = l10n?.emailAlreadyInUse ?? 'Email already in use';
        } else if (e.code == 'invalid_email' || lower.contains('invalid email')) {
          msg = l10n?.invalidEmail ?? 'Invalid email';
        } else if (e.code == 'weak_password') {
          msg = l10n?.passwordTooShort ?? 'Password is too weak';
        } else if (e.code == 'signup_cooldown') {
          msg = l10n?.pleaseWait ?? 'Please wait a moment before trying again.';
        } else {
          msg = e.message;
        }
        
        setState(() => _errorMessage = msg);
      }
    } on SocketException {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        setState(() => _errorMessage = l10n?.checkInternetConnection ?? 'Check your internet connection');
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        final errText = e.toString();
        if (errText.contains('SocketException') || errText.contains('ClientException')) {
          setState(() => _errorMessage = l10n?.checkInternetConnection ?? 'Check your internet connection');
        } else {
          setState(() => _errorMessage = l10n?.networkError ?? 'Network error');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authRepo = ref.read(authRepositoryProvider);
    final isEmailLimited = authRepo.isBlockedForEmail();
    final remainingTime = authRepo.remainingEmailRateLimitTime();
    
    String buttonText = l10n?.signup ?? '';
    if (isEmailLimited && remainingTime.inSeconds > 0) {
      final minutes = remainingTime.inMinutes;
      final seconds = remainingTime.inSeconds % 60;
      final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
      buttonText = l10n?.emailRateLimitWithTimer(timeStr) ?? 'Wait $timeStr';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n?.signup ?? '',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: AppGlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 100,
                        child: Lottie.asset(
                          'assets/add_new_user.json',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                                 AppIcon(
                            HeroIcons.userPlus,
                            size: 80,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      )
                          .animate()
                          .fade(duration: AppDurations.slow)
                          .scale(delay: 200.ms),
                      const SizedBox(height: AppSpacing.lg),
                      if (_errorMessage != null) 
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ).animate().fade().scale(),
                      AppTextField(
                        controller: _nameController,
                        labelText: l10n?.fullName ?? '', 
                        prefixIcon: HeroIcons.user,
                        validator: (value) => value == null || value.isEmpty 
                          ? (l10n?.requiredField ?? '') 
                          : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _emailController,
                        labelText: l10n?.email ?? '', 
                        prefixIcon: HeroIcons.envelope,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty || !value.contains('@') 
                          ? (l10n?.invalidEmail ?? '') 
                          : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _passwordController,
                        onChanged: (_) => setState(() {}),
                        labelText: l10n?.password ?? '', 
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) =>
                            validatePasswordForSignup(value, l10n),
                      ),
                      // Animated Password Strength Indicator
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          children: [
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      passwordStrengthLabel(
                                        _passwordController.text,
                                        l10n,
                                      ),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: passwordStrengthColor(
                                          theme,
                                          _passwordController.text,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_passwordController.text.length < 8)
                                      Text(
                                        '${_passwordController.text.length}/8',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.textTheme.bodySmall?.color,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate().fade().slideY(begin: -0.5),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _confirmPasswordController,
                        labelText: l10n?.confirmPassword ?? '', 
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) => validateConfirmPasswordForSignup(
                          value,
                          _passwordController.text,
                          l10n,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        onPressed: (_isLoading || isEmailLimited)
                            ? null
                            : _signUp,
                        isLoading: _isLoading,
                        text: buttonText,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        onPressed: () => context.pop(),
                        variant: AppButtonVariant.text,
                        text: '', // Child is used
                        child: RichText(
                          text: TextSpan(
                            text: '${l10n?.alreadyHaveAccount ?? ''} ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            children: [
                              TextSpan(
                                text: l10n?.login ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fade(duration: AppDurations.slow, curve: Curves.easeOut).slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }
}
