import 'package:flutter/foundation.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('SIGNUP CALLED');
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      Haptics.vibrate(HapticsType.success);
      
      if (mounted) {
        
        // Handle existing email even if enumeration protection is on
        final user = response.user;
        if (user != null && user.identities != null && user.identities!.isEmpty) {
          setState(() {
            _errorMessage = l10n?.emailAlreadyInUse ?? 'Email already in use';
          });
          Haptics.vibrate(HapticsType.error);
          return;
        }

        context.push('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}&fullName=${Uri.encodeComponent(_nameController.text.trim())}');
      }
    } on AuthApiException catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        String msg = l10n?.networkError ?? '';
        
        if (e.message.toLowerCase().contains('already registered') || e.code == 'user_already_exists') {
          msg = l10n?.emailAlreadyInUse ?? '';
        } else if (e.code == 'over_email_send_rate_limit') {
          msg = l10n?.tooManyRequests ?? '';
        } else if (e.code == 'weak_password') {
          msg = l10n?.passwordTooShort ?? '';
        }
        
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      debugPrint('🚨 SIGNUP ERROR: $e');
      if (mounted) {
        setState(() => _errorMessage = l10n?.networkError ?? 'Network error');
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
                        onChanged: (v) => setState(() {}),
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
                        onPressed: _signUp,
                        isLoading: _isLoading,
                        text: l10n?.signup ?? '',
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
