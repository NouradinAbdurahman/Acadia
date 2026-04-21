import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_text_field.dart';
import '../../components/app_back_button.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/auth/password_validation.dart';
import '../../widgets/auth/auth_background_container.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      Haptics.vibrate(HapticsType.success);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.passwordUpdatedSuccess ?? '')),
      );
      context.pop();
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        String errorMessage;
        if (e is AuthApiException) {
          final lower = e.message.toLowerCase();
          if (e.code == 'weak_password') {
            errorMessage = l10n?.passwordTooShort ?? '';
          } else if (e.code == 'same_password' ||
              lower.contains('new password should be different from the old password')) {
            errorMessage = l10n?.passwordSameAsOld ?? '';
          } else {
            errorMessage = l10n?.networkError ?? '';
          }
        } else {
          errorMessage = l10n?.networkError ?? '';
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(
          l10n?.changePasswordTitle ?? '',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n?.changePassword ?? '',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(alpha: 0.3),
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
                      AppTextField(
                        controller: _currentPasswordController,
                        labelText: l10n?.currentPassword ?? '',
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? (l10n?.requiredField ?? '')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _newPasswordController,
                        onChanged: (_) => setState(() {}),
                        labelText: l10n?.newPassword ?? '',
                        prefixIcon: HeroIcons.lockClosed,
                        obscureText: true,
                        validator: (value) =>
                          validatePasswordForSignup(value, l10n),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          children: [
                            if (_newPasswordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      passwordStrengthLabel(
                                        _newPasswordController.text,
                                        l10n,
                                      ),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: passwordStrengthColor(
                                          theme,
                                          _newPasswordController.text,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_newPasswordController.text.length < 8)
                                      Text(
                                        '${_newPasswordController.text.length}/8',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .textTheme.bodySmall?.color,
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
                          _newPasswordController.text,
                          l10n,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        onPressed: _isLoading ? null : _changePassword,
                        isLoading: _isLoading,
                        text: l10n?.changePassword ?? '',
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fade(duration: AppDurations.slow, curve: Curves.easeOut)
                .slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }
}
