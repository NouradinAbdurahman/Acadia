import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_button.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_back_button.dart';
import '../../models/student_profile.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../components/app_toast.dart';

class EditAcademicProfileScreen extends ConsumerStatefulWidget {
  const EditAcademicProfileScreen({super.key});

  @override
  ConsumerState<EditAcademicProfileScreen> createState() =>
      _EditAcademicProfileScreenState();
}

class _EditAcademicProfileScreenState
    extends ConsumerState<EditAcademicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;

  String? _selectedDegree;
  late int _selectedGradYear;
  late int _selectedYear;
  late int _selectedSemester;
  late double _studyHours;
  late String _preferredTime;
  late String _breakPattern;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentProfileProvider).value;

    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _universityController = TextEditingController(
      text: profile?.universityName ?? '',
    );
    _majorController = TextEditingController(text: profile?.major ?? '');
    _selectedDegree = profile?.degreeType ?? 'Bachelor';
    _selectedGradYear =
        profile?.expectedGraduationYear ?? (DateTime.now().year + 4);
    _selectedYear = (profile?.academicYear ?? 1).clamp(1, 10).toInt();
    _selectedSemester = profile?.currentSemester ?? 1;

    // Fix: Watch the centralized goal provider instead of reading from profile
    final currentGoal = ref.read(weeklyStudyGoalHoursProvider);
    _studyHours = currentGoal.toDouble();

    _preferredTime = profile?.preferredStudyTime ?? 'morning';
    _breakPattern = profile?.breakPattern ?? 'pomodoro';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_selectedSemester < 1) {
      AppToast.show(
        context,
        l10n.semesterNumberInvalid,
        type: AppToastType.warning,
      );
      return;
    }

    if (_studyHours < 5 || _studyHours > 40) {
      AppToast.show(
        context,
        l10n.weeklyStudyGoalInvalid,
        type: AppToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Haptics.vibrate(HapticsType.medium);

    final currentProfile = ref.read(studentProfileProvider).value;
    final normalizedFullName = _nameController.text.trim();
    final normalizedUniversity = _universityController.text.trim();
    final normalizedMajor = _majorController.text.trim();
    final updatedProfile = StudentProfile(
      id: currentProfile?.id ?? '',
      userId: currentProfile?.userId ?? '',
      fullName: normalizedFullName,
      universityName: normalizedUniversity,
      degreeType: _selectedDegree,
      major: normalizedMajor,
      academicYear: _selectedYear,
      currentSemester: _selectedSemester,
      expectedGraduationYear: _selectedGradYear,
      preferredStudyTime: _preferredTime,
      breakPattern: _breakPattern,
      timezone: currentProfile?.timezone ?? DateTime.now().timeZoneName,
      country:
          currentProfile?.country ??
          WidgetsBinding.instance.platformDispatcher.locale.countryCode,
      onboardingComplete: true,
      createdAt: currentProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(studentProfileProvider.notifier)
          .updateProfile(updatedProfile);

      // Keep weekly goal scoped to active semester.
      final activeSemester = ref.read(activeSemesterFullProvider).valueOrNull;
      if (activeSemester != null) {
        await ref
            .read(semesterProvider.notifier)
            .updateSemester(
              activeSemester.copyWith(weeklyStudyGoal: _studyHours.toInt()),
            );
        ref.invalidate(semesterProvider);
        ref.invalidate(weeklyStudyGoalHoursProvider);
        if (mounted) {
          _studyHours = ref.read(weeklyStudyGoalHoursProvider).toDouble();
        }
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
        AppToast.show(
          context,
          AppLocalizations.of(context)!.saveChanges,
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.toString(), type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(l10n.editProfile),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    l10n.basicIdentity,
                    HeroIcons.identification,
                  ),
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.fullName,
                    icon: HeroIcons.user,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _universityController,
                    label: l10n.universityName,
                    icon: HeroIcons.academicCap,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.academicProgram, HeroIcons.bookOpen),
                  _buildDropdown(
                    label: l10n.degreeType,
                    value:
                        ([
                          'Bachelor',
                          'Master',
                          'PhD',
                        ].contains(_selectedDegree))
                        ? _selectedDegree
                        : 'Bachelor',
                    items: {
                      'Bachelor': l10n.bachelor,
                      'Master': l10n.master,
                      'PhD': l10n.phd,
                    },
                    icon: HeroIcons.academicCap,
                    onChanged: (val) => setState(() => _selectedDegree = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _majorController,
                    label: l10n.major,
                    icon: HeroIcons.commandLine,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumberPicker(
                    label: l10n.expectedGraduationYear,
                    value: _selectedGradYear,
                    min: DateTime.now().year - 5,
                    max: DateTime.now().year + 10,
                    onChanged: (val) => setState(() => _selectedGradYear = val),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(
                    l10n.currentSemesterLoad,
                    HeroIcons.briefcase,
                  ),
                  _buildNumberPicker(
                    label: l10n.academicYear,
                    value: _selectedYear,
                    min: 1,
                    max: 10,
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumberPicker(
                    label: l10n.currentSemesterNumber,
                    value: _selectedSemester,
                    min: 1,
                    max: null,
                    onChanged: (val) => setState(() => _selectedSemester = val),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.studyHoursPerWeek,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStudyHoursSlider(theme),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.onboardingRiskImpactHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(
                    l10n.learningPatternCalibration,
                    HeroIcons.sparkles,
                  ),
                  Text(
                    l10n.preferredStudyTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSegmentedControl(
                    value: _preferredTime,
                    options: {
                      'morning': l10n.morning,
                      'afternoon': l10n.afternoon,
                      'night': l10n.night,
                    },
                    onChanged: (val) => setState(() => _preferredTime = val),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.breakPattern,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    onPressed: _isSubmitting ? null : _saveChanges,
                    isLoading: _isSubmitting,
                    text: l10n.saveChanges,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, HeroIcons icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          AppIcon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppIcon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
        validator: (val) => (val == null || val.isEmpty)
            ? AppLocalizations.of(context)!.requiredField
            : null,
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
    required int value,
    required int min,
    int? max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.glassSurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: value > min
                    ? () {
                        Haptics.vibrate(HapticsType.selection);
                        onChanged(value - 1);
                      }
                    : null,
                icon: const AppIcon(HeroIcons.minusCircle, size: 20),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  value.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: max == null || value < max
                    ? () {
                        Haptics.vibrate(HapticsType.selection);
                        onChanged(value + 1);
                      }
                    : null,
                icon: const AppIcon(HeroIcons.plusCircle, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyHoursSlider(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.glassSurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.hoursCount(_studyHours.toInt()),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _studyHours,
            min: 5,
            max: 40,
            divisions: 35,
            onChanged: (val) {
              if (val.round() != _studyHours.round()) {
                Haptics.vibrate(HapticsType.medium);
              }
              setState(() => _studyHours = val);
            },
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
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.25,
                            ),
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
