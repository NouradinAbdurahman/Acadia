import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    'assets/language.json',
                    fit: BoxFit.contain,
                  ),
                ).animate().fade(duration: AppDurations.slow).scale(delay: AppDurations.micro),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n?.selectLanguage ?? '',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                  ),
                ).animate().fade().slideY(begin: 0.2),
                const SizedBox(height: AppSpacing.xxl),
                AppGlassCard(
                  child: Column(
                    children: [
                      _LanguageOption(
                        title: l10n?.english ?? '',
                        isSelected: currentLocale.languageCode == 'en',
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                        flag: '🇺🇸',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _LanguageOption(
                        title: l10n?.turkish ?? '',
                        isSelected: currentLocale.languageCode == 'tr',
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('tr')),
                        flag: '🇹🇷',
                      ),
                    ],
                  ),
                ).animate().fade(delay: AppDurations.medium).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  onPressed: () {
                    Haptics.vibrate(HapticsType.medium);
                    // Persist the selection and mark the step as finished
                    ref.read(localeProvider.notifier).completeLanguageSelection();
                    // Go to onboarding welcome
                    context.go('/onboarding');
                  },
                  text: l10n?.continueText ?? 'Continue', // Fallback to 'Continue' if l10n is null
                ).animate().fade(delay: AppDurations.slow).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final String flag;

  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Haptics.vibrate(HapticsType.light);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
            ),
            const Spacer(),
            if (isSelected)
              AppIcon(
                HeroIcons.checkCircle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
