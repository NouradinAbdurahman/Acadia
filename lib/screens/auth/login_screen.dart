import 'dart:async';

import 'package:acadia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/app_button.dart';
import '../../components/app_text_field.dart';

import '../../core/design/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';

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
  OAuthProvider? _oauthBusy;
  bool _rememberMe = false;
  String? _errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
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
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      Haptics.vibrate(HapticsType.medium);
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('LOGIN START');
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.user != null && response.user!.emailConfirmedAt == null) {
        if (mounted) {
          context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
        }
        return;
      }

      final box = await Hive.openBox('settings');
      if (_rememberMe) {
        await box.put('remembered_email', _emailController.text.trim());
        await box.put('remembered_password', _passwordController.text.trim());
      } else {
        await box.delete('remembered_email');
        await box.delete('remembered_password');
      }

      debugPrint('LOGIN SUCCESS');
      Haptics.vibrate(HapticsType.success);
    } on TimeoutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      debugPrint('LOGIN ERROR: timeout');
      setState(() => _errorMessage = l10n?.requestTimedOut ?? '');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      String message;

      if (e is AuthApiException) {
        final lower = e.message.toLowerCase();

        if (e.code == 'email_not_confirmed' ||
            lower.contains('email not confirmed')) {
          debugPrint('LOGIN ERROR: email_not_confirmed');
          Haptics.vibrate(HapticsType.warning);
          context.go(
            '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
          );
          return;
        }

        if (e.code == 'invalid_credentials' ||
            lower.contains('invalid login credentials')) {
          debugPrint('LOGIN ERROR: invalid_credentials');
          message = l10n?.invalidCredentials ?? '';
        } else if (e.code == 'over_email_send_rate_limit') {
          debugPrint('LOGIN ERROR: email_rate_limit');
          message = l10n?.emailRateLimit ?? '';
        } else if (e.code == 'too_many_requests' ||
            lower.contains('too many requests')) {
          debugPrint('LOGIN ERROR: auth_rate_limit');
          message = l10n?.tooManyRequests ?? '';
        } else {
          debugPrint('LOGIN ERROR: auth_unknown');
          message = l10n?.networkError ?? '';
        }
      } else {
        debugPrint('LOGIN ERROR: unexpected');
        final isNetworkError = e.toString().contains('SocketException') ||
            e.toString().contains('ClientException');
        if (isNetworkError) {
          debugPrint('LOGIN ERROR: network');
          message = l10n?.checkInternetConnection ?? '';
        } else {
          message = l10n?.networkError ?? '';
        }
      }

      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    if (_isLoading || _oauthBusy != null) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      Haptics.vibrate(HapticsType.light);
      _oauthBusy = provider;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final launched = await authRepo.signInWithOAuth(provider);
      if (!launched && mounted) {
        setState(() => _errorMessage = l10n?.networkError ?? '');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('OAUTH ERROR: $e');
      setState(() => _errorMessage = l10n?.networkError ?? '');
    } finally {
      if (mounted) setState(() => _oauthBusy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final fieldFillColor = isLight
        ? theme.colorScheme.surface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.06);
    final fieldBorderColor = isLight
        ? theme.colorScheme.outline.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.15);
    final fieldFocusedBorderColor = isLight
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.9);
    final authRepo = ref.read(authRepositoryProvider);

    final isAuthLimited = authRepo.isAuthRateLimited();
    final remaining = authRepo.remainingAuthRateLimitTime();

    String buttonText = l10n?.login ?? '';
    if (isAuthLimited && remaining.inSeconds > 0) {
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
      buttonText = '${l10n?.login ?? ''} ($timeStr)';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 140,
                    child: Hero(
                      tag: 'app_header_logo',
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ).animate().fade().slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n?.appName ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n?.welcomeSubtitle ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.lg),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                  Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        labelText: l10n?.email ?? '',
                        prefixIcon: HeroIcons.envelope,
                        fillColor: fieldFillColor,
                        borderColor: fieldBorderColor,
                        focusedBorderColor: fieldFocusedBorderColor,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || value.isEmpty || !value.contains('@')
                                ? (l10n?.invalidEmail ?? '')
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _passwordController,
                        labelText: l10n?.password ?? '',
                        prefixIcon: HeroIcons.lockClosed,
                        fillColor: fieldFillColor,
                        borderColor: fieldBorderColor,
                        focusedBorderColor: fieldFocusedBorderColor,
                        obscureText: true,
                        validator: (value) => value == null || value.length < 8
                            ? (l10n?.passwordTooShort ?? '')
                            : null,
                      ),
                    ],
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
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
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
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
                  ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    onPressed: (isAuthLimited || _isLoading || _oauthBusy != null)
                        ? null
                        : _login,
                    isLoading: _isLoading,
                    text: buttonText,
                    isFullWidth: true,
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.md),
                  _buildOrContinueWith(context).animate().fade(delay: 350.ms).slideY(begin: 0.1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          context: context,
                          assetPath: 'assets/google.png',
                          label: l10n?.googleLabel ?? '',
                          isGoogleIcon: true,
                          isBusy: _oauthBusy == OAuthProvider.google,
                          onPressed: (_isLoading || _oauthBusy != null)
                              ? null
                              : () => _signInWithOAuth(OAuthProvider.google),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSocialButton(
                          context: context,
                          assetPath: 'assets/icons/apple.png',
                          label: l10n?.appleLabel ?? '',
                          isGoogleIcon: false,
                          isBusy: _oauthBusy == OAuthProvider.apple,
                          onPressed: (_isLoading || _oauthBusy != null)
                              ? null
                              : () => _signInWithOAuth(OAuthProvider.apple),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
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
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 450.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrContinueWith(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            l10n?.orContinueWith ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String assetPath,
    required String label,
    required bool isGoogleIcon,
    required bool isBusy,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final iconSize = isGoogleIcon ? 24.0 : 20.0;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
      child: isBusy
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  assetPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      isGoogleIcon ? Icons.g_mobiledata : Icons.apple,
                      size: iconSize,
                      color: theme.colorScheme.onSurface,
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}
