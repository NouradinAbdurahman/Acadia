import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_text_field.dart';
import '../../components/app_button.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../providers/deadlines_provider.dart';
import '../../providers/course_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/auth/auth_background_container.dart';

class EditDeadlineScreen extends ConsumerStatefulWidget {
  const EditDeadlineScreen({super.key, required this.deadlineId});

  final String deadlineId;

  @override
  ConsumerState<EditDeadlineScreen> createState() => _EditDeadlineScreenState();
}

class _EditDeadlineScreenState extends ConsumerState<EditDeadlineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _deadlineDate;
  String _deadlineType = 'assignment';
  String _priority = 'medium';
  String? _selectedCourseId;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromDeadline(dynamic deadline) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = deadline.title;
    _deadlineDate = deadline.deadlineDate;
    _deadlineType = deadline.deadlineType;
    _priority = deadline.priority;
    _selectedCourseId = deadline.courseId;
    _notesController.text = deadline.notes ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _deadlineDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _deadlineDate = picked;
    });
  }

  Future<void> _submit(dynamic existing) async {
    final l10n = AppLocalizations.of(context)!;
    if (_deadlineDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDate)));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
      _isSaving = true;
    });

    try {
      final selectedCourse = courses.firstWhere(
        (c) => c.id == _selectedCourseId,
      );

      await ref.read(deadlinesProvider.notifier).updateDeadline(existing.id, {
        'title': _titleController.text.trim(),
        'course': selectedCourse.courseName,
        'course_id': _selectedCourseId,
        'deadline_date': _deadlineDate!.toIso8601String(),
        'deadline_type': _deadlineType,
        'priority': _priority,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      Haptics.vibrate(HapticsType.success);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final deadlinesAsync = ref.watch(deadlinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deadlines),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: deadlinesAsync.when(
              data: (items) {
                final matched = items
                    .where((d) => d.id == widget.deadlineId)
                    .toList();
                if (matched.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noDeadlinesYet,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                final deadline = matched.first;
                _initFromDeadline(deadline);

                return SingleChildScrollView(
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.createDeadline,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _titleController,
                            labelText: l10n.title,
                            prefixIcon: HeroIcons.documentText,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? l10n.titleRequired
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildCourseDropdown(),
                          const SizedBox(height: AppSpacing.md),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: AppTextField(
                                controller: TextEditingController(
                                  text: _deadlineDate == null
                                      ? ''
                                      : '${_deadlineDate!.day.toString().padLeft(2, '0')}/${_deadlineDate!.month.toString().padLeft(2, '0')}/${_deadlineDate!.year}',
                                ),
                                labelText: l10n.deadlineDate,
                                prefixIcon: HeroIcons.calendarDays,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(l10n.type, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _ChoiceStyleChip(
                                label: l10n.assignment,
                                value: 'assignment',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) =>
                                    setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.exam,
                                value: 'exam',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) =>
                                    setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.quiz,
                                value: 'quiz',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) =>
                                    setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.project,
                                value: 'project',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) =>
                                    setState(() => _deadlineType = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.priority,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ChoiceStyleChip(
                                label: l10n.low,
                                value: 'low',
                                groupValue: _priority,
                                color: theme.colorScheme.primary,
                                onSelected: (v) =>
                                    setState(() => _priority = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.medium,
                                value: 'medium',
                                groupValue: _priority,
                                color: theme.colorScheme.secondary,
                                onSelected: (v) =>
                                    setState(() => _priority = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.high,
                                value: 'high',
                                groupValue: _priority,
                                color: theme.colorScheme.error,
                                onSelected: (v) =>
                                    setState(() => _priority = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesController,
                            labelText: '${l10n.notes} (${l10n.optional})',
                            prefixIcon: HeroIcons.clipboardDocumentList,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            onPressed: _isSaving
                                ? null
                                : () => _submit(deadline),
                            text: _isSaving ? l10n.saving : l10n.saveChanges,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: AppDurations.slow).slideY(begin: 0.1),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  l10n.couldNotLoadDeadlines,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
      ),
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

class _ChoiceStyleChip extends StatelessWidget {
  const _ChoiceStyleChip({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
