import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../models/deadline.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../providers/deadlines_provider.dart';
import '../../domain/academic_deadline_task.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../providers/bottom_nav_provider.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  String? _lastAppliedQueryFilter;
  String _selectedCourse = 'All';

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final tasksAsync = ref.watch(filteredTasksProvider);
    final deadlinesAsync = ref.watch(filteredDeadlinesProvider);
    final filter = ref.watch(taskFilterProvider);
    final segment = ref.watch(tasksListSegmentProvider);
    final theme = Theme.of(context);
    final routeState = GoRouterState.of(context);
    final queryFilter = routeState.uri.queryParameters['filter'];
    final isDashboardFocus =
        routeState.uri.queryParameters['source'] == 'dashboard';
    final currentSemesterTasks = tasksAsync.valueOrNull ?? const [];
    final currentSemesterDeadlines = deadlinesAsync.valueOrNull ?? const [];
    final courseOptions = _buildCourseOptions(
      currentSemesterTasks,
      currentSemesterDeadlines,
    );
    final selectedCourse = _effectiveCourse(courseOptions, _selectedCourse);
    final showCourseFilter = _shouldShowCourseFilter(courseOptions);

    _syncFilterFromQuery(ref, queryFilter, isDashboardFocus);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isDashboardFocus)
                            IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                  return;
                                }
                                ref.read(bottomNavProvider.notifier).state = 0;
                                context.go('/home');
                              },
                              icon: const AppIcon(HeroIcons.arrowLeft),
                              tooltip: AppLocalizations.of(context)!.backToHome,
                            ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.tasks,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showCreateOptions(context),
                            icon: AppIcon(
                              HeroIcons.plus,
                              color: theme.colorScheme.onSurface,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                            ),
                          ),
                        ],
                      ).animate().fade().slideX(begin: -0.1),
                      const SizedBox(height: AppSpacing.lg),
                      if (isDashboardFocus) ...[
                        if (showCourseFilter)
                          _CourseFilterPicker(
                            courses: courseOptions,
                            selectedCourse: selectedCourse,
                            onChanged: (value) {
                              setState(() => _selectedCourse = value);
                            },
                          ),
                        if (showCourseFilter)
                          const SizedBox(height: AppSpacing.md),
                        _SegmentTabs(
                          currentSegment: segment,
                          includeAll: true,
                          onSegmentChanged: (value) {
                            ref.read(tasksListSegmentProvider.notifier).state =
                                value;
                          },
                        ),
                      ] else ...[
                        _SegmentTabs(
                          currentSegment: segment,
                          onSegmentChanged: (value) {
                            ref.read(tasksListSegmentProvider.notifier).state =
                                value;
                          },
                        ),
                        if (showCourseFilter) ...[
                          const SizedBox(height: AppSpacing.md),
                          _CourseFilterPicker(
                            courses: courseOptions,
                            selectedCourse: selectedCourse,
                            onChanged: (value) {
                              setState(() => _selectedCourse = value);
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _StatusFilterTabs(
                          currentFilter: filter,
                          onFilterChanged: (value) =>
                              ref.read(taskFilterProvider.notifier).state =
                                  value,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildFilteredContent(
                    context: context,
                    tasksAsync: tasksAsync,
                    deadlinesAsync: deadlinesAsync,
                    segment: segment,
                    selectedCourse: selectedCourse,
                    isOverviewSource: isDashboardFocus,
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    Haptics.vibrate(HapticsType.medium);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.xl),
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.stayOrganized,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: l10n.createTask,
                    icon: HeroIcons.clipboardDocumentCheck,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/create-task');
                    },
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _CreateOptionCard(
                    title: l10n.createDeadline,
                    icon: HeroIcons.calendarDays,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/create-deadline');
                    },
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _syncFilterFromQuery(
    WidgetRef ref,
    String? queryFilter,
    bool isOverviewSource,
  ) {
    if (queryFilter == null) return;
    if (_lastAppliedQueryFilter == queryFilter) return;

    if (queryFilter == 'tasks') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tasksListSegmentProvider.notifier).state = 'tasks';
        ref.read(taskFilterProvider.notifier).state =
            isOverviewSource ? 'pending' : 'all';
      });
      _lastAppliedQueryFilter = queryFilter;
      return;
    }

    if (queryFilter == 'deadlines') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tasksListSegmentProvider.notifier).state = 'deadlines';
        ref.read(taskFilterProvider.notifier).state =
            isOverviewSource ? 'pending' : 'all';
      });
      _lastAppliedQueryFilter = queryFilter;
      return;
    }

    if (queryFilter == 'all') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tasksListSegmentProvider.notifier).state = 'all';
        ref.read(taskFilterProvider.notifier).state =
            isOverviewSource ? 'pending' : 'all';
      });
      _lastAppliedQueryFilter = queryFilter;
      return;
    }

    final allowedFilters = {'all', 'pending', 'completed', 'overdue'};
    if (!allowedFilters.contains(queryFilter)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(taskFilterProvider.notifier).state = queryFilter;
    });
    _lastAppliedQueryFilter = queryFilter;
  }

  Widget _buildFilteredContent({
    required BuildContext context,
    required AsyncValue<List<Task>> tasksAsync,
    required AsyncValue<List<Deadline>> deadlinesAsync,
    required String segment,
    required String selectedCourse,
    required bool isOverviewSource,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    List<Task> overviewTasksOnly(List<Task> tasks) {
      if (!isOverviewSource) return tasks;
      return tasks.where((task) => !task.isCompleted).toList();
    }

    List<Deadline> overviewDeadlinesOnly(List<Deadline> deadlines) {
      if (!isOverviewSource) return deadlines;
      return deadlines
          .where(
            (deadline) =>
                !deadline.isCompleted &&
                !deadline.deadlineDate.isBefore(startOfToday),
          )
          .toList();
    }

    if (segment == 'all') {
      final tasks = tasksAsync.valueOrNull;
      final deadlines = deadlinesAsync.valueOrNull;

      if (tasksAsync.isLoading || deadlinesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (tasksAsync.hasError || deadlinesAsync.hasError) {
        return Center(
          child: Text(
            l10n.networkError,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      final filteredTasks = _filterTasksByCourse(
        overviewTasksOnly(tasks ?? const []),
        selectedCourse,
      );
      final filteredDeadlines = _filterDeadlinesByCourse(
        overviewDeadlinesOnly(deadlines ?? const []),
        selectedCourse,
      );

      if (filteredTasks.isEmpty && filteredDeadlines.isEmpty) {
        return _FilteredTasksEmptyState(message: l10n.noPendingAlerts);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredTasks.isNotEmpty) ...[
            Text(
              l10n.tasks,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filteredTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TaskCard(task: task),
              ),
            ),
          ],
          if (filteredDeadlines.isNotEmpty) ...[
            if (filteredTasks.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.deadlines,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filteredDeadlines.map(
              (deadline) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DeadlineCard(deadline: deadline),
              ),
            ),
          ],
        ],
      );
    }

    if (segment == 'tasks') {
      return tasksAsync.when(
        data: (tasks) {
          final currentSemesterTasks = overviewTasksOnly(tasks);
          if (currentSemesterTasks.isEmpty) {
            return _TasksEmptyState(
              onCreate: () {
                Haptics.vibrate(HapticsType.medium);
                context.push('/create-task');
              },
            );
          }
          final filteredTasks = _filterTasksByCourse(
            currentSemesterTasks,
            selectedCourse,
          );
          if (filteredTasks.isEmpty) {
            return _FilteredTasksEmptyState(
              message: AppLocalizations.of(context)!.noTasksForThisCourse,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filteredTasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TaskCard(task: task),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            l10n.couldNotLoadTasks,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    } else {
      return deadlinesAsync.when(
        data: (deadlines) {
          final currentSemesterDeadlines = overviewDeadlinesOnly(deadlines);
          if (currentSemesterDeadlines.isEmpty) {
            return _DeadlinesEmptyState(
              onCreate: () {
                Haptics.vibrate(HapticsType.medium);
                context.push('/create-deadline');
              },
            );
          }
          final filteredDeadlines = _filterDeadlinesByCourse(
            currentSemesterDeadlines,
            selectedCourse,
          );
          if (filteredDeadlines.isEmpty) {
            return _FilteredTasksEmptyState(
              message: AppLocalizations.of(context)!.noDeadlinesForThisCourse,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filteredDeadlines.map((deadline) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DeadlineCard(deadline: deadline),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            l10n.couldNotLoadDeadlines,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
  }

  bool _shouldShowCourseFilter(List<String> courseOptions) {
    return courseOptions.length > 1;
  }

  List<String> _buildCourseOptions(
    List<Task> tasks,
    List<Deadline> deadlines,
  ) {
    return [
      ...tasks.map(_taskCourseLabel),
      ...deadlines.map(_deadlineCourseLabel),
    ]
        .where((course) => course.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Task> _filterTasksByCourse(List<Task> tasks, String selectedCourse) {
    if (selectedCourse == 'All') return tasks;
    return tasks.where((task) => _taskCourseLabel(task) == selectedCourse).toList();
  }

  List<Deadline> _filterDeadlinesByCourse(
    List<Deadline> deadlines,
    String selectedCourse,
  ) {
    if (selectedCourse == 'All') return deadlines;
    return deadlines
        .where((deadline) => _deadlineCourseLabel(deadline) == selectedCourse)
        .toList();
  }

  String _effectiveCourse(List<String> options, String selectedCourse) {
    if (selectedCourse == 'All') return 'All';
    return options.contains(selectedCourse) ? selectedCourse : 'All';
  }

  String _taskCourseLabel(Task task) {
    final courseName = task.course;
    if (courseName == null) return '';
    return _normalizeCourseName(courseName);
  }

  String _deadlineCourseLabel(Deadline deadline) {
    return _normalizeCourseName(deadline.course);
  }

  String _normalizeCourseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    return trimmed
        .split(RegExp(r'\\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

}

class _CreateOptionCard extends StatelessWidget {
  const _CreateOptionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String title;
  final HeroIcons icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AppIcon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksEmptyState extends StatelessWidget {
  const _TasksEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child:
          AppGlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      HeroIcons.checkCircle,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppLocalizations.of(context)!.stayOrganized,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppLocalizations.of(context)!.createFirstTask,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 200,
                      child: AppButton(
                        onPressed: onCreate,
                        text: AppLocalizations.of(context)!.createTask,
                        variant: AppButtonVariant.primary,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: AppDurations.slow)
              .scale(begin: const Offset(0.98, 0.98)),
    );
  }
}

class _FilteredTasksEmptyState extends StatelessWidget {
  const _FilteredTasksEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HeroIcons.folderOpen,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.currentSegment,
    required this.onSegmentChanged,
    this.includeAll = false,
  });

  final String currentSegment;
  final ValueChanged<String> onSegmentChanged;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    Widget segChip(String value, String label) {
      final selected = currentSegment == value;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          elevation: 0,
          onSelected: (_) {
            Haptics.vibrate(HapticsType.selection);
            onSegmentChanged(value);
          },
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
          selectedColor: theme.colorScheme.secondary,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.secondary
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          segChip('tasks', l10n.tasks),
          segChip('deadlines', l10n.deadlines),
          if (includeAll) segChip('all', l10n.all),
        ],
      ),
    );
  }
}

class _CourseFilterPicker extends StatelessWidget {
  const _CourseFilterPicker({
    required this.courses,
    required this.selectedCourse,
    required this.onChanged,
  });

  final List<String> courses;
  final String selectedCourse;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final options = <AppPickerOption<String>>[
      AppPickerOption<String>(value: l10n.all, title: l10n.all),
      ...courses.map(
        (course) => AppPickerOption<String>(value: course, title: course),
      ),
    ];

    return AppBottomSheetPicker<String>(
      icon: HeroIcons.bookOpen,
      fieldLabel: l10n.course,
      sheetTitle: l10n.course,
      selectedValue: selectedCourse,
      selectedDisplayText: selectedCourse,
      options: options,
      onChanged: onChanged,
      fieldLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      selectedTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatusFilterTabs extends StatelessWidget {
  const _StatusFilterTabs({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildChip(String value, String label) {
      final selected = currentFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          elevation: 0,
          onSelected: (_) {
            Haptics.vibrate(HapticsType.selection);
            onFilterChanged(value);
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
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
              width: 1,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip('all', AppLocalizations.of(context)!.all),
          buildChip('pending', AppLocalizations.of(context)!.pending),
          buildChip('completed', AppLocalizations.of(context)!.completed),
          buildChip('overdue', AppLocalizations.of(context)!.overdue),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});

  final Task task;

  Color _priorityColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (task.priority?.toLowerCase()) {
      case 'high':
        return theme.colorScheme.error;
      case 'medium':
        return theme.colorScheme.secondary;
      case 'low':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _formatDeadline(BuildContext context) {
    if (task.deadline == null) return AppLocalizations.of(context)!.noDeadline;
    final d = task.deadline!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final isCompleted = task.status == 'completed';
    
    bool isOverdue = false;
    if (!isCompleted && task.deadline != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDate = DateTime(
        task.deadline!.year,
        task.deadline!.month,
        task.deadline!.day,
      );
      isOverdue = taskDate.isBefore(today);
    }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                HeroIcons.checkCircle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                AppLocalizations.of(context)!.complete,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.editTask,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppIcon(
                HeroIcons.pencilSquare,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          Haptics.vibrate(HapticsType.selection);
          await showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const AppIcon(HeroIcons.pencilSquare),
                    title: Text(AppLocalizations.of(context)!.editTask),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/edit-task?id=${task.id}');
                    },
                  ),
                  ListTile(
                    leading: AppIcon(
                      HeroIcons.trash,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.deleteTask,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      try {
                        await ref
                            .read(tasksProvider.notifier)
                            .deleteTask(task.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.networkError,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          return false;
        }
        if (direction == DismissDirection.startToEnd) {
          Haptics.vibrate(HapticsType.selection);
          if (!isCompleted) {
            try {
              await ref
                  .read(tasksProvider.notifier)
                  .updateTaskStatus(task.id, 'completed');
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.networkError,
                    ),
                  ),
                );
              }
            }
          }
          return false;
        }
        return false;
      },
      child: InkWell(
        onTap: () {
          Haptics.vibrate(HapticsType.selection);
          context.push('/task-detail?id=${task.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1,
          child: Container(
            decoration: isOverdue ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                width: 1,
              ),
            ) : null,
            child: AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _priorityColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (task.course != null && task.course!.isNotEmpty)
                        Text(
                          '${AppLocalizations.of(context)!.course}: ${task.course}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (task.deadlineId != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            AppIcon(
                              HeroIcons.clipboardDocumentList,
                              size: 12,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.taskLinkedToDeadline,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          AppIcon(
                            HeroIcons.calendarDays,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.due(_formatDeadline(context)),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.estStudy(task.estimatedTime ?? 0),
                            style: theme.textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.complete,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Checkbox(
                                value: isCompleted,
                                onChanged: (value) {
                                  Haptics.vibrate(HapticsType.selection);
                                  final newStatus = value == true
                                      ? 'completed'
                                      : 'pending';
                                  ref
                                      .read(tasksProvider.notifier)
                                      .updateTaskStatus(task.id, newStatus);
                                },
                                activeColor: theme.colorScheme.primary,
                                side: BorderSide(
                                  color: theme.colorScheme.outline,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                                  .animate(key: ValueKey(isCompleted))
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.0, 1.0),
                                    duration: AppDurations.fast,
                                    curve: Curves.easeOutBack,
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ).animate().fade(duration: AppDurations.fast).slideY(begin: 0.05),
      ),
    );
  }
}

class _DeadlinesEmptyState extends StatelessWidget {
  const _DeadlinesEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child:
          AppGlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      HeroIcons.calendarDays,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppLocalizations.of(context)!.noDeadlinesYet,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppLocalizations.of(context)!.createFirstDeadline,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 220,
                      child: AppButton(
                        onPressed: onCreate,
                        text: AppLocalizations.of(context)!.createDeadline,
                        variant: AppButtonVariant.primary,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: AppDurations.slow)
              .scale(begin: const Offset(0.98, 0.98)),
    );
  }
}

class _DeadlineCard extends ConsumerWidget {
  const _DeadlineCard({required this.deadline});

  final Deadline deadline;

  bool _isOverdue() {
    if (deadline.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(
      deadline.deadlineDate.year,
      deadline.deadlineDate.month,
      deadline.deadlineDate.day,
    );
    return d.isBefore(today);
  }

  String _daysRemainingLabel(BuildContext context) {
    if (deadline.isCompleted) return AppLocalizations.of(context)!.completed;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(
      deadline.deadlineDate.year,
      deadline.deadlineDate.month,
      deadline.deadlineDate.day,
    );
    final diff = d.difference(today).inDays;
    if (diff < 0) return AppLocalizations.of(context)!.overdue;
    if (diff == 0) return AppLocalizations.of(context)!.dueToday;
    if (diff == 1) return AppLocalizations.of(context)!.daysRemaining(1);
    return AppLocalizations.of(context)!.daysRemaining(diff);
  }

  String _formatDate() {
    final d = deadline.deadlineDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _typeLabel(BuildContext context) {
    switch (deadline.deadlineType) {
      case 'exam':
        return AppLocalizations.of(context)!.exam;
      case 'quiz':
        return AppLocalizations.of(context)!.quiz;
      case 'project':
        return AppLocalizations.of(context)!.project;
      case 'assignment':
      default:
        return AppLocalizations.of(context)!.assignment;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = deadline.isCompleted;
    final isOverdue = _isOverdue();
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final progress = deadlineTaskProgress(tasks, deadline.id);

    return Dismissible(
      key: ValueKey(deadline.id),
      direction: DismissDirection.horizontal,
      background: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                HeroIcons.checkCircle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.complete,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.editDeadline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppIcon(
                HeroIcons.pencilSquare,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Haptics.vibrate(HapticsType.selection);
          if (!isCompleted) {
            try {
              await ref
                  .read(deadlinesProvider.notifier)
                  .markDeadlineCompleted(deadline.id);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.networkError,
                    ),
                  ),
                );
              }
            }
          }
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          Haptics.vibrate(HapticsType.selection);
          await showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const AppIcon(HeroIcons.pencilSquare),
                    title: Text(l10n.editDeadline),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/edit-deadline?id=${deadline.id}');
                    },
                  ),
                  ListTile(
                    leading: AppIcon(
                      HeroIcons.trash,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      l10n.deleteDeadline,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      try {
                        await ref
                            .read(deadlinesProvider.notifier)
                            .deleteDeadline(deadline.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.networkError,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          return false;
        }
        return false;
      },
      child: InkWell(
        onTap: () {
          Haptics.vibrate(HapticsType.selection);
          context.push('/deadline-detail?id=${deadline.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1,
          child: Container(
            decoration: isOverdue ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                width: 1,
              ),
            ) : null,
            child: AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadline.title,
                        softWrap: true,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.deadlineKindBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n.course}: ${deadline.course}',
                        softWrap: true,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.due(_formatDate()),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _daysRemainingLabel(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : (isOverdue ? theme.colorScheme.error : null),
                        ),
                      ),
                      if (progress.totalCount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.deadlineLinkedTasksProgress(
                            progress.completedCount,
                            progress.totalCount,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _typeLabel(context),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.complete, style: theme.textTheme.bodySmall),
                        const SizedBox(width: AppSpacing.xs),
                        Checkbox(
                          value: isCompleted,
                          onChanged: (_) async {
                            Haptics.vibrate(HapticsType.selection);
                            try {
                              await ref
                                  .read(deadlinesProvider.notifier)
                                  .toggleDeadlineCompletion(deadline.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .networkError,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        )
                            .animate(key: ValueKey(isCompleted))
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: AppDurations.fast,
                              curve: Curves.easeOutBack,
                            ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    ).animate().fade(duration: AppDurations.fast).slideY(begin: 0.05);
  }
}
