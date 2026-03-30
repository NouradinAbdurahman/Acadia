import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_text_field.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_icons.dart';
import '../../core/theme/app_colors.dart';
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
    if (_deadlineDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectDate)),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final courses = ref.read(courseProvider).value ?? [];
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.addCourseFirst)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final selectedCourse =
          courses.firstWhere((c) => c.id == _selectedCourseId);

      await ref.read(deadlinesProvider.notifier).updateDeadline(
        existing.id,
        {
          'title': _titleController.text.trim(),
          'course': selectedCourse.courseName,
          'course_id': _selectedCourseId,
          'deadline_date': _deadlineDate!.toIso8601String(),
          'deadline_type': _deadlineType,
          'priority': _priority,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        },
      );

      Haptics.vibrate(HapticsType.success);
      if (mounted) context.pop();
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
                final matched =
                    items.where((d) => d.id == widget.deadlineId).toList();
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
                            validator: (value) => value == null || value.trim().isEmpty
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
                          Text(
                            l10n.type,
                            style: theme.textTheme.bodyMedium,
                          ),
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
                                onSelected: (v) => setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.exam,
                                value: 'exam',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) => setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.quiz,
                                value: 'quiz',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) => setState(() => _deadlineType = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.project,
                                value: 'project',
                                groupValue: _deadlineType,
                                color: theme.colorScheme.primary,
                                onSelected: (v) => setState(() => _deadlineType = v),
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
                                onSelected: (v) => setState(() => _priority = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.medium,
                                value: 'medium',
                                groupValue: _priority,
                                color: theme.colorScheme.secondary,
                                onSelected: (v) => setState(() => _priority = v),
                              ),
                              _ChoiceStyleChip(
                                label: l10n.high,
                                value: 'high',
                                groupValue: _priority,
                                color: theme.colorScheme.error,
                                onSelected: (v) => setState(() => _priority = v),
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
                            onPressed: _isSaving ? null : () => _submit(deadline),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return AppButton(
            onPressed: () => context.push('/create-course'),
            text: AppLocalizations.of(context)!.addCourseFirst,
            variant: AppButtonVariant.secondary,
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorder
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              hint: Text(AppLocalizations.of(context)!.selectCourse),
              icon: const AppIcon(HeroIcons.chevronDown, size: 20),
              isExpanded: true,
              itemHeight: null,
              dropdownColor: theme.colorScheme.surface,
              validator: (val) => val == null
                  ? AppLocalizations.of(context)!.pleaseSelectCourse
                  : null,
              selectedItemBuilder: (context) {
                return courses.map((course) {
                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: course.uiColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.courseName,
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: courses.map((course) {
                return DropdownMenuItem(
                  value: course.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: course.uiColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.courseName,
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCourseId = val),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: AppLocalizations.of(context)!.course,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: AppIcon(HeroIcons.academicCap, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(AppLocalizations.of(context)!.errorLoadingCourses),
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
      onSelected: (_) => onSelected(value),
      selectedColor: color,
      backgroundColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
