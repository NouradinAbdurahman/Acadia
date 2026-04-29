import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../components/app_back_button.dart';

import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/mood_log.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/mood/mood_details_bottom_sheet.dart';

import '../../widgets/mood/mood_daily_list.dart';

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  String _selectedSource = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final moodLogsAsync = ref.watch(moodLogsProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const AppBackButton(alignToContentEdge: true),
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
                      onPressed: () {
                        Haptics.vibrate(HapticsType.medium);
                        context.push('/mood/log');
                      },
                      child: Text(l10n.logMoodTitle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "FILTER BY SOURCE",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSourceTabs(l10n, theme),
              Expanded(
                child: moodLogsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text(l10n.networkError)),
                  data: (allLogs) {
                    final logs = allLogs.where((log) {
                      if (_selectedSource == 'all') return true;
                      return log.source == _selectedSource;
                    }).toList();

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
                        section = l10n.today;
                      } else if (delta == 1) {
                        section = l10n.yesterday;
                      } else if (delta <= 7) {
                        section = l10n.thisWeekLabel;
                      } else {
                        section = l10n.olderLabel;
                      }
                      
                      grouped.putIfAbsent(section, () => []).add(log);
                    }

                    final sections = [l10n.today, l10n.yesterday, l10n.thisWeekLabel, l10n.olderLabel]
                        .where((section) => grouped.containsKey(section))
                        .toList();

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
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
                                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
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
  
  Widget _buildSourceTabs(AppLocalizations l10n, ThemeData theme) {
    return RepaintBoundary(
      child: Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              label: l10n.all,
              isSelected: _selectedSource == 'all',
              color: theme.colorScheme.primary,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                setState(() => _selectedSource = 'all');
              },
            ),
          ),
          Expanded(
            child: _buildTabItem(
              label: l10n.dailyBaseline,
              isSelected: _selectedSource == 'manual',
              color: AppColors.moodSourceDailyAccent,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                setState(() => _selectedSource = 'manual');
              },
            ),
          ),
          Expanded(
            child: _buildTabItem(
              label: l10n.studySessions,
              isSelected: _selectedSource == 'session',
              color: AppColors.moodSourceSessionAccent,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                setState(() => _selectedSource = 'session');
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.cardColor : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
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
    final moodLabel = _moodLevelLabel(log.moodLevel, l10n);

    return GestureDetector(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
        MoodDetailsBottomSheet.show(context, log);
      },
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodEmojiCircle(moodLevel: log.moodLevel, size: 54),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      moodLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.stressLevel} ${log.stressLevel}/10',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (log.note != null && log.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      log.note!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  whenLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  String _moodLevelLabel(int level, AppLocalizations l10n) {
    switch (level) {
      case 1:
        return l10n.moodNameAwful;
      case 2:
        return l10n.moodNameBad;
      case 3:
        return l10n.moodNameNeutral;
      case 4:
        return l10n.moodNameGood;
      case 5:
        return l10n.moodNameGreat;
      default:
        return 'Unknown';
    }
  }
}
