import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../providers/deadlines_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../domain/academic_deadline_task.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';

class DeadlineDetailScreen extends ConsumerWidget {
  const DeadlineDetailScreen({super.key, required this.deadlineId});

  final String deadlineId;

  dynamic _findDeadline(List<dynamic> deadlines) {
    try {
      return deadlines.firstWhere((d) => d.id == deadlineId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlinesAsync = ref.watch(deadlinesProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deadlineDetail),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: deadlinesAsync.when(
              data: (deadlines) {
                final deadline = _findDeadline(deadlines);
                if (deadline == null) {
                  return Center(
                    child: Text(
                      l10n.deadlineNotFound,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                String formatDate() {
                  final d = deadline.deadlineDate;
                  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                }

                String countdown() {
                  if (deadline.isCompleted) return l10n.completed;
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final d = DateTime(
                    deadline.deadlineDate.year,
                    deadline.deadlineDate.month,
                    deadline.deadlineDate.day,
                  );
                  final diff = d.difference(today).inDays;
                  if (diff < 0) return l10n.overdueByDays(diff.abs());
                  if (diff == 0) return l10n.dueToday;
                  return l10n.dueInDays(diff);
                }

                String typeLabel() {
                  switch (deadline.deadlineType) {
                    case 'exam':
                      return l10n.exam;
                    case 'quiz':
                      return l10n.quiz;
                    case 'project':
                      return l10n.project;
                    case 'assignment':
                    default:
                      return l10n.assignment;
                  }
                }

                final status = deadlineStatus(deadline, DateTime.now());
                final statusLabel = switch (status) {
                  AcademicDeadlineStatus.completed => l10n.completed,
                  AcademicDeadlineStatus.overdue => l10n.overdue,
                  AcademicDeadlineStatus.pending => l10n.pending,
                };

                return SingleChildScrollView(
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          deadline.title,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _DeadlineKindChip(
                              label: l10n.deadlineKindBadge,
                              color: theme.colorScheme.primary,
                            ),
                            _DeadlineKindChip(
                              label: statusLabel,
                              color: switch (status) {
                                AcademicDeadlineStatus.overdue =>
                                  theme.colorScheme.error,
                                AcademicDeadlineStatus.completed =>
                                  theme.colorScheme.primary,
                                AcademicDeadlineStatus.pending =>
                                  theme.colorScheme.onSurface,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${l10n.course}: ${deadline.course}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            AppIcon(
                              HeroIcons.calendarDays,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.deadlineDate}: ${formatDate()}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            AppIcon(
                              HeroIcons.tag,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.type}: ${typeLabel()}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            AppIcon(
                              HeroIcons.flag,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.priority}: ${deadline.priority}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (deadline.notes != null &&
                            deadline.notes!.isNotEmpty) ...[
                          Row(
                            children: [
                              AppIcon(
                                HeroIcons.clipboardDocumentList,
                                size: 18,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.notes}:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              deadline.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text(
                          l10n.relatedTasksSection,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        tasksAsync.when(
                          data: (tasks) {
                            final progress = deadlineTaskProgress(
                              tasks,
                              deadline.id,
                            );
                            final linked = tasksForDeadline(tasks, deadline.id);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (progress.totalCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      l10n.deadlineLinkedTasksProgress(
                                        progress.completedCount,
                                        progress.totalCount,
                                      ),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                if (linked.isEmpty)
                                  Text(
                                    l10n.deadlineNoLinkedTasks,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  )
                                else
                                  ...linked.map(
                                    (Task t) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(t.title),
                                      subtitle: Text(
                                        t.status == 'completed'
                                            ? l10n.completed
                                            : l10n.pending,
                                      ),
                                      trailing: const AppIcon(
                                        HeroIcons.chevronRight,
                                        size: 18,
                                      ),
                                      onTap: () {
                                        Haptics.vibrate(HapticsType.selection);
                                        context.push('/task-detail?id=${t.id}');
                                      },
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  onPressed: () {
                                    Haptics.vibrate(HapticsType.selection);
                                    final deadlineParam = Uri.encodeComponent(
                                      deadline.id,
                                    );
                                    final courseParam = deadline.courseId;
                                    final query = courseParam == null
                                        ? 'deadlineId=$deadlineParam'
                                        : 'deadlineId=$deadlineParam&courseId=${Uri.encodeComponent(courseParam)}';
                                    context.push(
                                      '/create-task?$query',
                                    );
                                  },
                                  text: l10n.addTaskToThisDeadline,
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(
                            height: 24,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, _) => Text(
                            l10n.couldNotLoadTasks,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          countdown(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: deadline.isCompleted
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          onPressed: () async {
                            Haptics.vibrate(HapticsType.medium);
                            try {
                              await ref
                                  .read(deadlinesProvider.notifier)
                                  .toggleDeadlineCompletion(deadline.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.networkError),
                                  ),
                                );
                              }
                            }
                          },
                          text: deadline.isCompleted
                              ? l10n.markAsPending
                              : l10n.markAsComplete,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          onPressed: () {
                            Haptics.vibrate(HapticsType.selection);
                            context.push('/edit-deadline?id=${deadline.id}');
                          },
                          text: l10n.editDeadline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          onPressed: () async {
                            Haptics.vibrate(HapticsType.error);
                            try {
                              await ref
                                  .read(deadlinesProvider.notifier)
                                  .deleteDeadline(deadline.id);
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.networkError),
                                  ),
                                );
                              }
                            }
                          },
                          text: l10n.deleteDeadline,
                        ),
                      ],
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
}

class _DeadlineKindChip extends StatelessWidget {
  const _DeadlineKindChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
