import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

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
    final settingsAsync = ref.watch(moodSettingsProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text(l10n.networkError)),
            data: (settings) {
              _initializeOnce(settings);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const AppIcon(HeroIcons.arrowLeft),
                        ),
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
                            value: _trackingEnabled,
                            onChanged: (value) => _updateSettings(
                              trackingEnabled: value,
                            ),
                          ),
                          const Divider(height: AppSpacing.xl),
                          _buildToggleRow(
                            context,
                            icon: HeroIcons.bell,
                            title: l10n.enableMoodReminders,
                            value: _trackingEnabled && _reminderEnabled,
                            onChanged: _trackingEnabled
                                ? (value) => _updateSettings(
                                      reminderEnabled: value,
                                    )
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
                            subtitle: Text(_formatTime(context, _reminderTime)),
                            trailing: const AppIcon(HeroIcons.chevronRight),
                            onTap: (_trackingEnabled && _reminderEnabled)
                                ? _pickTime
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
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment<String>(
                                value: 'daily',
                                label: Text(l10n.reminderTypeDaily),
                              ),
                              ButtonSegment<String>(
                                value: 'session',
                                label: Text(l10n.reminderTypeAfterStudy),
                              ),
                              ButtonSegment<String>(
                                value: 'both',
                                label: Text(l10n.reminderTypeBoth),
                              ),
                            ],
                            selected: {_reminderType},
                            onSelectionChanged:
                                (_trackingEnabled && _reminderEnabled)
                                    ? (selection) {
                                        final next = selection.first;
                                        _updateSettings(reminderType: next);
                                      }
                                    : null,
                            showSelectedIcon: false,
                          ),
                          if (_trackingEnabled && _reminderEnabled) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
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
                                          'Next: Today at ${_formatTime(context, _reminderTime)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_trackingEnabled)
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
                        onTap: () => context.push('/mood/history'),
                      ),
                    ),
                  ],
                ),
              );
            },
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

  void _initializeOnce(MoodSettings? settings) {
    if (_initialized) return;

    _trackingEnabled = settings?.trackingEnabled ?? true;
    _reminderEnabled = settings?.reminderEnabled ?? true;
    _reminderType = settings?.reminderType ?? 'both';

    final parsedTime = _parseReminderTime(settings?.reminderTime);
    _reminderTime = parsedTime ?? const TimeOfDay(hour: 20, minute: 0);

    _initialized = true;
  }

  TimeOfDay? _parseReminderTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: true,
    );
  }

  String _toDbTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTime() async {
    final next = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (next == null) return;
    setState(() => _reminderTime = next);
    await _updateSettings(reminderTime: next);
  }

  Future<void> _updateSettings({
    bool? trackingEnabled,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    String? reminderType,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    if (trackingEnabled != null) {
      setState(() => _trackingEnabled = trackingEnabled);
      if (!trackingEnabled) {
        setState(() => _reminderEnabled = false);
      }
    }
    if (reminderEnabled != null) {
      setState(() => _reminderEnabled = reminderEnabled);
    }
    if (reminderTime != null) {
      setState(() => _reminderTime = reminderTime);
    }
    if (reminderType != null) {
      setState(() => _reminderType = reminderType);
    }

    if (_isSaving) return;
    _isSaving = true;

    try {
      final settings = MoodSettings(
        userId: userId,
        trackingEnabled: _trackingEnabled,
        reminderEnabled: _trackingEnabled && _reminderEnabled,
        reminderTime: _toDbTime(_reminderTime),
        reminderType: _reminderType,
      );

      await ref.read(moodActionsProvider).saveMoodSettings(settings);

      final shouldScheduleDaily =
          settings.trackingEnabled &&
          settings.reminderEnabled &&
          (settings.reminderType == 'daily' || settings.reminderType == 'both');

      if (shouldScheduleDaily) {
        await ref.read(moodActionsProvider).scheduleDailyMoodReminder(
              time: settings.reminderTime ?? '20:00',
              title: l10n.moodReminderTitle,
              body: l10n.moodReminderBody,
            );
      } else {
        await ref.read(moodActionsProvider).cancelDailyMoodReminder();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkError)),
        );
      }
    } finally {
      _isSaving = false;
    }
  }
}
