import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tasks_provider.dart';
import '../../providers/deadlines_provider.dart';
import '../../models/deadline.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/app_back_button.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../providers/course_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, this.initialDeadlineId});

  /// When set (e.g. from deadline detail), pre-fills link and due date.
  final String? initialDeadlineId;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCourseId;
  DateTime? _deadline;
  String _priority = 'medium';
  int? _estimatedHours;
  String? _linkedDeadlineId;

  bool _isSubmitting = false;
  bool _initialDeadlineSynced = false;

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.colorScheme.primary,
              brightness: theme.brightness,
              primary: theme.colorScheme.primary,
              surface: theme.colorScheme.surface,
              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadline = picked;
        _deadlineController.text = _formatDeadline(context);
      });
    }
  }

  String _formatDeadline(BuildContext context) {
    if (_deadline == null) return AppLocalizations.of(context)!.noDeadline;
    final d = _deadline!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectCourse)));
      return;
    }

    final courses = ref.read(courseProvider).value ?? [];
    if (courses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addCourseFirst)));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final selectedCourse = courses.firstWhere(
        (c) => c.id == _selectedCourseId,
      );
      await ref
          .read(tasksProvider.notifier)
          .createTask(
            title: _titleController.text.trim(),
            course: selectedCourse.courseName,
            courseId: _selectedCourseId,
            deadline: _deadline,
            deadlineId: _linkedDeadlineId,
            priority: _priority,
            estimatedHours: _estimatedHours,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      Haptics.vibrate(HapticsType.success);
      if (mounted) {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _trySyncInitialDeadline(List<Deadline> deadlines) {
    if (_initialDeadlineSynced) return;
    final param = widget.initialDeadlineId;
    if (param == null || param.isEmpty) {
      _initialDeadlineSynced = true;
      return;
    }
    Deadline? match;
    for (final d in deadlines) {
      if (d.id == param) {
        match = d;
        break;
      }
    }
    if (match == null) {
      _initialDeadlineSynced = true;
      return;
    }
    _initialDeadlineSynced = true;
    setState(() {
      _linkedDeadlineId = match!.id;
      _deadline ??= DateTime(
        match.deadlineDate.year,
        match.deadlineDate.month,
        match.deadlineDate.day,
      );
      _deadlineController.text = _formatDeadline(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(deadlinesProvider).whenData(_trySyncInitialDeadline);
    if (_deadlineController.text.isEmpty) {
      _deadlineController.text = _formatDeadline(context);
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(AppLocalizations.of(context)!.createTask),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppGlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.newAcademicTask,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _titleController,
                        labelText: AppLocalizations.of(context)!.taskTitle,
                        prefixIcon: HeroIcons.documentText,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? AppLocalizations.of(context)!.titleRequired
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCourseDropdown(),
                      const SizedBox(height: AppSpacing.md),
                      _buildLinkedDeadlinePicker(),
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: _pickDeadline,
                        child: AbsorbPointer(
                          child: AppTextField(
                            controller: _deadlineController,
                            labelText: AppLocalizations.of(context)!.deadlines,
                            prefixIcon: HeroIcons.calendarDays,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context)!.priority,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PriorityChip(
                            label: AppLocalizations.of(context)!.low,
                            value: 'low',
                            groupValue: _priority,
                            color: theme.colorScheme.primary,
                            onSelected: (v) => setState(() => _priority = v),
                          ),
                          _PriorityChip(
                            label: AppLocalizations.of(context)!.medium,
                            value: 'medium',
                            groupValue: _priority,
                            color: theme.colorScheme.secondary,
                            onSelected: (v) => setState(() => _priority = v),
                          ),
                          _PriorityChip(
                            label: AppLocalizations.of(context)!.high,
                            value: 'high',
                            groupValue: _priority,
                            color: theme.colorScheme.error,
                            onSelected: (v) => setState(() => _priority = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context)!.estimatedStudyTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final h in [1, 2, 3, 4])
                            _HourChip(
                              label:
                                  '$h${AppLocalizations.of(context)!.hoursAbbreviation}',
                              selected: _estimatedHours == h,
                              onSelected: (_) =>
                                  setState(() => _estimatedHours = h),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _notesController,
                        labelText:
                            '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})',
                        prefixIcon: HeroIcons.clipboardDocumentList,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        onPressed: _isSubmitting ? null : _submit,
                        isLoading: _isSubmitting,
                        text: AppLocalizations.of(context)!.createTask,
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: AppDurations.slow).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  String _shortDeadlineDate(Deadline d) {
    return '${d.deadlineDate.day.toString().padLeft(2, '0')}/${d.deadlineDate.month.toString().padLeft(2, '0')}/${d.deadlineDate.year}';
  }

  Widget _buildLinkedDeadlinePicker() {
    final l10n = AppLocalizations.of(context)!;
    final deadlinesAsync = ref.watch(deadlinesProvider);

    return deadlinesAsync.when(
      data: (deadlines) {
        final filtered = _selectedCourseId == null
            ? [...deadlines]
            : deadlines.where((d) => d.courseId == _selectedCourseId).toList();
        final useList = filtered.isEmpty ? [...deadlines] : filtered;
        useList.sort((a, b) => a.deadlineDate.compareTo(b.deadlineDate));

        var selectedTitle = l10n.noneLinkedDeadline;
        final options = <AppPickerOption<String>>[
          AppPickerOption(value: '', title: l10n.noneLinkedDeadline),
        ];

        for (final d in useList) {
          if (d.isCompleted) continue;
          options.add(
            AppPickerOption(
              value: d.id,
              title: d.title,
              subtitle: '${d.course} · ${_shortDeadlineDate(d)}',
            ),
          );
          if (_linkedDeadlineId != null && d.id == _linkedDeadlineId) {
            selectedTitle = d.title;
          }
        }

        return AppBottomSheetPicker<String>(
          icon: HeroIcons.clipboardDocumentList,
          fieldLabel: l10n.linkToAcademicDeadline,
          sheetTitle: l10n.linkToAcademicDeadline,
          selectedValue: _linkedDeadlineId ?? '',
          selectedDisplayText:
              _linkedDeadlineId == null || _linkedDeadlineId!.isEmpty
              ? l10n.noneLinkedDeadline
              : selectedTitle,
          options: options,
          onChanged: (v) => setState(() {
            _linkedDeadlineId = v.isEmpty ? null : v;
          }),
          emptyText: l10n.noDeadlinesYet,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          Text(AppLocalizations.of(context)!.couldNotLoadDeadlines),
    );
  }

  Widget _buildCourseDropdown() {
    final coursesAsync = ref.watch(courseProvider);
    final l10n = AppLocalizations.of(context)!;

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return AppButton(
            onPressed: () => context.push('/create-course'),
            text: l10n.addCourseFirst,
            variant: AppButtonVariant.secondary,
          );
        }

        String selectedCourseName = l10n.selectCourse;
        Color? selectedCourseColor;
        final options = <AppPickerOption<String>>[];
        for (final course in courses) {
          options.add(
            AppPickerOption(
              value: course.id,
              title: course.courseName,
              subtitle: course.courseCode,
              swatchColor: course.uiColor,
            ),
          );
          if (course.id == _selectedCourseId) {
            selectedCourseName = course.courseName;
            selectedCourseColor = course.uiColor;
          }
        }

        return AppBottomSheetPicker<String>(
          icon: HeroIcons.academicCap,
          fieldLabel: l10n.course,
          sheetTitle: l10n.course,
          selectedValue: _selectedCourseId,
          selectedDisplayText: selectedCourseName,
          selectedSwatchColor: selectedCourseColor,
          options: options,
          onChanged: (val) => setState(() => _selectedCourseId = val),
          emptyText: l10n.noCoursesYet,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.errorLoadingCourses),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        Haptics.vibrate(HapticsType.selection);
        onSelected(value);
      },
      selectedColor: color,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected
              ? color
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
      ),
    );
  }
}

class _HourChip extends StatelessWidget {
  const _HourChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        Haptics.vibrate(HapticsType.selection);
        onSelected(val);
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
      ),
    );
  }
}
