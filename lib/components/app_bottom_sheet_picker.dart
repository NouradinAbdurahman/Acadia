import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';

import '../core/design/app_icons.dart';
import '../core/design/app_spacing.dart';
import 'app_glass_card.dart';

class AppPickerOption<T> {
  const AppPickerOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.swatchColor,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Color? swatchColor;
}

class AppBottomSheetPicker<T> extends StatelessWidget {
  const AppBottomSheetPicker({
    super.key,
    required this.icon,
    required this.fieldLabel,
    required this.sheetTitle,
    required this.selectedValue,
    required this.selectedDisplayText,
    required this.options,
    required this.onChanged,
    this.emptyText,
    this.selectedSwatchColor,
    this.fieldLabelTextStyle,
    this.selectedTextStyle,
    this.selectedTextMaxLines = 2,
  });

  final HeroIcons icon;
  final String fieldLabel;
  final String sheetTitle;
  final T? selectedValue;
  final String selectedDisplayText;
  final List<AppPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? emptyText;
  final Color? selectedSwatchColor;
  final TextStyle? fieldLabelTextStyle;
  final TextStyle? selectedTextStyle;
  final int selectedTextMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedDisplayText.trim().isNotEmpty;

    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Haptics.vibrate(HapticsType.medium);
          _openPicker(context, theme);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Center(
                  child: AppIcon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          fieldLabelTextStyle ??
                          theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDisplayText,
                      maxLines: selectedTextMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style:
                          selectedTextStyle ??
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                          ),
                    ),
                  ],
                ),
              ),
              if (selectedSwatchColor != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedSwatchColor,
                      boxShadow: [
                        BoxShadow(
                          color: selectedSwatchColor!.withValues(alpha: 0.38),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              AppIcon(
                HeroIcons.chevronDown,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, ThemeData theme) async {
    final selected = await showAppBottomSheetPicker<T>(
      context: context,
      theme: theme,
      icon: icon,
      sheetTitle: sheetTitle,
      options: options,
      selectedValue: selectedValue,
      emptyText: emptyText,
    );

    if (selected == null) return;
    onChanged(selected);
  }
}

Future<T?> showAppBottomSheetPicker<T>({
  required BuildContext context,
  required ThemeData theme,
  required HeroIcons icon,
  required String sheetTitle,
  required List<AppPickerOption<T>> options,
  required T? selectedValue,
  String? emptyText,
}) async {
  final isDark = theme.brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.14,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Center(
                          child: AppIcon(
                            icon,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sheetTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Tap an item to select',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
                if (options.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        emptyText ?? '-',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: options.length,
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Divider(
                          height: 1,
                          indent: AppSpacing.sm,
                          endIndent: AppSpacing.sm,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option.value == selectedValue;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Haptics.vibrate(HapticsType.selection);
                              Navigator.pop(context, option.value);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (option.swatchColor != null)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        right: AppSpacing.sm,
                                      ),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: option.swatchColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: option.swatchColor!
                                                .withValues(alpha: 0.38),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.title,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                        ),
                                        if (option.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            option.subtitle!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.68),
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.primary,
                                      ),
                                      child: Center(
                                        child: AppIcon(
                                          HeroIcons.check,
                                          color: theme.colorScheme.onPrimary,
                                          solid: true,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
