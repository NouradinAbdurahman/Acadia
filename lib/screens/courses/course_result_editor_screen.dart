import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course.dart';
import '../../models/course_result.dart';
import '../../models/semester.dart';
import '../../providers/course_provider.dart';
import '../../providers/course_results_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

const _gradeOptions = <String>[
  'AA',
  'BA',
  'BB',
  'CB',
  'CC',
  'DC',
  'DD',
  'FF',
  'EX',
  'NA',
  'S',
  'U',
  'I',
  'P',
  'W',
];

const _gradeLabelByCode = <String, String>{
  'EX': 'EX (EXEMPT)',
  'NA': 'NA (DISCONTINUITY)',
  'S': 'S (SUCCESSFUL)',
  'U': 'U (FAILED)',
  'I': 'I (MISSING)',
  'P': 'P (ONGOING WORK)',
  'W': 'W (WITHDRAWAL)',
};

class CourseResultEditorScreen extends ConsumerStatefulWidget {
  const CourseResultEditorScreen({
    super.key,
    this.resultId,
    this.initialSemesterId,
  });

  final String? resultId;
  final String? initialSemesterId;

  @override
  ConsumerState<CourseResultEditorScreen> createState() =>
      _CourseResultEditorScreenState();
}

class _CourseResultEditorScreenState
    extends ConsumerState<CourseResultEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _finalAverageController = TextEditingController();
  final List<_ComponentDraft> _components = [];

  String? _selectedSemesterId;
  String? _pendingSemesterId;
  String? _selectedCourseId;
  String _selectedLetterGrade = _gradeOptions.first;
  String _selectedResultStatus = 'successful';
  bool _isLoading = false;
  bool _isInitializing = true;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _pendingSemesterId = widget.initialSemesterId;
    _initialize();
  }

  @override
  void dispose() {
    _finalAverageController.dispose();
    for (final component in _components) {
      component.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    if (widget.resultId != null && widget.resultId!.isNotEmpty) {
      final loaded = await ref
          .read(courseResultsProvider.notifier)
          .getResultById(widget.resultId!);
      if (loaded != null) {
        _pendingSemesterId = loaded.semesterId;
        _selectedCourseId = loaded.courseId;
        _selectedLetterGrade = _normalizeLetterGrade(loaded.letterGrade);
        _selectedResultStatus = _normalizeResultStatus(loaded.resultStatus);
        _finalAverageController.text = loaded.finalAverage?.toString() ?? '';
        _createdAt = loaded.createdAt;
        for (final component in loaded.components) {
          _components.add(
            _ComponentDraft(
              title: component.title,
              score: component.score.toString(),
              percentage: component.percentage.toString(),
            ),
          );
        }
      }
    }

    if (_components.isEmpty) _components.add(_ComponentDraft());
    if (mounted) setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semestersAsync = ref.watch(semesterProvider);
    final coursesAsync = ref.watch(courseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resultId == null ? l10n.addResult : l10n.editResult),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : semestersAsync.when(
                  data: (semesters) {
                    _ensureSemester(semesters);
                    final selectedSemesterId = _selectedSemesterId;
                    if (selectedSemesterId == null) {
                      return Center(child: Text(l10n.noSemestersYet));
                    }

                    final allCourses = coursesAsync.value ?? <Course>[];
                    final filteredCourses = _coursesForSemester(
                      allCourses,
                      selectedSemesterId,
                    );
                    final percentageTotal = _currentPercentageTotal();
                    final isPercentageComplete =
                        (percentageTotal - 100).abs() <= 0.01;
                    if (_selectedCourseId != null &&
                        !filteredCourses.any(
                          (c) => c.id == _selectedCourseId,
                        )) {
                      _selectedCourseId = null;
                    }

                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: l10n.overview),
                            const SizedBox(height: AppSpacing.md),
                            _SemesterDropdown(
                              selectedSemesterId: selectedSemesterId,
                              semesters: semesters,
                              onChanged: (semesterId) {
                                if (semesterId == null) return;
                                setState(() {
                                  _selectedSemesterId = semesterId;
                                  _selectedCourseId = null;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CourseDropdown(
                              selectedCourseId: _selectedCourseId,
                              courses: filteredCourses,
                              onChanged: (value) =>
                                  setState(() => _selectedCourseId = value),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(title: l10n.gradingComponents),
                            const SizedBox(height: AppSpacing.sm),
                            ..._components.asMap().entries.map((entry) {
                              final index = entry.key;
                              final component = entry.value;
                              return _ComponentCard(
                                component: component,
                                index: index,
                                onDelete: _components.length == 1
                                    ? null
                                    : () {
                                        setState(() {
                                          _components.removeAt(index).dispose();
                                        });
                                      },
                              );
                            }),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(
                                  '${l10n.percentage}: ${percentageTotal.toStringAsFixed(percentageTotal.truncateToDouble() == percentageTotal ? 0 : 2)}%',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: isPercentageComplete
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              onPressed: () {
                                setState(
                                  () => _components.add(_ComponentDraft()),
                                );
                              },
                              variant: AppButtonVariant.text,
                              text: l10n.addComponent,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(title: l10n.finalSection),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _finalAverageController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.finalAverage,
                                hintText: l10n.finalAverageHint,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppBottomSheetPicker(
                              icon: HeroIcons.academicCap,
                              fieldLabel: l10n.letterGrade,
                              sheetTitle: l10n.letterGrade,
                              selectedValue: _selectedLetterGrade,
                              selectedDisplayText: _displayGradeLabel(
                                _selectedLetterGrade,
                              ),
                              options: _gradeOptions
                                  .map(
                                    (grade) => AppPickerOption(
                                      value: grade,
                                      title: _displayGradeLabel(grade),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedLetterGrade = value);
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppBottomSheetPicker(
                              icon: HeroIcons.checkCircle,
                              fieldLabel: l10n.resultStatus,
                              sheetTitle: l10n.resultStatus,
                              selectedValue: _selectedResultStatus,
                              selectedDisplayText: _displayResultStatusLabel(
                                l10n,
                                _selectedResultStatus,
                              ),
                              options: [
                                AppPickerOption(
                                  value: 'successful',
                                  title: l10n.resultSuccessful,
                                ),
                                AppPickerOption(
                                  value: 'failed',
                                  title: l10n.resultFailed,
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedResultStatus = value);
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _saveResult(selectedSemesterId),
                              isLoading: _isLoading,
                              isFullWidth: true,
                              text: l10n.save,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text(l10n.networkError)),
                ),
        ),
      ),
    );
  }

  void _ensureSemester(List<Semester> semesters) {
    if (_selectedSemesterId != null) return;
    if (semesters.isEmpty) return;

    if (_pendingSemesterId != null &&
        semesters.any((semester) => semester.id == _pendingSemesterId)) {
      _selectedSemesterId = _pendingSemesterId;
      _pendingSemesterId = null;
      return;
    }

    String selected = semesters.first.id;
    for (final semester in semesters) {
      if (semester.isCurrent) {
        selected = semester.id;
        break;
      }
    }
    _selectedSemesterId = selected;
  }

  List<Course> _coursesForSemester(
    List<Course> courses,
    String selectedSemesterId,
  ) {
    return courses
        .where((course) => course.semesterId == selectedSemesterId)
        .toList();
  }

  double _currentPercentageTotal() {
    return _components.fold<double>(0, (sum, component) {
      final value = double.tryParse(component.percentageController.text.trim());
      return sum + (value ?? 0);
    });
  }

  Future<void> _saveResult(String selectedSemesterId) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectCourse)));
      return;
    }
    if (_selectedLetterGrade.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectLetterGrade)));
      return;
    }

    final parsedComponents = <CourseResultComponent>[];
    for (final component in _components) {
      final title = component.titleController.text.trim();
      final score = double.tryParse(component.scoreController.text.trim());
      final percentage = double.tryParse(
        component.percentageController.text.trim(),
      );
      if (title.isEmpty || score == null || percentage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.completeComponentsError)));
        return;
      }
      parsedComponents.add(
        CourseResultComponent(
          id: '',
          resultId: '',
          title: title,
          score: score,
          percentage: percentage,
        ),
      );
    }

    final totalPercentage = parsedComponents.fold<double>(
      0,
      (sum, item) => sum + item.percentage,
    );
    if ((totalPercentage - 100).abs() > 0.01) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.percentageNot100Warning)));
    }

    final finalAverage = _finalAverageController.text.trim().isEmpty
        ? null
        : double.tryParse(_finalAverageController.text.trim());

    setState(() => _isLoading = true);
    final now = DateTime.now();
    final result = CourseResult(
      id: widget.resultId ?? '',
      userId: '',
      courseId: _selectedCourseId!,
      semesterId: selectedSemesterId,
      finalAverage: finalAverage,
      letterGrade: _normalizeLetterGrade(_selectedLetterGrade),
      resultStatus: _normalizeResultStatus(_selectedResultStatus),
      createdAt: _createdAt ?? now,
      updatedAt: now,
      components: parsedComponents,
    );

    await ref
        .read(courseResultsProvider.notifier)
        .saveResult(result: result, semesterId: selectedSemesterId);
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  String _normalizeLetterGrade(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (normalized.isEmpty) return _gradeOptions.first;

    final code = normalized.split(' ').first;
    if (_gradeOptions.contains(code)) return code;
    return _gradeOptions.first;
  }

  String _normalizeResultStatus(String? rawValue) {
    final value = (rawValue ?? '').trim().toLowerCase();
    if (value == 'failed') return 'failed';
    return 'successful';
  }

  String _displayResultStatusLabel(AppLocalizations l10n, String statusCode) {
    return statusCode == 'failed' ? l10n.resultFailed : l10n.resultSuccessful;
  }

  String _displayGradeLabel(String code) {
    return _gradeLabelByCode[code] ?? code;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({
    required this.selectedSemesterId,
    required this.semesters,
    required this.onChanged,
  });

  final String selectedSemesterId;
  final List<Semester> semesters;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String selectedName = '-';
    final options = <AppPickerOption<String>>[];
    for (final semester in semesters) {
      options.add(AppPickerOption(value: semester.id, title: semester.name));
      if (semester.id == selectedSemesterId) selectedName = semester.name;
    }

    return AppBottomSheetPicker(
      icon: HeroIcons.calendarDays,
      fieldLabel: l10n.semester,
      sheetTitle: l10n.semester,
      selectedValue: selectedSemesterId,
      selectedDisplayText: selectedName,
      options: options,
      onChanged: (value) => onChanged(value),
      emptyText: l10n.noSemestersYet,
    );
  }
}

