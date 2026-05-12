import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/app_back_button.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_text_field.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam.dart';
import '../../providers/course_provider.dart';
import '../../providers/exams_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_toast.dart';

class CreateExamScreen extends ConsumerStatefulWidget {
  const CreateExamScreen({super.key});

  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _classroomController = TextEditingController();
  final _instructorController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String? _selectedCourseId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isOnline = false;
  ExamType _type = ExamType.midterm;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _classroomController.dispose();
    _instructorController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
      _timeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null || _selectedTime == null) {
      AppToast.show(context, l10n.examsPickDateTimeError, type: AppToastType.warning);
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final examDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isSaving = true);
    try {
      await ref
          .read(examsProvider.notifier)
          .createExam(
            ExamModel(
              id: '',
              userId: userId,
              title: _titleController.text.trim(),
              courseId: _selectedCourseId,
              examDateTime: examDateTime,
              classroom: _classroomController.text.trim().isEmpty
                  ? null
                  : _classroomController.text.trim(),
              isOnline: _isOnline,
              instructorName: _instructorController.text.trim().isEmpty
                  ? null
                  : _instructorController.text.trim(),
              type: _type.dbValue,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
      Haptics.vibrate(HapticsType.success);
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('[CreateExamScreen] create failed: $e');
      if (mounted) {
        AppToast.show(context, '${l10n.examsCreateError}: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(courseProvider);
    final activeSemesterAsync = ref.watch(activeSemesterFullProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.examsAddCta),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _titleController,
                      labelText: l10n.examsTitleField,
                      prefixIcon: HeroIcons.documentText,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.titleRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    activeSemesterAsync.when(
                      data: (semester) => Text(
                        semester == null
                            ? '${l10n.semester}: ${l10n.notSet}'
                            : '${l10n.semester}: ${semester.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => Text(
                        '${l10n.semester}: ...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      error: (_, __) => Text(
                        '${l10n.semester}: ${l10n.notSet}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    coursesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(l10n.errorLoadingCourses),
                      data: (courses) {
                        String display = l10n.examsOptionalCourse;
                        Color? swatch;
                        final options = <AppPickerOption<String>>[
                          AppPickerOption(value: '', title: l10n.noneLinkedDeadline),
                        ];
                        for (final c in courses) {
                          options.add(
                            AppPickerOption(
                              value: c.id,
                              title: c.courseName,
                              subtitle: c.courseCode,
                              swatchColor: c.uiColor,
                            ),
                          );
                          if (c.id == _selectedCourseId) {
                            display = c.courseName;
                            swatch = c.uiColor;
                          }
                        }
                        return AppBottomSheetPicker<String>(
                          icon: HeroIcons.academicCap,
                          fieldLabel: l10n.examsCourseOptionalField,
                          sheetTitle: l10n.selectCourse,
                          selectedValue: _selectedCourseId ?? '',
                          selectedDisplayText: display,
                          selectedSwatchColor: swatch,
                          options: options,
                          onChanged: (v) => setState(
                            () => _selectedCourseId = v.isEmpty ? null : v,
                          ),
                          emptyText: l10n.noCoursesForSemester,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: AppTextField(
                          controller: _dateController,
                          labelText: l10n.examsDateField,
                          prefixIcon: HeroIcons.calendarDays,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: _pickTime,
                      child: AbsorbPointer(
                        child: AppTextField(
                          controller: _timeController,
                          labelText: l10n.examsTimeField,
                          prefixIcon: HeroIcons.clock,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      value: _isOnline,
                      onChanged: (v) => setState(() => _isOnline = v),
                      title: Text(l10n.examsOnlineToggle),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _classroomController,
                      labelText: l10n.examsClassroomField,
                      prefixIcon: HeroIcons.mapPin,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _instructorController,
                      labelText: l10n.examsInstructorField,
                      prefixIcon: HeroIcons.user,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.type, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.examsTypeMidterm),
                          selected: _type == ExamType.midterm,
                          onSelected: (_) => setState(() => _type = ExamType.midterm),
                        ),
                        ChoiceChip(
                          label: Text(l10n.examsTypeFinal),
                          selected: _type == ExamType.finalExam,
                          onSelected: (_) => setState(() => _type = ExamType.finalExam),
                        ),
                        ChoiceChip(
                          label: Text(l10n.examsTypeQuiz),
                          selected: _type == ExamType.quiz,
                          onSelected: (_) => setState(() => _type = ExamType.quiz),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesController,
                      labelText: l10n.examsNotesOptionalField,
                      prefixIcon: HeroIcons.clipboardDocumentList,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      onPressed: _isSaving ? null : _submit,
                      isLoading: _isSaving,
                      text: l10n.examsCreateButton,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
