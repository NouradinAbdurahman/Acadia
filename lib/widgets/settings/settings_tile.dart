import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';

class SettingsTile extends StatelessWidget {
  final HeroIcons icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? textColor;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              AppIcon(
                HeroIcons.chevronRight,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
