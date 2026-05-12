import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/semester_provider.dart';
import '../../models/semester.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_back_button.dart';
import '../../components/destructive_confirmation_dialog.dart';
import '../../l10n/app_localizations.dart';
import 'semester_management_screen.dart';
import '../../components/app_toast.dart';

class CreateSemesterScreen extends ConsumerStatefulWidget {
  final Semester? semesterToEdit;

  /// When true the screen is part of the first-run onboarding flow:
  /// the new semester is automatically set as active and the user
  /// is forwarded to Home instead of being popped back.
  final bool isOnboarding;

  const CreateSemesterScreen({
    super.key,
    this.semesterToEdit,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<CreateSemesterScreen> createState() =>
      _CreateSemesterScreenState();
}

class _CreateSemesterScreenState extends ConsumerState<CreateSemesterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isDeleting = false;
  late String _selectedSeason;
  late int _selectedAcademicStartYear;
  late List<int> _academicYearOptions;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentAcademicStartYear = now.month >= 9 ? now.year : now.year - 1;
    _academicYearOptions = List<int>.generate(
      12,
      (index) => currentAcademicStartYear - 5 + index,
    );

    _selectedAcademicStartYear = currentAcademicStartYear;
    _selectedSeason = now.month >= 9 ? 'fall' : 'spring';
    _nameController = TextEditingController();

    if (widget.semesterToEdit != null) {
      final initial = _parseExistingSemester(widget.semesterToEdit!);
      _selectedSeason = initial.season;
      _selectedAcademicStartYear = initial.academicStartYear;
      _startDate = widget.semesterToEdit?.startDate;
      _endDate = widget.semesterToEdit?.endDate;
      _nameController.text = widget.semesterToEdit!.name;
    } else {
      // Apply with English fallback first; then re-apply once l10n is available.
      _applyAutoFill();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _applyAutoFill(l10n: AppLocalizations.of(context));
          });
        }
      });
    }

    if (!_academicYearOptions.contains(_selectedAcademicStartYear)) {
      _academicYearOptions = [
        ..._academicYearOptions,
        _selectedAcademicStartYear,
      ]..sort();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSemester() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;

    if (_startDate != null && _endDate != null && !_startDate!.isBefore(_endDate!)) {
      AppToast.show(context, l10n.semesterStartBeforeEndError, type: AppToastType.warning);
      return;
    }

    final semesters = ref.read(semesterProvider).value ?? const <Semester>[];
    if (_hasDuplicateSemester(semesters)) {
      AppToast.show(context, l10n.semesterAlreadyExists, type: AppToastType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final semester = Semester(
        id: widget.semesterToEdit?.id ?? '',
        userId: user.id,
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isCurrent: false,
        createdAt: widget.semesterToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.semesterToEdit == null) {
        final created =
            await ref.read(semesterProvider.notifier).addSemester(semester);

        if (widget.isOnboarding && created != null) {
          // First semester — make it active immediately then go to Home.
          await ref
              .read(activeSemesterProvider.notifier)
              .setActiveSemester(created.id);
          if (mounted) context.go('/home');
          return;
        }
      } else {
        await ref.read(semesterProvider.notifier).updateSemester(semester);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, AppLocalizations.of(context)!.networkError, type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSemester() async {
    final semester = widget.semesterToEdit;
    if (semester == null || _isDeleting) return;

    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDestructiveConfirmationDialog(
      context: context,
      title: l10n.delete,
      primaryMessage: l10n.deleteSemesterWarning,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.delete,
    );

    if (!shouldDelete || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(semesterProvider.notifier).deleteSemester(semester.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, l10n.networkError, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _applyAutoFill({AppLocalizations? l10n}) {
    final startYear = _selectedAcademicStartYear;
    final endYear = startYear + 1;

    final fallLabel = l10n?.fallSemester ?? 'Fall';
    final springLabel = l10n?.springSemester ?? 'Spring';

    final generatedName = _selectedSeason == 'fall'
        ? '$startYear-$endYear $fallLabel'
        : '$startYear-$endYear $springLabel';

    final generatedStartDate = _selectedSeason == 'fall'
        ? DateTime(startYear, 9, 1)
        : DateTime(endYear, 2, 1);

    final generatedEndDate = _selectedSeason == 'fall'
        ? DateTime(endYear, 1, 31)
        : DateTime(endYear, 6, 30);

    _nameController.text = generatedName;
    _startDate = generatedStartDate;
    _endDate = generatedEndDate;
  }

  _SemesterDraft _parseExistingSemester(Semester semester) {
    final name = semester.name.toLowerCase();
    final season = name.contains('fall') ? 'fall' : 'spring';
    final parsedStartYear = RegExp(r'(\d{4})').firstMatch(semester.name);
    final year =
        int.tryParse(parsedStartYear?.group(1) ?? '') ??
        (semester.startDate?.year ?? DateTime.now().year);
    return _SemesterDraft(season: season, academicStartYear: year);
  }

  bool _hasDuplicateSemester(List<Semester> semesters) {
    for (final semester in semesters) {
      if (widget.semesterToEdit != null && semester.id == widget.semesterToEdit!.id) {
        continue;
      }

      final parsed = _parseExistingSemester(semester);
      if (parsed.season == _selectedSeason &&
          parsed.academicStartYear == _selectedAcademicStartYear) {
        return true;
      }
    }
    return false;
  }

  String _academicYearLabel(int startYear) {
    final endYear = startYear + 1;
    return '$startYear-$endYear';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: widget.isOnboarding ? const SizedBox.shrink() : AppBackButton(),
        title: Text(
          widget.semesterToEdit == null ? l10n.addSemester : l10n.editSemester,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isOnboarding) ...[
                    Text(
                      l10n.createFirstSemester,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SemesterManagementScreen(),
                            ),
                          );
                        },
                        variant: AppButtonVariant.text,
                        text: l10n.allSemesters,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSectionHeader(l10n.semester),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: l10n.semesterSeason,
                          icon: HeroIcons.sun,
                          value: _selectedSeason,
                          items: [
                            DropdownMenuItem(
                              value: 'fall',
                              child: Text(l10n.fallSemester),
                            ),
                            DropdownMenuItem(
                              value: 'spring',
                              child: Text(l10n.springSemester),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedSeason = value;
                              _applyAutoFill(l10n: AppLocalizations.of(context));
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildDropdownField<int>(
                          label: l10n.academicYearLabel,
                          icon: HeroIcons.calendarDays,
                          value: _selectedAcademicStartYear,
                          selectedTextFontSize: 14,
                          selectedTextMaxLines: 2,
                          items: _academicYearOptions
                              .map(
                                (startYear) => DropdownMenuItem(
                                  value: startYear,
                                  child: Text(_academicYearLabel(startYear)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedAcademicStartYear = value;
                              _applyAutoFill(l10n: AppLocalizations.of(context));
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.semesterName,
                    icon: HeroIcons.calendar,
                    validator: (val) =>
                        val == null || val.isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDatePicker(
                    label: l10n.startDate,
                    value: _startDate,
                    onChanged: (val) => setState(() => _startDate = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDatePicker(
                    label: l10n.endDate,
                    value: _endDate,
                    onChanged: (val) => setState(() => _endDate = val),
                  ),
                  if (widget.semesterToEdit != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Consumer(
                      builder: (context, ref, _) {
                        final activeSemesterId = ref.watch(activeSemesterProvider).value;
                        final isActive =
                            activeSemesterId == widget.semesterToEdit!.id;
                        return AppButton(
                          onPressed: isActive
                              ? null
                              : () async {
                                  await ref
                                      .read(activeSemesterProvider.notifier)
                                      .setActiveSemester(widget.semesterToEdit!.id);
                                },
                          text: isActive
                              ? l10n.currentSemesterLabel
                              : l10n.setAsActive,
                          variant: isActive
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          isFullWidth: true,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl * 2),
                  AppButton(
                    onPressed: _isLoading ? null : _saveSemester,
                    text: _isLoading
                        ? l10n.saving
                        : (widget.semesterToEdit == null
                              ? l10n.createSemester
                              : l10n.updateSemester),
                    isFullWidth: true,
                  ),
                  if (widget.semesterToEdit != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      onPressed: (_isLoading || _isDeleting) ? null : _deleteSemester,
                      isLoading: _isDeleting,
                      text: l10n.delete,
                      variant: AppButtonVariant.secondary,
                      isFullWidth: true,
                      icon: const AppIcon(
                        HeroIcons.trash,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      child: Text(
                        l10n.delete,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required HeroIcons icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorder
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppIcon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  surface: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black,
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? AppColors.glassBorder
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value == null
                      ? AppLocalizations.of(context)!.selectDate
                      : '${value.day}/${value.month}/${value.year}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppIcon(
              HeroIcons.calendar,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required HeroIcons icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double selectedTextFontSize = 16,
    int selectedTextMaxLines = 1,
  }) {
    final theme = Theme.of(context);
    String selectedTitle = '-';
    final options = <AppPickerOption<T>>[];
    for (final item in items) {
      final itemValue = item.value;
      if (itemValue == null) continue;
      final child = item.child;
      String title = '$itemValue';
      if (child is Text) {
        title = child.data ?? title;
      }
      options.add(AppPickerOption<T>(value: itemValue, title: title));
      if (itemValue == value) selectedTitle = title;
    }

    return AppBottomSheetPicker<T>(
      icon: icon,
      fieldLabel: label,
      sheetTitle: label,
      selectedValue: value,
      selectedDisplayText: selectedTitle,
      fieldLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      selectedTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: selectedTextFontSize,
        height: 1.15,
      ),
      selectedTextMaxLines: selectedTextMaxLines,
      options: options,
      onChanged: (selected) => onChanged(selected),
    );
  }
}

class _SemesterDraft {
  const _SemesterDraft({required this.season, required this.academicStartYear});

  final String season;
  final int academicStartYear;
}
