import 'dart:ui';

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
import '../../components/app_back_button.dart';

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
  final Set<String> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(courseProvider);
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
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

                final sortedCourses = courses.where((c) => !_dismissedIds.contains(c.id)).toList();
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
                    final semCompare = a.academicSemester.compareTo(
                      b.academicSemester,
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
        showCheckmark: false,
        elevation: 0,
        onSelected: (val) {
          Haptics.vibrate(HapticsType.selection);
          onSelected(val);
        },
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.3 : 0.5,
                  )
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : theme.colorScheme.outline.withValues(alpha: 0.3)),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: AppButton(
              onPressed: () => context.push('/create-course'),
              icon: const AppIcon(HeroIcons.plus, size: 20, color: Colors.white),
              text: l10n.addFirstCourseBtn,
            ),
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
        final theme = Theme.of(context);
        final confirmed = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withValues(alpha: 0.6),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim1, anim2) => const SizedBox(),
          transitionBuilder: (context, anim1, anim2, child) {
            return FadeTransition(
              opacity: anim1,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const AppIcon(
                                    HeroIcons.exclamationTriangle,
                                    color: Color(0xFFEF4444),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.deleteCourse,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.examDetailDeleteWarning,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.deleteCourseWarning,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _WarningDialogButton(
                                        label: l10n.cancel,
                                        isOutline: true,
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _WarningDialogButton(
                                        label: l10n.delete,
                                        isDanger: true,
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        setState(() => _dismissedIds.add(course.id));
        Haptics.vibrate(HapticsType.error);
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
                      '${course.courseCode ?? '---'} • ${l10n.semester} ${course.academicSemester}',
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

class _WarningDialogButton extends StatelessWidget {
  const _WarningDialogButton({
    required this.label,
    required this.onPressed,
    this.isOutline = false,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isOutline;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = const Color(0xFFEF4444);

    final backgroundColor = isDanger
        ? danger
        : (isOutline ? Colors.transparent : theme.colorScheme.primary);
    final foregroundColor = isDanger
        ? Colors.white
        : (isOutline ? theme.colorScheme.onSurface : Colors.white);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isOutline
                ? Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
