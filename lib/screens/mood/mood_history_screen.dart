import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';

import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/mood_log.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class MoodHistoryScreen extends ConsumerWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final moodLogsAsync = ref.watch(moodLogsProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const AppIcon(HeroIcons.arrowLeft),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.moodHistoryTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/mood/log'),
                      child: Text(l10n.logMoodTitle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: moodLogsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text(l10n.networkError)),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.moodNoData,
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    // Group logs by date sections
                    final Map<String, List<MoodLog>> grouped = {};
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    
                    for (final log in logs) {
                      final logDate = DateTime(
                        log.createdAt.year,
                        log.createdAt.month,
                        log.createdAt.day,
                      );
                      final delta = today.difference(logDate).inDays;
                      
                      String section;
                      if (delta == 0) {
                        section = 'Today';
                      } else if (delta == 1) {
                        section = 'Yesterday';
                      } else if (delta <= 7) {
                        section = 'This Week';
                      } else {
                        section = 'Older';
                      }
                      
                      grouped.putIfAbsent(section, () => []).add(log);
                    }

                    final sections = ['Today', 'Yesterday', 'This Week', 'Older']
                        .where((section) => grouped.containsKey(section))
                        .toList();

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: sections.fold<int>(
                        0,
                        (sum, section) => sum + grouped[section]!.length + 1,
                      ),
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        // Calculate which section and item within section
                        int currentIndex = 0;
                        for (final section in sections) {
                          final sectionItems = grouped[section]!;
                          if (index == currentIndex) {
                            // This is the section header
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                section,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }
                          currentIndex++;
                          
                          if (index < currentIndex + sectionItems.length) {
                            final itemIndex = index - currentIndex;
                            return _MoodHistoryItem(log: sectionItems[itemIndex]);
                          }
                          currentIndex += sectionItems.length;
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodHistoryItem extends StatelessWidget {
  const _MoodHistoryItem({required this.log});

  final MoodLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final whenLabel = _dayLabel(context, log.createdAt);
    final time = DateFormat.Hm().format(log.createdAt);
    final moodEmoji = _emojiForMood(log.moodLevel);
    final moodLabel = _moodLevelLabel(log.moodLevel);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji and mood label
          Row(
            children: [
              Text(
                moodEmoji,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                moodLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          
          // Stress level
          Text(
            '${l10n.stressLevel} ${log.stressLevel}/10',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          // Note if present
          if (log.note != null && log.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${log.note!}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          
          // When (Today/Yesterday/date at bottom) 
          const SizedBox(height: AppSpacing.xs),
          Text(
            whenLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime value) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final delta = today.difference(date).inDays;

    if (delta == 0) return l10n.today;
    if (delta == 1) return l10n.yesterday;
    return DateFormat.yMMMd().format(value);
  }

  String _emojiForMood(int level) {
    switch (level) {
      case 1:
        return '😞';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      default:
        return '😄';
    }
  }

  String _moodLevelLabel(int level) {
    switch (level) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Amazing';
      default:
        return 'Unknown';
    }
  }
}
