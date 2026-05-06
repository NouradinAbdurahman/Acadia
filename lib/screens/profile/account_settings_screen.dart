import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../components/app_back_button.dart';
import '../../components/destructive_confirmation_dialog.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Future<void> clearRememberedCredentials() async {
      final box = Hive.box('settings');
      await box.delete('remembered_email');
      await box.delete('remembered_password');
    }

    Future<void> handleLogout() async {
      await ref.read(authRepositoryProvider).logout();
    }

    Future<void> handleDeleteAccount() async {
      final shouldDelete = await showDestructiveConfirmationDialog(
        context: context,
        title: l10n.deleteAccountTitle,
        primaryMessage: l10n.deleteAccountWarning,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.delete,
      );
      if (!shouldDelete) return;
      await clearRememberedCredentials();
      await handleLogout();
    }

    Widget buildItem({
      required HeroIcons icon,
      required String title,
      Color? textColor,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: () {
          Haptics.vibrate(HapticsType.medium);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIcon(icon, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AppIcon(
                HeroIcons.chevronRight,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSection({
      required String title,
      required List<Widget> children,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 24, AppSpacing.md, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.14 : 0.16,
                ),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 50,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.accountSettings),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                buildSection(
                  title: l10n.accountSettings,
                  children: [
                    buildItem(
                      icon: HeroIcons.shieldCheck,
                      title: l10n.privacyPolicy,
                      onTap: () => context.push('/profile/privacy-policy'),
                    ),
                    buildItem(
                      icon: HeroIcons.documentText,
                      title: l10n.termsOfService,
                      onTap: () => context.push('/profile/terms-of-service'),
                    ),
                    buildItem(
                      icon: HeroIcons.lockClosed,
                      title: l10n.dataPermissionsTitle,
                      onTap: () => context.push('/profile/data-permissions'),
                    ),
                    buildItem(
                      icon: HeroIcons.envelope,
                      title: l10n.contactSupportTitle,
                      onTap: () => context.push('/profile/contact-support'),
                    ),
                    buildItem(
                      icon: HeroIcons.lockClosed,
                      title: l10n.changePassword,
                      onTap: () => context.push('/profile/change-password'),
                    ),
                  ],
                ),
                buildSection(
                  title: l10n.deleteAccountTitle,
                  children: [
                    buildItem(
                      icon: HeroIcons.trash,
                      title: l10n.deleteAccountTitle,
                      textColor: Colors.redAccent,
                      onTap: handleDeleteAccount,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
