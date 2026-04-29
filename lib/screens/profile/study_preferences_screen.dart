import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_back_button.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class StudyPreferencesScreen extends ConsumerStatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  ConsumerState<StudyPreferencesScreen> createState() =>
      _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState
    extends ConsumerState<StudyPreferencesScreen> {
  bool _isSaving = false;
  double? _studyHours;
  late String _preferredTime;
  late String _breakPattern;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentProfileProvider).value;

    _preferredTime = profile?.preferredStudyTime ?? 'morning';
    _breakPattern = profile?.breakPattern ?? 'pomodoro';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeeklyGoal();
    });
  }

  Future<void> _loadWeeklyGoal() async {
    final activeSemester = ref.read(activeSemesterFullProvider).valueOrNull;
    if (!mounted) return;

    setState(() {
      _studyHours =
          (activeSemester?.weeklyStudyGoal ?? DEFAULT_WEEKLY_GOAL).toDouble();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.read(studentProfileProvider).value;
    final activeSemester = ref.read(activeSemesterFullProvider).valueOrNull;
    if (activeSemester == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.startTrackingYourSemester)));
      }
      return;
    }
    final weeklyGoalHours =
      (_studyHours ?? ref.read(weeklyStudyGoalHoursProvider).toDouble())
        .toInt();

    setState(() => _isSaving = true);
    Haptics.vibrate(HapticsType.medium);

    try {
      if (profile != null) {
        final updated = profile.copyWith(
          preferredStudyTime: _preferredTime,
          breakPattern: _breakPattern,
        );

        // Save non-goal study preferences in student_profiles.
        await ref.read(studentProfileProvider.notifier).updateProfile(updated);
      }

      // Save weekly goal in active semester (single source of truth).
      await ref.read(semesterProvider.notifier).updateSemester(
        activeSemester.copyWith(weeklyStudyGoal: weeklyGoalHours),
          );

      ref.invalidate(semesterProvider);
      ref.invalidate(weeklyStudyGoalHoursProvider);

      if (mounted) {
        setState(() {
          _studyHours =
              ref.read(weeklyStudyGoalHoursProvider).toDouble();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveChanges)),
        );
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
        if (context.canPop()) context.pop();
        if (!context.canPop()) {
          ref.read(bottomNavProvider.notifier).state = 4;
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
    final hasActiveSemester = ref.watch(activeSemesterFullProvider).valueOrNull != null;
    final fallbackGoal = ref.watch(weeklyStudyGoalHoursProvider).toDouble();
    final goalValue = _studyHours ?? fallbackGoal;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.hoursCount(goalValue.toInt()),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: goalValue,
                    min: 5,
                    max: 40,
                    divisions: 35,
                    label: l10n.hoursCount(goalValue.toInt()),
                    onChanged: hasActiveSemester
                        ? (v) {
                            if (v.round() != (goalValue).toInt()) {
                              Haptics.vibrate(HapticsType.medium);
                            }
                            setState(() => _studyHours = v);
                          }
                        : null,
                  ),
                  Text(
                    l10n.onboardingRiskImpactHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.preferredStudyTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSegmentedControl(
                    value: _preferredTime,
                    options: {
                      'morning': l10n.morning,
                      'afternoon': l10n.afternoon,
                      'night': l10n.night,
                    },
                    onChanged: (val) => setState(() => _preferredTime = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.breakPattern,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSegmentedControl(
                    value: _breakPattern,
                    options: {
                      'pomodoro': l10n.pomodoro,
                      'deep_work': l10n.deepWork,
                      'mixed': l10n.mixed,
                    },
                    onChanged: (val) => setState(() => _breakPattern = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.optionalPreferencesDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    onPressed: (_isSaving || !hasActiveSemester) ? null : _save,
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

  Widget _buildSegmentedControl({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
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
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
