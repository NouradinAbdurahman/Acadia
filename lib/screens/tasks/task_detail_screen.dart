import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_back_button.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/course_provider.dart';
import '../../components/app_toast.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  Task? _findTask(List<Task> tasks) {
    try {
      return tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final coursesAsync = ref.watch(courseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(AppLocalizations.of(context)!.taskDetail),
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
                final task = _findTask(tasks);
                if (task == null) {
                  return Center(
                    child: Text(
                        AppLocalizations.of(context)!.taskNotFound,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                String formatDeadline() {
                  if (task.deadline == null) return AppLocalizations.of(context)!.noDeadline;
                  final d = task.deadline!;
                  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                }

                String deadlineCountdown() {
                  if (task.deadline == null) return AppLocalizations.of(context)!.noDeadlineSet;
                  final now = DateTime.now();
                  final diff = task.deadline!.difference(now).inDays;
                  if (diff < 0) return AppLocalizations.of(context)!.overdueByDays(diff.abs());
                  if (diff == 0) return AppLocalizations.of(context)!.dueToday;
                  return AppLocalizations.of(context)!.dueInDays(diff);
                }

                return SingleChildScrollView(
                  child: AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        (() {
                          final courses = coursesAsync.value ?? [];
                          final courseObj = courses.where((c) => c.id == task.courseId).firstOrNull;
                          final displayCourse = task.course ?? courseObj?.courseName;
                          
                          if (displayCourse == null || displayCourse.isEmpty) return const SizedBox.shrink();
                          
                          return Text(
                            '${AppLocalizations.of(context)!.course}: $displayCourse',
                            style: theme.textTheme.bodyMedium,
                          );
                        })(),
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
                              '${AppLocalizations.of(context)!.deadlines}: ${formatDeadline()}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            AppIcon(
                              HeroIcons.clock,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AppLocalizations.of(context)!.estimated}: ${task.estimatedTime ?? 0}${AppLocalizations.of(context)!.hoursAbbreviation}',
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
                              '${AppLocalizations.of(context)!.priority}: ${task.priority ?? AppLocalizations.of(context)!.notSet}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (task.notes != null && task.notes!.isNotEmpty) ...[
                          Row(
                            children: [
                              AppIcon(
                                HeroIcons.clipboardDocumentList,
                                size: 18,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${AppLocalizations.of(context)!.notes}:',
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
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text(
                          deadlineCountdown(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          onPressed: () {
                            Haptics.vibrate(HapticsType.selection);
                            context.push('/edit-task?id=${task.id}');
                          },
                          text: AppLocalizations.of(context)!.editTask,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          onPressed: () async {
                            Haptics.vibrate(HapticsType.medium);
                            final newStatus = task.status == 'completed'
                                ? 'pending'
                                : 'completed';
                            try {
                              await ref
                                  .read(tasksProvider.notifier)
                                  .updateTaskStatus(task.id, newStatus);
                            } catch (_) {
                              if (context.mounted) {
                                AppToast.show(context, AppLocalizations.of(context)!.networkError, type: AppToastType.error);
                              }
                            }
                          },
                          text: task.status == 'completed'
                              ? AppLocalizations.of(context)!.markAsPending
                              : AppLocalizations.of(context)!.markAsComplete,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          onPressed: () async {
                            Haptics.vibrate(HapticsType.error);
                            try {
                              await ref
                                  .read(tasksProvider.notifier)
                                  .deleteTask(task.id);
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (_) {
                              if (context.mounted) {
                                AppToast.show(context, AppLocalizations.of(context)!.networkError, type: AppToastType.error);
                              }
                            }
                          },
                          text: AppLocalizations.of(context)!.deleteTask,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: AppDurations.slow).slideY(begin: 0.1),
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
        ),
      ),
    );
  }
}

