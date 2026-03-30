import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/course_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_icons.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCourseId;
  DateTime? _deadline;
  String _priority = 'medium';
  int? _estimatedHours;

  bool _initialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromTask(Task task) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = task.title;
    _selectedCourseId = task.courseId;
    _priority = task.priority ?? 'medium';
    _estimatedHours = task.estimatedTime;
    _notesController.text = task.notes ?? '';
    _deadline = task.deadline;
    _deadlineController.text = _formatDeadline();
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
        _deadlineController.text = _formatDeadline();
      });
    }
  }

  String _formatDeadline() {
    if (_deadline == null) return AppLocalizations.of(context)!.noDeadline;
    final d = _deadline!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit(Task existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final courses = ref.read(courseProvider).value ?? [];
    String? courseName;
    if (_selectedCourseId != null) {
      courseName = courses.firstWhere((c) => c.id == _selectedCourseId).courseName;
    }

    final updated = Task(
      id: existing.id,
      userId: existing.userId,
      title: _titleController.text.trim(),
      course: courseName,
      courseId: _selectedCourseId,
      deadline: _deadline,
      priority: _priority,
      estimatedTime: _estimatedHours,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: existing.status,
      createdAt: existing.createdAt,
    );

    try {
      await ref.read(tasksProvider.notifier).updateTask(updated);
      Haptics.vibrate(HapticsType.success);
      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editTask),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: tasksAsync.when(
              data: (tasks) {
                final task = tasks.firstWhere(
                  (t) => t.id == widget.taskId,
                  orElse: () => throw Exception(AppLocalizations.of(context)!.taskNotFound),
                );
                _initFromTask(task);

                return SingleChildScrollView(
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.updateTask,
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
                                  label: '$h${AppLocalizations.of(context)!.hoursAbbreviation}',
                                  selected: _estimatedHours == h,
                                  onSelected: (_) => setState(() => _estimatedHours = h),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesController,
                            labelText: '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})',
                            prefixIcon: HeroIcons.clipboardDocumentList,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            onPressed: _isSubmitting ? null : () => _submit(task),
                            isLoading: _isSubmitting,
                            text: AppLocalizations.of(context)!.saveChanges,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: AppDurations.slow).slideY(begin: 0.1),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  AppLocalizations.of(context)!.couldNotLoadTasks,
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
              color: isDark ? AppColors.glassBorder : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              hint: Text(AppLocalizations.of(context)!.selectCourse),
              icon: const AppIcon(HeroIcons.chevronDown, size: 20),
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              validator: (val) => val == null ? AppLocalizations.of(context)!.pleaseSelectCourse : null,
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
      onSelected: (_) => onSelected(value),
      selectedColor: color,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
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
      onSelected: onSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
      ),
    );
  }
}
