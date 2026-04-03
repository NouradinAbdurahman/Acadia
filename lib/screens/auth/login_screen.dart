import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_section_title.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final box = await Hive.openBox('settings');
    final email = box.get('remembered_email', defaultValue: '');
    final password = box.get('remembered_password', defaultValue: '');
    
    if (email.isNotEmpty) {
      _emailController.text = email;
      _passwordController.text = password;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return; // Prevent double-tap
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.login(_emailController.text.trim(), _passwordController.text.trim());
      
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        if (mounted) {
          context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}&resend=1');
        }
        return;
      }

      // Handle Remember Me
      final box = await Hive.openBox('settings');
      if (_rememberMe) {
        await box.put('remembered_email', _emailController.text.trim());
        await box.put('remembered_password', _passwordController.text.trim());
      } else {
        await box.delete('remembered_email');
        await box.delete('remembered_password');
      }

      // Successful login, GoRouter redirect will handle via authStateChanges
      Haptics.vibrate(HapticsType.success);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      String message;

      if (e is AuthApiException) {
        final lower = e.message.toLowerCase();

        // If email is not confirmed, force user into OTP verification flow
        if (e.code == 'email_not_confirmed' ||
            lower.contains('email not confirmed')) {
          Haptics.vibrate(HapticsType.warning);
          context.go(
            '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}&resend=1',
          );
          return;
        }

        if (e.code == 'invalid_credentials' ||
            lower.contains('invalid login credentials')) {
          message = l10n?.invalidCredentials ?? '';
        } else if (e.code == 'over_email_send_rate_limit') {
          message = l10n?.tooManyRequests ?? '';
        } else {
          message = l10n?.networkError ?? '';
        }
      } else {
        debugPrint('🚨 LOGIN ERROR: $e');
        final isNetworkError = e.toString().contains('SocketException') ||
            e.toString().contains('ClientException');
        // In debug: show real error. In release: always show generic message.
        message = kDebugMode && !isNetworkError
            ? e.toString()
            : (l10n?.networkError ?? '');
      }

      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/logo.png', height: 120)
                            .animate()
                            .fade(duration: AppDurations.slow)
                            .scale(delay: 200.ms, begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: AppSpacing.md),
                        AppSectionTitle(
                          title: 'Acadia',
                          subtitle: l10n?.welcome ?? '',
                        ).animate().fade().slideY(begin: 0.2, curve: Curves.easeOut),
                        const SizedBox(height: AppSpacing.xxl),
                        AppGlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                  labelText: l10n?.password ?? '',
                                  prefixIcon: HeroIcons.lockClosed,
                                  obscureText: true,
                                  validator: (value) => value == null || value.length < 8 
                                    ? (l10n?.passwordTooShort ?? '') 
                                    : null,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Flexible(
                                       child: InkWell(
                                         onTap: () => setState(() => _rememberMe = !_rememberMe),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             SizedBox(
                                               height: 24,
                                               width: 24,
                                               child: Checkbox(
                                                 value: _rememberMe,
                                                 onChanged: (value) {
                                                   Haptics.vibrate(HapticsType.selection);
                                                   setState(() {
                                                     _rememberMe = value ?? false;
                                                   });
                                                 },
                                                 activeColor: theme.colorScheme.primary,
                                                 side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                                                 shape: RoundedRectangleBorder(
                                                   borderRadius: BorderRadius.circular(4),
                                                 ),
                                               ),
                                             ),
                                             const SizedBox(width: AppSpacing.sm),
                                             Flexible(
                                               child: Text(
                                                 l10n?.rememberMe ?? '',
                                                 style: theme.textTheme.bodyMedium,
                                                 overflow: TextOverflow.ellipsis,
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                     AppButton(
                                       onPressed: () => context.push('/forgot-password'),
                                       variant: AppButtonVariant.text,
                                       text: l10n?.forgotPassword ?? '',
                                     ),
                                   ],
                                 ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton(
                                  onPressed: _login,
                                  isLoading: _isLoading,
                                   text: l10n?.login ?? '',
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(duration: AppDurations.slow, curve: Curves.easeOut).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          onPressed: () {
                            Haptics.vibrate(HapticsType.light);
                            context.push('/signup');
                          },
                          variant: AppButtonVariant.text,
                          text: '',
                          child: RichText(
                            text: TextSpan(
                               text: '${l10n?.dontHaveAccount ?? ''} ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              children: [
                                TextSpan(
                                   text: l10n?.signup ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ).animate().fade(delay: 200.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