class _CourseDropdown extends StatelessWidget {
  const _CourseDropdown({
    required this.selectedCourseId,
    required this.courses,
    required this.onChanged,
  });

  final String? selectedCourseId;
  final List<Course> courses;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String selectedName = l10n.selectCourse;
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
    }
    if (selectedCourseId != null) {
      for (final course in courses) {
        if (course.id == selectedCourseId) {
          selectedName = course.courseName;
          selectedCourseColor = course.uiColor;
          break;
        }
      }
    }

    return AppBottomSheetPicker(
      icon: HeroIcons.academicCap,
      fieldLabel: l10n.course,
      sheetTitle: l10n.course,
      selectedValue: selectedCourseId,
      selectedDisplayText: selectedName,
      selectedSwatchColor: selectedCourseColor,
      options: options,
      onChanged: (value) => onChanged(value),
      emptyText: l10n.noCoursesForSemester,
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.component,
    required this.index,
    required this.onDelete,
  });

  final _ComponentDraft component;
  final int index;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${l10n.component} ${index + 1}'),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const AppIcon(HeroIcons.trash, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: component.titleController,
              decoration: InputDecoration(
                labelText: l10n.componentTitle,
                hintText: l10n.componentTitleHint,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredField
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: component.scoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.score,
                      hintText: l10n.scoreHint,
                    ),
                    validator: (value) =>
                        double.tryParse((value ?? '').trim()) == null
                        ? l10n.numberRequired
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: component.percentageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.percentage,
                      hintText: l10n.percentageHint,
                    ),
                    validator: (value) =>
                        double.tryParse((value ?? '').trim()) == null
                        ? l10n.numberRequired
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentDraft {
  _ComponentDraft({
    String title = '',
    String score = '',
    String percentage = '',
  }) : titleController = TextEditingController(text: title),
       scoreController = TextEditingController(text: score),
       percentageController = TextEditingController(text: percentage);

  final TextEditingController titleController;
  final TextEditingController scoreController;
  final TextEditingController percentageController;

  void dispose() {
    titleController.dispose();
    scoreController.dispose();
    percentageController.dispose();
  }
}
