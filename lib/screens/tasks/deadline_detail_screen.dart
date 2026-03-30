import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../providers/deadlines_provider.dart';
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
                        if (deadline.notes != null && deadline.notes!.isNotEmpty) ...[
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
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
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
                          countdown(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
                            await ref
                                .read(deadlinesProvider.notifier)
                                .deleteDeadline(deadline.id);
                            if (context.mounted) {
                              context.pop();
                            }
                          },
                          text: l10n.deleteDeadline,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: AppDurations.slow).slideY(begin: 0.1),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
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
