import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_text_field.dart';
import '../../components/app_button.dart';

class ForgotPasswordOTPScreen extends ConsumerStatefulWidget {
  const ForgotPasswordOTPScreen({super.key});

  @override
  ConsumerState<ForgotPasswordOTPScreen> createState() => _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends ConsumerState<ForgotPasswordOTPScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isSending = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      
      await authRepo.sendPasswordResetOTP(email);
      
      Haptics.vibrate(HapticsType.success);
      
      if (mounted) {
        context.push('/forgot-password-code?email=${Uri.encodeComponent(email)}');
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage = l10n?.networkError ?? '';
        
        if (e is AuthApiException) {
          if (e.code == 'over_email_send_rate_limit') {
            errorMessage = l10n?.tooManyRequests ?? '';
          }
        }

        setState(() {
          _error = errorMessage;
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
          l10n?.forgotPasswordTitle ?? '',
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
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ).animate().fade().scale(),
                      SizedBox(
                        height: 100,
                        child: Lottie.asset(
                          'assets/forget_password.json',
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate()
                          .fade(duration: AppDurations.slow)
                          .scale(delay: 200.ms),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n?.forgotPasswordPrompt ?? '',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        controller: _emailController,
                        labelText: l10n?.email ?? '', 
                        prefixIcon: HeroIcons.envelope,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty || !value.contains('@') 
                          ? (l10n?.invalidEmail ?? '') 
                          : null,
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        onPressed: _sendOTP,
                        isLoading: _isSending,
                        text: l10n?.sendResetLink ?? '',
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        onPressed: () => context.pop(),
                        variant: AppButtonVariant.text,
                        text: l10n?.backToLogin ?? '',
                      ).animate().fade(delay: 400.ms),
                    ],
                  ),
                ),
              ).animate().fade(duration: AppDurations.slow, curve: Curves.easeOut).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
