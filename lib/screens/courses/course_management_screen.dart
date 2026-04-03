import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../providers/course_provider.dart';
import '../../providers/study_sessions_provider.dart';
import '../../models/course.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import 'create_course_screen.dart';
import 'semester_management_screen.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../components/app_glass_card.dart';

enum _CourseSort { semester, alphabetical, studyTime }

class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() =>
      _CourseManagementScreenState();
}

class _CourseManagementScreenState
    extends ConsumerState<CourseManagementScreen> {
  _CourseSort _sortBy = _CourseSort.semester;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(courseProvider);
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myCourses),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Haptics.vibrate(HapticsType.light);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SemesterManagementScreen(),
                ),
              );
            },
            icon: const AppIcon(HeroIcons.calendar, size: 24),
            tooltip: l10n.manageSemesters,
          ),
          IconButton(
            onPressed: () {
              Haptics.vibrate(HapticsType.light);
              context.push('/course-results');
            },
            icon: const AppIcon(HeroIcons.chartBar, size: 24),
            tooltip: l10n.examResults,
          ),
          IconButton(
            onPressed: () {
              Haptics.vibrate(HapticsType.light);
              context.push('/create-course');
            },
            icon: const AppIcon(HeroIcons.plus, size: 24),
            tooltip: l10n.addCourse,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: sessionsAsync.when(
            data: (sessions) => coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return _buildEmptyState(context, l10n);
                }

                final studyMinutesByCourse = <String, int>{};
                for (final session in sessions) {
                  studyMinutesByCourse.update(
                    session.courseId,
                    (value) => value + session.durationMinutes,
                    ifAbsent: () => session.durationMinutes,
                  );
                }

                final sortedCourses = [...courses];
                if (_sortBy == _CourseSort.alphabetical) {
                  sortedCourses.sort(
                    (a, b) => a.courseName.compareTo(b.courseName),
                  );
                } else if (_sortBy == _CourseSort.studyTime) {
                  sortedCourses.sort(
                    (a, b) => (studyMinutesByCourse[b.id] ?? 0).compareTo(
                      studyMinutesByCourse[a.id] ?? 0,
                    ),
                  );
                } else {
                  sortedCourses.sort((a, b) {
                    final semCompare = (a.semester ?? 0).compareTo(
                      b.semester ?? 0,
                    );
                    if (semCompare != 0) return semCompare;
                    return a.courseName.compareTo(b.courseName);
                  });
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildSortSection(l10n),
                    const SizedBox(height: AppSpacing.md),
                    ...sortedCourses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildCourseCard(
                          context,
                          ref,
                          course,
                          l10n,
                          studyMinutesByCourse[course.id] ?? 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.networkError)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.networkError)),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: l10n.semester,
            selected: _sortBy == _CourseSort.semester,
            onSelected: (_) => setState(() => _sortBy = _CourseSort.semester),
          ),
          _buildFilterChip(
            label: l10n.sortAlphabetical,
            selected: _sortBy == _CourseSort.alphabetical,
            onSelected: (_) =>
                setState(() => _sortBy = _CourseSort.alphabetical),
          ),
          _buildFilterChip(
            label: l10n.sortStudyTime,
            selected: _sortBy == _CourseSort.studyTime,
            onSelected: (_) => setState(() => _sortBy = _CourseSort.studyTime),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: selected
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              HeroIcons.bookOpen,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.noCoursesYet,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.addFirstCourse,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            onPressed: () => context.push('/create-course'),
            icon: const AppIcon(HeroIcons.plus, size: 20, color: Colors.white),
            text: l10n.addFirstCourseBtn,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    WidgetRef ref,
    Course course,
    AppLocalizations l10n,
    int studyMinutes,
  ) {
    final theme = Theme.of(context);
    final courseColor = course.uiColor;
    final formattedStudyTime = _formatStudyDuration(
      l10n: l10n,
      totalMinutes: studyMinutes,
    );

    return Dismissible(
      key: Key(course.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteCourse),
            content: Text(l10n.deleteCourseWarning),
            actions: [
              AppButton(
                onPressed: () => Navigator.pop(context, false),
                variant: AppButtonVariant.text,
                text: l10n.cancel,
              ),
              AppButton(
                onPressed: () => Navigator.pop(context, true),
                variant: AppButtonVariant.text,
                text: l10n.delete,
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(courseProvider.notifier).deleteCourse(course.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const AppIcon(HeroIcons.trash, color: Colors.white),
      ),
      child: AnimatedPressable(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCourseScreen(courseToEdit: course),
            ),
          );
        },
        child: AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 48,
                decoration: BoxDecoration(
                  color: courseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${course.courseCode ?? '---'} • ${l10n.semester} ${course.semester ?? 0}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.sortStudyTime}: $formattedStudyTime',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${course.credits} ${l10n.creditsLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: courseColor,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${course.ects} ECTS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIcon(
                HeroIcons.chevronRight,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStudyDuration({
    required AppLocalizations l10n,
    required int totalMinutes,
  }) {
    if (totalMinutes <= 0) return '0${l10n.minutesAbbreviation}';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes${l10n.minutesAbbreviation}';
    if (minutes == 0) return '$hours${l10n.hoursAbbreviation}';
    return '$hours${l10n.hoursAbbreviation} $minutes${l10n.minutesAbbreviation}';
  }
}
