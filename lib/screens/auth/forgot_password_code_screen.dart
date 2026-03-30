import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_radius.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';

class ForgotPasswordCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const ForgotPasswordCodeScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ForgotPasswordCodeScreen> createState() => _ForgotPasswordCodeScreenState();
}

class _ForgotPasswordCodeScreenState extends ConsumerState<ForgotPasswordCodeScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(String code) async {
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      Haptics.vibrate(HapticsType.medium);
      final authRepo = ref.read(authRepositoryProvider);
      
      final result = await authRepo.verifyPasswordResetOTP(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Haptics.vibrate(HapticsType.success);
        if (mounted) {
          context.pushReplacement(
            '/reset-password?email=${Uri.encodeComponent(widget.email)}&sessionToken=${result['session_token']}',
          );
        }
      } else {
        Haptics.vibrate(HapticsType.error);
        final l10n = AppLocalizations.of(context);
        final errorMsg = result['error']?.toString().toLowerCase() ?? '';
        
        if (mounted) {
          setState(() {
            if (errorMsg.contains('expired')) {
              _error = l10n?.otpExpired ?? '';
            } else if (errorMsg.contains('attempts')) {
              _error = l10n?.tooManyAttempts ?? '';
            } else {
              _error = l10n?.invalidOtp ?? '';
            }
          });
          _otpController.clear();
        }
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _error = l10n?.networkError ?? '');
        _otpController.clear();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
    });

    try {
      Haptics.vibrate(HapticsType.medium);
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetOTP(widget.email);
      
      if (mounted) {
        Haptics.vibrate(HapticsType.success);
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.codeResent ?? ''),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String message = l10n?.networkError ?? '';
        if (e is AuthApiException && e.code == 'over_email_send_rate_limit') {
          message = l10n?.tooManyRequests ?? '';
        }
        setState(() => _error = message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n?.verifyEmail ?? '',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Lottie.asset(
                        'assets/forget_password.json',
                        fit: BoxFit.contain,
                      ),
                    ).animate().fade(duration: AppDurations.slow).scale(delay: 200.ms),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n?.enterOtp ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.xl),
                    if (_error != null) 
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fade().scale(),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      keyboardType: TextInputType.number,
                      enablePinAutofill: true,
                      textStyle: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: AppRadius.borderMd,
                        fieldHeight: 60,
                        fieldWidth: 50,
                        activeFillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                        inactiveFillColor: theme.colorScheme.surface.withValues(alpha: 0.1),
                        selectedFillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                        activeColor: theme.colorScheme.outline,
                        inactiveColor: theme.colorScheme.outline.withValues(alpha: 0.5),
                        selectedColor: theme.colorScheme.primary,
                      ),
                      animationDuration: AppDurations.normal,
                      enableActiveFill: true,
                      controller: _otpController,
                      beforeTextPaste: (text) => true,
                      onCompleted: _verifyCode,
                      onChanged: (value) {
                        Haptics.vibrate(HapticsType.selection);
                        if (mounted) setState(() {});
                      },
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      onPressed: _isVerifying || _otpController.text.length != 6 
                        ? null 
                        : () => _verifyCode(_otpController.text),
                      isLoading: _isVerifying,
                      text: l10n?.verifyCode ?? '',
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      onPressed: _resendCode,
                      variant: AppButtonVariant.text,
                      text: l10n?.resendCode ?? '',
                    ).animate().fade(delay: 500.ms),
                  ],
                ),
              ).animate().fade(duration: AppDurations.slow, curve: Curves.easeOut).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
