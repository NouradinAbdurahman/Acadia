import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../components/app_back_button.dart';

import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class MoodSettingsScreen extends ConsumerStatefulWidget {
  const MoodSettingsScreen({super.key});

  @override
  ConsumerState<MoodSettingsScreen> createState() => _MoodSettingsScreenState();
}

class _MoodSettingsScreenState extends ConsumerState<MoodSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(moodSettingsProvider);
    final notifier = ref.read(moodSettingsProvider.notifier);
    final todayMoodAsync = ref.watch(todayMoodProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppBackButton(alignToContentEdge: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.moodSettingsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (ref.watch(moodSettingsProvider.notifier).shouldShowDaily)
                  todayMoodAsync.when(
                    data: (hasLoggedToday) {
                      if (!hasLoggedToday) {
                        return _buildMoodEntryCard(context, theme, l10n);
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                if (ref.watch(moodSettingsProvider.notifier).shouldShowDaily &&
                    !(todayMoodAsync.asData?.value ?? true))
                  const SizedBox(height: AppSpacing.md),
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        context,
                        icon: HeroIcons.faceSmile,
                        title: l10n.enableMoodTracking,
                        value: settings.trackingEnabled,
                        onChanged: (value) {
                          Haptics.vibrate(HapticsType.medium);
                          notifier.toggleTracking(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? l10n.moodTrackingNowEnabled
                                    : l10n.moodTrackingNowDisabled,
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            settings.trackingEnabled
                                ? l10n.moodTrackingStatusActive
                                : l10n.moodTrackingStatusOff,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: settings.trackingEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AppIcon(
                      HeroIcons.clock,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.moodHistoryTitle),
                    trailing: const AppIcon(HeroIcons.chevronRight),
                    onTap: () {
                      Haptics.vibrate(HapticsType.medium);
                      context.push('/mood/history');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required HeroIcons icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        AppIcon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMoodEntryCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return AppGlassCard(
      borderOnly: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moodDailyPromptTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.moodDailyPromptSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.push('/mood/log'),
            icon: AppIcon(
              HeroIcons.plusCircle,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              l10n.logMoodTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

