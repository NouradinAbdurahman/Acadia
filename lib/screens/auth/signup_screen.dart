import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_spacing.dart';

import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/app_back_button.dart';
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
  OAuthProvider? _oauthBusy;
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
        final timeStr =
            '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, "0")}';
        setState(
          () => _errorMessage = l10n?.emailRateLimitWithTimer(timeStr) ?? '',
        );
      } else {
        setState(() => _errorMessage = l10n?.emailRateLimit ?? '');
      }
      return;
    }

    // 2. Check Signup Success Cooldown
    if (!authRepo.canSignup()) {
      setState(() => _errorMessage = l10n?.pleaseWait ?? '');
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
        if (user != null &&
            user.identities != null &&
            user.identities!.isEmpty) {
          setState(() {
            _errorMessage = l10n?.emailAlreadyInUse ?? '';
          });
          debugPrint('SIGNUP ERROR: email_already_in_use');
          Haptics.vibrate(HapticsType.error);
          return;
        }

        debugPrint('SIGNUP SUCCESS');
        context.push(
          '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}&fullName=${Uri.encodeComponent(_nameController.text.trim())}',
        );
      }
    } on TimeoutException {
      Haptics.vibrate(HapticsType.error);
      debugPrint('SIGNUP ERROR: timeout');
      if (mounted) {
        setState(() => _errorMessage = l10n?.requestTimedOut ?? '');
      }
    } on AuthApiException catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        String msg = l10n?.networkError ?? '';
        final lower = e.message.toLowerCase();

        if (e.code == 'over_email_send_rate_limit' ||
            lower.contains('rate limit')) {
          debugPrint('SIGNUP ERROR: rate_limit detected');
          msg = l10n?.emailRateLimit ?? '';
        } else if (lower.contains('already registered') ||
            e.code == 'user_already_exists') {
          msg = l10n?.emailAlreadyInUse ?? '';
        } else if (e.code == 'invalid_email' ||
            lower.contains('invalid email')) {
          msg = l10n?.invalidEmail ?? '';
        } else if (e.code == 'weak_password') {
          msg = l10n?.passwordTooShort ?? '';
        } else if (e.code == 'signup_cooldown') {
          msg = l10n?.pleaseWait ?? '';
        } else {
          msg = e.message;
        }

        setState(() => _errorMessage = msg);
      }
    } on SocketException {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        setState(() => _errorMessage = l10n?.checkInternetConnection ?? '');
      }
    } catch (e) {
      Haptics.vibrate(HapticsType.error);
      if (mounted) {
        final errText = e.toString();
        if (errText.contains('SocketException') ||
            errText.contains('ClientException')) {
          setState(() => _errorMessage = l10n?.checkInternetConnection ?? '');
        } else {
          setState(() => _errorMessage = l10n?.networkError ?? '');
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
        ? theme.colorScheme.surface.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.06);
    final fieldBorderColor = isLight
        ? theme.colorScheme.outline.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.15);
    final fieldFocusedBorderColor = isLight
        ? theme.colorScheme.primary.withValues(alpha: 0.78)
        : theme.colorScheme.primary.withValues(alpha: 0.9);
    final authRepo = ref.read(authRepositoryProvider);
    final isEmailLimited = authRepo.isBlockedForEmail();
    final remainingTime = authRepo.remainingEmailRateLimitTime();

    String buttonText = l10n?.signup ?? '';
    if (isEmailLimited && remainingTime.inSeconds > 0) {
      final minutes = remainingTime.inMinutes;
      final seconds = remainingTime.inSeconds % 60;
      final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
      buttonText = l10n?.emailRateLimitWithTimer(timeStr) ?? '';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: AppBackButton(),
        title: const SizedBox.shrink(),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
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
                        SizedBox(
                          height: 120,
                          child: Hero(
                            tag: 'app_header_logo_signup',
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ).animate().fade().slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n?.appName ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n?.signupSubtitle ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.lg),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.3,
                                ),
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
                              controller: _nameController,
                              labelText: l10n?.fullName ?? '',
                              prefixIcon: HeroIcons.user,
                              fillColor: fieldFillColor,
                              borderColor: fieldBorderColor,
                              focusedBorderColor: fieldFocusedBorderColor,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? (l10n?.requiredField ?? '')
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _emailController,
                              labelText: l10n?.email ?? '',
                              prefixIcon: HeroIcons.envelope,
                              fillColor: fieldFillColor,
                              borderColor: fieldBorderColor,
                              focusedBorderColor: fieldFocusedBorderColor,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value == null ||
                                      value.isEmpty ||
                                      !value.contains('@')
                                  ? (l10n?.invalidEmail ?? '')
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _passwordController,
                              onChanged: (_) => setState(() {}),
                              labelText: l10n?.password ?? '',
                              prefixIcon: HeroIcons.lockClosed,
                              fillColor: fieldFillColor,
                              borderColor: fieldBorderColor,
                              focusedBorderColor: fieldFocusedBorderColor,
                              obscureText: true,
                              validator: (value) =>
                                  validatePasswordForSignup(value, l10n),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Column(
                                children: [
                                  if (_passwordController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            passwordStrengthLabel(
                                              _passwordController.text,
                                              l10n,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: passwordStrengthColor(
                                                    theme,
                                                    _passwordController.text,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (_passwordController.text.length <
                                              8)
                                            Text(
                                              '${_passwordController.text.length}/8',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
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
                              fillColor: fieldFillColor,
                              borderColor: fieldBorderColor,
                              focusedBorderColor: fieldFocusedBorderColor,
                              obscureText: true,
                              validator: (value) =>
                                  validateConfirmPasswordForSignup(
                                    value,
                                    _passwordController.text,
                                    l10n,
                                  ),
                            ),
                          ],
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          onPressed:
                              (_isLoading ||
                                  isEmailLimited ||
                                  _oauthBusy != null)
                              ? null
                              : _signUp,
                          isLoading: _isLoading,
                          text: buttonText,
                          isFullWidth: true,
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                        // ======================================================
                        // TEMPORARILY DISABLED
                        //
                        // Google Sign-In and Apple Sign-In are intentionally
                        // hidden from the UI for the current App Store release.
                        //
                        // The implementation is preserved below and must NOT
                        // be removed — it only renders when the corresponding
                        // FeatureFlags.enable*SignIn flag is true.
                        //
                        // To re-enable:
                        // 1. Configure Apple/Google OAuth in Supabase.
                        // 2. Set FeatureFlags.enableAppleSignIn /
                        //    enableGoogleSignIn = true in
                        //    lib/core/config/feature_flags.dart.
                        // 3. Verify Apple Developer / Google Cloud credentials.
                        //
                        // See docs/authentication/OAUTH_REENABLE_GUIDE.md
                        // ======================================================
                        if (FeatureFlags.enableAnyOAuth) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildOrContinueWith(
                            context,
                          ).animate().fade(delay: 350.ms).slideY(begin: 0.1),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              if (FeatureFlags.enableGoogleSignIn)
                                Expanded(
                                  child: _buildSocialButton(
                                    context: context,
                                    assetPath: 'assets/google.png',
                                    label: l10n?.googleLabel ?? '',
                                    isGoogleIcon: true,
                                    isBusy: _oauthBusy == OAuthProvider.google,
                                    onPressed:
                                        (_isLoading || _oauthBusy != null)
                                        ? null
                                        : () => _signInWithOAuth(
                                            OAuthProvider.google,
                                          ),
                                  ),
                                ),
                              if (FeatureFlags.enableGoogleSignIn &&
                                  FeatureFlags.enableAppleSignIn)
                                const SizedBox(width: AppSpacing.sm),
                              if (FeatureFlags.enableAppleSignIn)
                                Expanded(
                                  child: _buildSocialButton(
                                    context: context,
                                    assetPath: 'assets/icons/apple.png',
                                    label: l10n?.appleLabel ?? '',
                                    isGoogleIcon: false,
                                    isBusy: _oauthBusy == OAuthProvider.apple,
                                    onPressed:
                                        (_isLoading || _oauthBusy != null)
                                        ? null
                                        : () => _signInWithOAuth(
                                            OAuthProvider.apple,
                                          ),
                                  ),
                                ),
                            ],
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          onPressed: () => context.pop(),
                          variant: AppButtonVariant.text,
                          text: '',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
