import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String fullName;
  final bool shouldResendCodeOnLoad;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.fullName,
    this.shouldResendCodeOnLoad = false,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.shouldResendCodeOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resendCode(force: true);
      });
    }
  }

  void _startTimer() {
    _countdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp(String code) async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;
    if (code.length != 6) return;

    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('VERIFY OTP CALLED');
      final authRepo = ref.read(authRepositoryProvider);
      
      await authRepo.verifyOTP(widget.email, code, widget.fullName);
      
      Haptics.vibrate(HapticsType.success);
      
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        String message = l10n?.networkError ?? '';
        
        if (e is AuthApiException) {
          if (e.message.toLowerCase().contains('invalid') || e.code == 'invalid_otp') {
            message = l10n?.invalidOtp ?? '';
          } else if (e.code == 'otp_expired' || e.message.toLowerCase().contains('expired')) {
            message = l10n?.otpExpired ?? '';
          }
        }
        
        setState(() => _errorMessage = message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode({bool force = false}) async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;
    if (!force && _countdown > 0) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('RESEND CODE CALLED');
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resendOTP(widget.email);
      
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.codeResent ?? ''),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n?.networkError ?? '';

        if (e is AuthApiException) {
          if (e.code == 'over_email_send_rate_limit') {
            errorMessage = l10n?.tooManyRequests ?? '';
          }
        }

        setState(() => _errorMessage = errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Provide default text fallback if localized not found
    final String resendButtonText = _countdown > 0 
      ? (l10n?.resendIn(_countdown) ?? '')
      : (l10n?.resendCode ?? '');

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
                    AppIcon(
                      HeroIcons.envelopeOpen,
                      size: 80,
                      color: theme.colorScheme.onSurface,
                    )
                        .animate()
                        .fade(duration: AppDurations.slow)
                        .scale(delay: 200.ms),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n?.enterOtp ??
                          '',
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
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
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
                        fontWeight: FontWeight.bold,
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
                      onCompleted: (v) {
                        _verifyOtp(v);
                      },
                      onChanged: (value) {
                        Haptics.vibrate(HapticsType.selection);
                        if (mounted) setState(() {});
                      },
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      onPressed: _isLoading ||
                              _otpController.text.length != 6
                          ? null
                          : () => _verifyOtp(_otpController.text),
                      isLoading: _isLoading,
                      text: l10n?.verifyCode ?? '',
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      onPressed:
                          _countdown > 0 ? null : () => _resendCode(),
                      variant: AppButtonVariant.text,
                      text: resendButtonText,
                    ).animate().fade(delay: 500.ms),
                  ],
                ),
              ).animate().fade(
                    duration: AppDurations.slow,
                    curve: Curves.easeOut,
                  ).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
