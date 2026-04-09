import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course.dart';
import '../../models/course_result.dart';
import '../../models/semester.dart';
import '../../providers/course_provider.dart';
import '../../providers/course_results_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class CourseResultsScreen extends ConsumerWidget {
  const CourseResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final semestersAsync = ref.watch(orderedSemestersProvider);
    final coursesAsync = ref.watch(courseProvider);
    final resultsAsync = ref.watch(courseResultsProvider);
    final activeSemesterId = ref.watch(activeSemesterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.examResults),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: activeSemesterId == null
                ? null
                : () => context.push('/course-results/edit'),
            icon: const AppIcon(HeroIcons.plus),
            tooltip: l10n.addResult,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
              0,
            ),
            child: semestersAsync.when(
              data: (semesters) {
                final currentSemesterId = activeSemesterId;
                if (currentSemesterId == null) {
                  return Center(child: Text(l10n.noSemestersYet));
                }
                final currentSemesterName = _semesterNameById(
                  semesters,
                  currentSemesterId,
                  l10n.noSemestersYet,
                );
                final courses = coursesAsync.value ?? <Course>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppGlassCard(
                      child: Row(
                        children: [
                          AppIcon(
                            HeroIcons.calendarDays,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${l10n.semester}: $currentSemesterName',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: resultsAsync.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return _EmptyResultsState(
                              onAdd: () => context.push('/course-results/edit'),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.xs,
                              right: AppSpacing.xs,
                              bottom: 120,
                            ),
                            itemCount: results.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final result = results[index];
                              final course = _courseById(
                                courses,
                                result.courseId,
                              );
                              return _CourseResultCard(
                                result: result,
                                courseName:
                                    course?.courseName ??
                                    result.courseName ??
                                    l10n.noCoursesYet,
                                courseCode:
                                    course?.courseCode ?? result.courseCode,
                                onEdit: () => context.push(
                                  '/course-results/edit?id=${result.id}',
                                ),
                                onDelete: () async {
                                  await ref
                                      .read(courseResultsProvider.notifier)
                                      .deleteResult(
                                        resultId: result.id,
                                        semesterId: currentSemesterId,
                                      );
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) =>
                            Center(child: Text(l10n.networkError)),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(l10n.networkError)),
            ),
          ),
        ),
      ),
      floatingActionButton: activeSemesterId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/course-results/edit'),
              icon: const AppIcon(
                HeroIcons.plus,
                color: Colors.white,
                size: 18,
              ),
              label: Text(l10n.addResult),
            ),
    );
  }

  Course? _courseById(List<Course> courses, String courseId) {
    for (final course in courses) {
      if (course.id == courseId) return course;
    }
    return null;
  }

  String _semesterNameById(
    List<Semester> semesters,
    String semesterId,
    String fallback,
  ) {
    for (final semester in semesters) {
      if (semester.id == semesterId) {
        return semester.name;
      }
    }
    return fallback;
  }
}

class _EmptyResultsState extends StatelessWidget {
  const _EmptyResultsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HeroIcons.chartBar,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noResultsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.addFirstResultPrompt,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(onPressed: onAdd, text: l10n.addResult),
          ],
        ),
      ),
    );
  }
}

class _CourseResultCard extends StatefulWidget {
  const _CourseResultCard({
    required this.result,
    required this.courseName,
    required this.courseCode,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseResult result;
  final String courseName;
  final String? courseCode;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  State<_CourseResultCard> createState() => _CourseResultCardState();
}

class _CourseResultCardState extends State<_CourseResultCard> {
  bool _expanded = false;
  static const Map<String, String> _gradeLabelByCode = {
    'EX': 'EX (EXEMPT)',
    'NA': 'NA (DISCONTINUITY)',
    'S': 'S (SUCCESSFUL)',
    'U': 'U (FAILED)',
    'I': 'I (MISSING)',
    'P': 'P (ONGOING WORK)',
    'W': 'W (WITHDRAWAL)',
  };

  String _displayLetterGrade(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (normalized.isEmpty) return '-';
    final code = normalized.split(' ').first;
    return _gradeLabelByCode[code] ?? code;
  }

  String _displayGradeCode(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (normalized.isEmpty) return '-';
    return normalized.split(' ').first;
  }

  bool get _isSuccessful =>
      (widget.result.resultStatus ?? 'successful').toLowerCase() != 'failed';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String avgLabel() {
      final avg = widget.result.finalAverage;
      if (avg == null) return '-';
      return avg.toStringAsFixed(avg.truncateToDouble() == avg ? 0 : 2);
    }

    return AppGlassCard(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      _displayGradeCode(widget.result.letterGrade),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.courseCode != null &&
                            widget.courseCode!.trim().isNotEmpty)
                          Text(
                            widget.courseCode!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (widget.courseCode != null &&
                            widget.courseCode!.trim().isNotEmpty)
                          const SizedBox(height: 1),
                        Text(
                          widget.courseName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${l10n.letterGrade}: ${_displayLetterGrade(widget.result.letterGrade)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _isSuccessful
                              ? l10n.resultSuccessful
                              : l10n.resultFailed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _isSuccessful ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(
                    _expanded ? HeroIcons.chevronUp : HeroIcons.chevronDown,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final component in widget.result.components) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.06,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${component.title} (${component.percentage.toStringAsFixed(component.percentage.truncateToDouble() == component.percentage ? 0 : 2)}%)',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            component.score.toStringAsFixed(
                              component.score.truncateToDouble() ==
                                      component.score
                                  ? 0
                                  : 2,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.result.components.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('-', style: theme.textTheme.bodySmall),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.finalAverage,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          avgLabel(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.letterGrade,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          _displayLetterGrade(widget.result.letterGrade),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (_isSuccessful ? Colors.green : Colors.red)
                          .withValues(alpha: 0.12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.resultStatus,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          _isSuccessful
                              ? l10n.resultSuccessful
                              : l10n.resultFailed,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _isSuccessful ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      AppButton(
                        onPressed: widget.onEdit,
                        variant: AppButtonVariant.text,
                        text: l10n.editResult,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        onPressed: () async => widget.onDelete(),
                        variant: AppButtonVariant.text,
                        text: l10n.delete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
