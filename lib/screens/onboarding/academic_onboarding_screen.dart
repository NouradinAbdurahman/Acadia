import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../models/student_profile.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

class AcademicOnboardingScreen extends ConsumerStatefulWidget {
  const AcademicOnboardingScreen({super.key});

  @override
  ConsumerState<AcademicOnboardingScreen> createState() =>
      _AcademicOnboardingScreenState();
}

class _AcademicOnboardingScreenState
    extends ConsumerState<AcademicOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _showInfoCard = true;
  Timer? _infoCardTimer;
  final int _currentYear = DateTime.now().year;

  // Form Controllers
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();

  String? _selectedDegree;
  int _selectedGradYear = DateTime.now().year + 4;
  int _selectedSemester = 1;
  double _studyHours = DEFAULT_WEEKLY_GOAL.toDouble();
  String _preferredTime = 'morning';
  String _breakPattern = 'pomodoro';

  @override
  void initState() {
    super.initState();
    _prefillForm();
    
    _infoCardTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showInfoCard = false);
      }
    });
  }

  void _prefillForm() {
    final profile = ref.read(studentProfileProvider).value;
    if (profile != null) {
      _universityController.text = profile.universityName ?? '';
      _majorController.text = profile.major ?? '';
      _selectedDegree = profile.degreeType;
        _selectedGradYear = (profile.expectedGraduationYear ?? (DateTime.now().year + 4))
          .clamp(_currentYear, _currentYear + 10)
          .toInt();
        _selectedSemester = profile.currentSemester ?? 1;
        _studyHours = (ref.read(weeklyStudyGoalHoursProvider)).toDouble();
      _preferredTime = profile.preferredStudyTime ?? 'morning';
      _breakPattern = profile.breakPattern ?? 'pomodoro';
    }
  }

  @override
  void dispose() {
    _infoCardTimer?.cancel();
    _pageController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final l10n = AppLocalizations.of(context)!;

    // Simple validation
    if (_currentStep == 0) {
      if (_universityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requiredField)));
        return;
      }
    } else if (_currentStep == 1) {
      if (_majorController.text.trim().isEmpty || _selectedDegree == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requiredField)));
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedSemester < 1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.semesterNumberInvalid)));
        return;
      }
      if (_studyHours < 1 || _studyHours > 80) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.weeklyStudyGoalInvalid)));
        return;
      }
    }

    if (_currentStep < 3) {
      Haptics.vibrate(HapticsType.medium);
      _pageController.nextPage(
        duration: AppDurations.normal,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    Haptics.vibrate(HapticsType.success);

    final existingProfile = ref.read(studentProfileProvider).value;
    final profile = StudentProfile(
      id: '', // Will be handled by upsert
      userId: '', // Will be handled by service
      fullName: existingProfile?.fullName ?? '',
      universityName: _universityController.text.trim(),
      degreeType: _selectedDegree,
      major: _majorController.text.trim(),
      academicYear: null,
      currentSemester: _selectedSemester,
      expectedGraduationYear: _selectedGradYear,
      preferredStudyTime: _preferredTime,
      breakPattern: _breakPattern,
      timezone: DateTime.now().timeZoneName,
      country: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
      onboardingComplete: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      debugPrint('[AcademicOnboarding] Starting profile update...');
      await ref.read(studentProfileProvider.notifier).updateProfile(profile);
      if (!mounted) return;

      debugPrint('[AcademicOnboarding] Marking onboarding complete...');
      await ref.read(studentProfileProvider.notifier).completeOnboarding();
      if (!mounted) return;

      // Persist weekly goal to active semester if one already exists.
      final activeSemester = ref.read(activeSemesterFullProvider).valueOrNull;
      if (activeSemester != null) {
        debugPrint('[AcademicOnboarding] Persisting weekly goal: ${_studyHours.toInt()}');
        await ref.read(semesterProvider.notifier).updateSemester(
              activeSemester.copyWith(weeklyStudyGoal: _studyHours.toInt()),
            );
        if (!mounted) return;
        ref.invalidate(semesterProvider);
        ref.invalidate(weeklyStudyGoalHoursProvider);
      }

      // Force provider to resolve with updated DB state before navigation.
      debugPrint('[AcademicOnboarding] Refreshing user state from DB...');
      await ref.refresh(currentAppUserProvider.future).catchError((_) => null);
      if (!mounted) return;

      debugPrint('[AcademicOnboarding] User state ready. Transitioning to home.');
      context.go('/home');
    } catch (e) {
      debugPrint('[AcademicOnboarding] Error during finish: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.networkError ?? 'Error saving profile'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop:
          ref.watch(studentProfileProvider).value?.onboardingComplete ?? false,
      child: Scaffold(
        body: AuthBackgroundContainer(
          child: SafeArea(
            child: Column(
              children: [
                // Progress Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: AppDurations.normal,
                        child: _showInfoCard
                            ? Padding(
                                key: const ValueKey('onboarding_info_card'),
                                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AppGlassCard(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(AppSpacing.sm),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(AppRadius.lg),
                                            ),
                                            child: AppIcon(
                                              HeroIcons.sparkles,
                                              color: theme.colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n?.academicAnalyticsContext ??
                                                      'This information helps personalize your academic analytics and recommendations.',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  l10n?.onboardingRiskImpactHint ??
                                                      'Your semester and study goal are used to calculate academic risk and progress insights.',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: GestureDetector(
                                        onTap: () {
                                          _infoCardTimer?.cancel();
                                          setState(() => _showInfoCard = false);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(AppSpacing.xs),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: AppIcon(
                                            HeroIcons.xMark,
                                            size: 14,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fade().slideY(begin: -0.2, end: 0),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            IconButton(
                              onPressed: () => _pageController.previousPage(
                                duration: AppDurations.normal,
                                curve: Curves.easeInOut,
                              ),
                              icon: const AppIcon(HeroIcons.chevronLeft),
                            )
                          else
                            const SizedBox(width: 48),

                          Text(
                            l10n?.academicProfileOnboarding ??
                                'Academic Profile',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: List.generate(4, (index) {
                          final isActive = index <= _currentStep;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: AppDurations.normal,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (val) => setState(() => _currentStep = val),
                    children: [
                      _buildIdentityStep(l10n, theme),
                      _buildProgramStep(l10n, theme),
                      _buildLoadStep(l10n, theme),
                      _buildCalibrationStep(l10n, theme),
                    ],
                  ),
                ),

                // Bottom Button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    isLoading: _isSubmitting,
                    text: _currentStep == 3
                        ? (l10n?.getStarted ?? 'Get Started')
                        : (l10n?.next ?? 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityStep(AppLocalizations? l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            l10n?.universitySetup ?? 'University',
            l10n?.universitySetupDesc ??
                'Tell us where you study.',
            HeroIcons.academicCap,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildTextField(
            controller: _universityController,
            label: l10n?.universityName ?? 'University',
            icon: HeroIcons.academicCap,
          ),
        ],
      ).animate().fade().slideY(begin: 0.1),
    );
  }

  Widget _buildProgramStep(AppLocalizations? l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            l10n?.academicProgram ?? 'Academic Program',
            l10n?.programDesc ?? 'Tell us about your field of study.',
            HeroIcons.bookOpen,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDropdown(
            label: l10n?.degreeType ?? 'Degree Type',
            value: (['Bachelor', 'Master', 'PhD'].contains(_selectedDegree))
                ? _selectedDegree
                : null,
            items: {
              'Bachelor': l10n?.bachelor ?? 'Bachelor',
              'Master': l10n?.master ?? 'Master',
              'PhD': l10n?.phd ?? 'PhD',
            },
            icon: HeroIcons.academicCap,
            onChanged: (val) => setState(() => _selectedDegree = val),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _majorController,
            label: l10n?.major ?? 'Major',
            icon: HeroIcons.commandLine,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildNumberPicker(
            label: l10n?.expectedGraduationYear ?? 'Grad Year',
            helperText: l10n?.graduationYearHint ??
                'Choose your expected graduation year (this year or later).',
            value: _selectedGradYear,
            min: _currentYear,
            max: _currentYear + 100,
            onChanged: (val) => setState(() => _selectedGradYear = val),
          ),
        ],
      ).animate().fade().slideY(begin: 0.1),
    );
  }

  Widget _buildLoadStep(AppLocalizations? l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            l10n?.semesterTrackingSetup ?? 'Semester Tracking Setup',
            l10n?.loadDesc ?? 'Help us calibrate your expected workload.',
            HeroIcons.briefcase,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildNumberPicker(
            label: l10n?.currentSemesterNumber ?? 'Current Semester',
            helperText: l10n?.currentSemesterHint ?? 'Enter your current semester number.',
            value: _selectedSemester,
            min: 1,
            max: null,
            onChanged: (val) => setState(() => _selectedSemester = val),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.studyHoursPerWeek ?? 'Weekly Study Goal (Hours)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.glassSurface
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? AppColors.glassBorder
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n?.hoursCount(_studyHours.toInt()) ??
                      '${_studyHours.toInt()} Hours',
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
                  onChanged: (val) {
                    if (val.round() != _studyHours.round()) {
                      Haptics.vibrate(HapticsType.medium);
                    }
                    setState(() => _studyHours = val);
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n?.studyGoalRecommendation ??
                        'Recommended: 10-25 hours per week',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fade().slideY(begin: 0.1),
    );
  }

  Widget _buildCalibrationStep(AppLocalizations? l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            l10n?.optionalPreferencesTitle ?? 'Optional Preferences',
            l10n?.optionalPreferencesDesc ?? 'You can change these later.',
            HeroIcons.sparkles,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.preferredStudyTime ?? 'Preferred Study Time',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSegmentedControl(
            value: _preferredTime,
            options: {
              'morning': l10n?.morning ?? 'Morning',
              'afternoon': l10n?.afternoon ?? 'Afternoon',
              'night': l10n?.night ?? 'Night',
            },
            onChanged: (val) => setState(() => _preferredTime = val),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.breakPattern ?? 'Break Pattern',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSegmentedControl(
            value: _breakPattern,
            options: {
              'pomodoro': l10n?.pomodoro ?? 'Pomodoro',
              'deep_work': l10n?.deepWork ?? 'Deep Work',
              'mixed': l10n?.mixed ?? 'Mixed',
            },
            onChanged: (val) => setState(() => _breakPattern = val),
          ),
        ],
      ).animate().fade().slideY(begin: 0.1),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, HeroIcons icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: AppIcon(icon, color: theme.colorScheme.primary, size: 32),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required HeroIcons icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.glassSurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.glassBorder
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppIcon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required HeroIcons icon,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedValue = items.containsKey(value) ? value : null;
    final selectedText = selectedValue == null
        ? '-'
        : (items[selectedValue] ?? '-');
    final options = items.entries
        .map((e) => AppPickerOption<String>(value: e.key, title: e.value))
        .toList();

    return AppBottomSheetPicker<String>(
      icon: icon,
      fieldLabel: label,
      sheetTitle: label,
      selectedValue: selectedValue,
      selectedDisplayText: selectedText,
      options: options,
      onChanged: (selected) => onChanged(selected),
    );
  }

  Widget _buildNumberPicker({
    required String label,
    String? helperText,
    required int value,
    required int min,
    int? max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.glassSurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.glassBorder
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          if (helperText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helperText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > min
                      ? () {
                          Haptics.vibrate(HapticsType.selection);
                          onChanged(value - 1);
                        }
                      : null,
                  icon: const AppIcon(HeroIcons.minusCircle),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: max == null || value < max
                      ? () {
                          Haptics.vibrate(HapticsType.selection);
                          onChanged(value + 1);
                        }
                      : null,
                  icon: const AppIcon(HeroIcons.plusCircle),
                ),
              ],
            ),
          ),
        ],
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
            ? AppColors.glassSurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.glassBorder
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
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
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                          : theme.textTheme.bodyMedium?.color,
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
