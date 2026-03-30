import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';

class StudyPreferencesScreen extends ConsumerStatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  ConsumerState<StudyPreferencesScreen> createState() => _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState extends ConsumerState<StudyPreferencesScreen> {
  bool _isSaving = false;
  late double _studyHours;
  late String _preferredTime;
  late String _breakPattern;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentProfileProvider).value;
    _studyHours = (profile?.studyHoursPerWeek ?? 20).toDouble();
    _preferredTime = profile?.preferredStudyTime ?? 'morning';
    _breakPattern = profile?.breakPattern ?? 'pomodoro';
  }

  Future<void> _save() async {
    final profile = ref.read(studentProfileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);
    Haptics.vibrate(HapticsType.medium);

    try {
      final updated = profile.copyWith(
        studyHoursPerWeek: _studyHours.toInt(),
        preferredStudyTime: _preferredTime,
        breakPattern: _breakPattern,
      );
      
      // Update in student_profiles table (legacy sync)
      await ref.read(studentProfileProvider.notifier).updateProfile(updated);
      
      // Update in users table (Single source of truth for Risk Engine)
      final appUser = ref.read(currentAppUserProvider).value;
      if (appUser != null) {
        await ref.read(authRepositoryProvider).updateWeeklyStudyGoal(appUser.id, _studyHours.toInt());
        ref.invalidate(currentAppUserProvider);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveChanges)),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studyPreferences),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.studyHoursPerWeek,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.hoursCount(_studyHours.toInt()),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _studyHours,
                    min: 1,
                    max: 80,
                    divisions: 79,
                    label: l10n.hoursCount(_studyHours.toInt()),
                    onChanged: (v) => setState(() => _studyHours = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.preferredStudyTime,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'morning', label: Text(l10n.morning)),
                      ButtonSegment(value: 'afternoon', label: Text(l10n.afternoon)),
                      ButtonSegment(value: 'night', label: Text(l10n.night)),
                    ],
                    selected: {_preferredTime},
                    onSelectionChanged: (selection) {
                      setState(() => _preferredTime = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.breakPattern,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'pomodoro', label: Text(l10n.pomodoro)),
                      ButtonSegment(value: 'deep_work', label: Text(l10n.deepWork)),
                      ButtonSegment(value: 'mixed', label: Text(l10n.mixed)),
                    ],
                    selected: {_breakPattern},
                    onSelectionChanged: (selection) {
                      setState(() => _breakPattern = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    onPressed: _isSaving ? null : _save,
                    isLoading: _isSaving,
                    text: l10n.saveChanges,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
