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
import '../../models/mood_settings.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class MoodSettingsScreen extends ConsumerStatefulWidget {
  const MoodSettingsScreen({super.key});

  @override
  ConsumerState<MoodSettingsScreen> createState() => _MoodSettingsScreenState();
}

class _MoodSettingsScreenState extends ConsumerState<MoodSettingsScreen> {
  bool _initialized = false;
  bool _trackingEnabled = true;
  bool _reminderEnabled = true;
  String _reminderType = 'both';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(moodSettingsProvider);
    final notifier = ref.read(moodSettingsProvider.notifier);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBackButton(),
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
                        },
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildToggleRow(
                        context,
                        icon: HeroIcons.bell,
                        title: l10n.enableMoodReminders,
                        value: settings.trackingEnabled && settings.reminderEnabled,
                        onChanged: settings.trackingEnabled
                            ? (value) {
                                Haptics.vibrate(HapticsType.medium);
                                notifier.toggleReminders(value);
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AppIcon(
                          HeroIcons.clock,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(l10n.reminderTimeLabel),
                        subtitle: Text(settings.reminderTime ?? '20:00'),
                        trailing: const AppIcon(HeroIcons.chevronRight),
                        onTap: (settings.trackingEnabled && settings.reminderEnabled)
                            ? () {
                                Haptics.vibrate(HapticsType.selection);
                                _pickTime(context, settings.reminderTime ?? '20:00', (time) {
                                  notifier.updateReminderTime(time);
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.reminderTypeLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSegmentedControl(
                        value: settings.reminderType,
                        enabled: settings.trackingEnabled && settings.reminderEnabled,
                        options: {
                          'daily': l10n.reminderTypeDaily,
                          'session': l10n.reminderTypeAfterStudy,
                          'both': l10n.reminderTypeBoth,
                        },
                        onChanged: (value) => notifier.updateReminderType(value),
                      ),
                      if (settings.trackingEnabled && settings.reminderEnabled) ...[
                        const SizedBox(height: AppSpacing.lg),
                        InkWell(
                          onTap: (settings.trackingEnabled && settings.reminderEnabled)
                              ? () {
                                  Haptics.vibrate(HapticsType.selection);
                                  _pickTime(context, settings.reminderTime ?? '20:00', (time) {
                                    notifier.updateReminderTime(time);
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                AppIcon(
                                  HeroIcons.checkCircle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminder enabled',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Next: Today at ${settings.reminderTime ?? '20:00'}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const AppIcon(HeroIcons.pencilSquare, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ] else if (settings.trackingEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Text(
                            'Reminders disabled. Enable above to receive notifications.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
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

  Widget _buildSegmentedControl({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.06)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: options.entries.map((entry) {
              final isSelected = value == entry.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Haptics.vibrate(HapticsType.selection);
                    onChanged(entry.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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

  Future<void> _pickTime(BuildContext context, String current, Function(String) onPicked) async {
    final parts = current.split(':');
    final initial = parts.length >= 2 
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 20, minute: 0);

    final next = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (next == null) return;
    final hh = next.hour.toString().padLeft(2, '0');
    final mm = next.minute.toString().padLeft(2, '0');
    Haptics.vibrate(HapticsType.success);
    onPicked('$hh:$mm');
  }
}

