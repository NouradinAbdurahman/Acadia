import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_text_field.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String sessionToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.sessionToken,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      final result = await authRepo.updatePasswordAfterOTP(
        email: widget.email,
        sessionToken: widget.sessionToken,
        newPassword: _passwordController.text.trim(),
      );
      
      if (result['success'] == true) {
        Haptics.vibrate(HapticsType.success);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.resetPassword ?? ''),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/login');
        }
      } else {
        Haptics.vibrate(HapticsType.error);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _errorMessage = l10n?.networkError ?? '';
          });
        }
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      String message;

      if (e is AuthApiException) {
        final lower = e.message.toLowerCase();
        if (e.code == 'same_password' ||
            lower.contains('new password should be different from the old password')) {
          message = l10n?.passwordSameAsOld ?? '';
        } else if (e.code == 'weak_password') {
          message = l10n?.passwordTooShort ?? '';
        } else {
          message = l10n?.networkError ?? '';
        }
      } else {
        message = l10n?.networkError ?? '';
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          l10n?.resetPassword ?? '',
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: AppGlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
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
                      ).animate().fade(duration: AppDurations.slow).scale(delay: AppDurations.micro),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n?.newPassword ?? '',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ).animate().fade(delay: AppDurations.micro).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xxl),
                      if (_errorMessage != null) 
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                        controller: _passwordController,
                        onChanged: (v) => setState(() {}),
                        labelText: l10n?.newPassword ?? '',
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) => value == null || value.length < 8 
                          ? (l10n?.passwordTooShort ?? '') 
                          : null,
                      ).animate().fade(delay: AppDurations.fast).slideY(begin: 0.2),
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
                                      _passwordController.text.length >= 8 
                                        ? (l10n?.passwordStrong ?? '')
                                        : _passwordController.text.length >= 5
                                          ? (l10n?.passwordFair ?? '')
                                          : (l10n?.passwordWeak ?? ''),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _passwordController.text.length >= 8 
                                          ? theme.colorScheme.primary 
                                          : _passwordController.text.length >= 5
                                            ? Colors.orange
                                            : theme.colorScheme.error,
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
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _confirmPasswordController,
                        labelText: l10n?.confirmPassword ?? '',
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) => value != _passwordController.text 
                          ? (l10n?.passwordsDoNotMatch ?? '') 
                          : null,
                      ).animate().fade(delay: AppDurations.normal).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        isLoading: _isLoading,
                        text: l10n?.resetPassword ?? '',
                      ).animate().fade(delay: AppDurations.slow).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ).animate().fade(duration: AppDurations.medium, curve: Curves.easeOut).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
