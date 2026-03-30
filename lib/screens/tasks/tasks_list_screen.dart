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
import '../../providers/deadlines_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final deadlinesAsync = ref.watch(deadlinesProvider);
    final filter = ref.watch(taskFilterProvider);
    final theme = Theme.of(context);

    // Sync filter from query parameter if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryFilter = GoRouterState.of(context).uri.queryParameters['filter'];
      if (queryFilter != null && queryFilter != filter) {
        ref.read(taskFilterProvider.notifier).state = queryFilter;
      }
    });

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.tasks,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
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
                _TaskFilterTabs(
                  currentFilter: filter,
                  onFilterChanged: (value) =>
                      ref.read(taskFilterProvider.notifier).state = value,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: filter == 'all'
                      ? tasksAsync.when(
                          data: (tasks) => deadlinesAsync.when(
                            data: (deadlines) {
                              final sortedDeadlines = [...deadlines]
                                ..sort((a, b) =>
                                    a.deadlineDate.compareTo(b.deadlineDate));

                              if (tasks.isEmpty && deadlines.isEmpty) {
                                return _TasksEmptyState(
                                  onCreate: () {
                                    Haptics.vibrate(HapticsType.medium);
                                    context.push('/create-task');
                                  },
                                );
                              }

                              return ListView(
                                padding: const EdgeInsets.only(bottom: 120),
                                children: [
                                  if (sortedDeadlines.isNotEmpty) ...[
                                    Text(
                                      AppLocalizations.of(context)!.deadlines,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    for (final d in sortedDeadlines) ...[
                                      _DeadlineCard(deadline: d),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                  ],
                                  if (tasks.isNotEmpty) ...[
                                    if (sortedDeadlines.isNotEmpty)
                                      const SizedBox(height: AppSpacing.md),
                                    Text(
                                      AppLocalizations.of(context)!.tasks,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    for (final task in tasks) ...[
                                      _TaskCard(task: task),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                  ],
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Text(
                                AppLocalizations.of(context)!.couldNotLoadDeadlines,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(
                            child: Text(
                              AppLocalizations.of(context)!.couldNotLoadTasks,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        )
                      : filter == 'deadlines'
                          ? deadlinesAsync.when(
                              data: (items) {
                                final sortedItems = [...items]
                                  ..sort((a, b) =>
                                      a.deadlineDate.compareTo(b.deadlineDate));

                                if (items.isEmpty) {
                                  return _DeadlinesEmptyState(
                                    onCreate: () {
                                      Haptics.vibrate(HapticsType.medium);
                                      context.push('/create-deadline');
                                    },
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: sortedItems.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final d = sortedItems[index];
                                    return _DeadlineCard(deadline: d);
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(
                                child: Text(
                                  AppLocalizations.of(context)!.couldNotLoadDeadlines,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : tasksAsync.when(
                              data: (tasks) {
                                if (tasks.isEmpty) {
                                  return _TasksEmptyState(
                                    onCreate: () {
                                      Haptics.vibrate(HapticsType.medium);
                                      context.push('/create-task');
                                    },
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: tasks.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final task = tasks[index];
                                    return _TaskCard(task: task);
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(
                                child: Text(
                                  AppLocalizations.of(context)!.couldNotLoadTasks,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
      child: AppGlassCard(
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
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
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
      ).animate().fade(duration: AppDurations.slow).scale(begin: const Offset(0.98, 0.98)),
    );
  }
}

class _TaskFilterTabs extends StatelessWidget {
  const _TaskFilterTabs({
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
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onFilterChanged(value),
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
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
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
          buildChip('deadlines', AppLocalizations.of(context)!.deadlines),
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

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 160,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppIcon(
                  HeroIcons.checkCircle,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  AppLocalizations.of(context)!.complete,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      secondaryBackground: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 160,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppIcon(
                  HeroIcons.trash,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  AppLocalizations.of(context)!.delete,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          Haptics.vibrate(HapticsType.medium);
          await ref.read(tasksProvider.notifier).deleteTask(task.id);
          return true;
        }
        if (direction == DismissDirection.startToEnd) {
          Haptics.vibrate(HapticsType.selection);
          if (!isCompleted) {
            await ref
                .read(tasksProvider.notifier)
                .updateTaskStatus(task.id, 'completed');
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
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (task.course != null && task.course!.isNotEmpty)
                      Text(
                        '${AppLocalizations.of(context)!.course}: ${task.course}',
                        style: theme.textTheme.bodySmall,
                      ),
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
                          AppLocalizations.of(context)!.due(_formatDeadline(context)),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.estStudy(task.estimatedTime ?? 0),
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
      child: AppGlassCard(
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
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
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
      ).animate().fade(duration: AppDurations.slow).scale(
            begin: const Offset(0.98, 0.98),
          ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.deadline});

  final Deadline deadline;

  String _daysRemainingLabel(BuildContext context) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
        context.push('/deadline-detail?id=${deadline.id}');
      },
      borderRadius: BorderRadius.circular(16),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${AppLocalizations.of(context)!.course}: ${deadline.course}',
                    softWrap: true,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppLocalizations.of(context)!.due(_formatDate()),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _daysRemainingLabel(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              _typeLabel(context),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: AppDurations.fast).slideY(begin: 0.05);
  }
}


