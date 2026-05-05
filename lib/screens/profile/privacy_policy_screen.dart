import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_back_button.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/auth/auth_background_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget section(HeroIcons icon, String title, List<String> lines) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeroIcon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              color: theme.colorScheme.surface.withValues(alpha: 0.22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        '• $line',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
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
                        l10n.privacyPolicy,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                    color: theme.colorScheme.surface.withValues(alpha: 0.18),
                  ),
                  child: Row(
                    children: [
                      HeroIcon(
                        HeroIcons.shieldCheck,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.privacyPolicyEffectiveDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.privacyPolicyIntro,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                section(HeroIcons.circleStack, l10n.privacyPolicyCollectedTitle, [
                  l10n.privacyPolicyCollectedAccount,
                  l10n.privacyPolicyCollectedAcademic,
                  l10n.privacyPolicyCollectedMood,
                ]),
                section(HeroIcons.cog6Tooth, l10n.privacyPolicyUseTitle, [
                  l10n.privacyPolicyUseAnalytics,
                  l10n.privacyPolicyUseAi,
                  l10n.privacyPolicyUseFeatures,
                ]),
                section(HeroIcons.serverStack, l10n.privacyPolicyStorageTitle, [
                  l10n.privacyPolicyStorageSupabase,
                  l10n.privacyPolicyStorageRetention,
                ]),
                section(HeroIcons.bell, l10n.privacyPolicyNotificationsTitle, [
                  l10n.privacyPolicyNotificationsLocalOnly,
                ]),
                section(HeroIcons.adjustmentsHorizontal, l10n.privacyPolicyControlTitle, [
                  l10n.privacyPolicyControlMood,
                  l10n.privacyPolicyControlDelete,
                ]),
                Text(
                  l10n.privacyPolicyNoSell,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.privacyPolicyThirdParty,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.privacyPolicyAiDisclaimer,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.legalContactLine,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
