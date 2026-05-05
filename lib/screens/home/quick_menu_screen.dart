import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme/app_gradients.dart';
import '../../l10n/app_localizations.dart';
import 'quick_menu_nav_items.dart';

class QuickMenuScreen extends StatelessWidget {
  const QuickMenuScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickMenuScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewPadding = MediaQuery.of(context).viewPadding;

    final items = buildQuickMenuNavItems(l10n)
        .map(
          (e) => _QuickMenuItem(
            icon: e.icon,
            title: e.title,
            route: e.route,
          ),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.darkBackground : AppGradients.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notch/Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    l10n.quickMenu,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Haptics.vibrate(HapticsType.selection);
                      context.pop();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const AppIcon(HeroIcons.xMark, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Content
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl + viewPadding.bottom,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _QuickMenuCard(
                    item: item,
                      onTap: () {
                        Haptics.vibrate(HapticsType.medium);
                        context.pop(); // Close sheet
                        context.push(item.route);
                      },
                    theme: theme,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({
    required this.item,
    required this.onTap,
    required this.theme,
  });

  final _QuickMenuItem item;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(item.icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuItem {
  const _QuickMenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  final HeroIcons icon;
  final String title;
  final String route;
}
