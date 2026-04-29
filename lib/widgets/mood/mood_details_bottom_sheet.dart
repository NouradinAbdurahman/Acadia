import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mood_log.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_gradients.dart';
import '../../l10n/app_localizations.dart';
import 'mood_daily_list.dart';

class MoodDetailsBottomSheet extends StatelessWidget {
  final MoodLog log;

  const MoodDetailsBottomSheet({super.key, required this.log});

  static void show(BuildContext context, MoodLog log) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
      barrierColor: theme.colorScheme.shadow.withValues(alpha: 0.45),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => MoodDetailsBottomSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final dateStr = DateFormat.yMMMMEEEEd(locale).format(log.createdAt);
    final timeStr = DateFormat.Hm(locale).format(log.createdAt);
    final moodLabel = _nameForMood(log.moodLevel, l10n);

    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkBackground
              : AppGradients.lightBackground,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header
              Row(
                children: [
                  MoodEmojiCircle(moodLevel: log.moodLevel, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moodLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "$dateStr • $timeStr",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
              Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      l10n.stressLevel,
                      "${log.stressLevel}/10",
                      Icons.psychology_outlined,
                      _getMoodColor(log.moodLevel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (log.energyLevel != null)
                    Expanded(
                      child: _statCard(
                        context,
                        l10n.moodEnergyLevel,
                        "${log.energyLevel}/10",
                        Icons.bolt_outlined,
                        Colors.orange,
                      ),
                    ),
                ],
              ),

              if (log.factors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.moodFactors,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: log.factors.map((factor) {
                    final factorInfo = _getFactorInfo(factor, l10n);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            factorInfo.$2,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            factorInfo.$1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (log.note != null && log.note!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.notes,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Text(
                    log.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Footer attribution
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    log.source == 'session'
                        ? Icons.timer_outlined
                        : Icons.edit_note_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    log.source == 'session'
                        ? l10n.moodLoggedSession
                        : l10n.moodLoggedManual,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _nameForMood(int level, AppLocalizations l10n) {
    switch (level) {
      case 1:
        return l10n.moodNameAwful;
      case 2:
        return l10n.moodNameBad;
      case 3:
        return l10n.moodNameNeutral;
      case 4:
        return l10n.moodNameGood;
      default:
        return l10n.moodNameGreat;
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFF7043);
      case 3:
        return const Color(0xFFFFC107);
      case 4:
        return const Color(0xFF66BB6A);
      case 5:
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFFFFC107);
    }
  }

  (String, IconData) _getFactorInfo(String key, AppLocalizations l10n) {
    switch (key) {
      case 'sleep':
        return (l10n.moodFactorSleep, Icons.bedtime);
      case 'workload':
        return (l10n.moodFactorWorkload, Icons.work_outline);
      case 'health':
        return (l10n.moodFactorHealth, Icons.favorite_border);
      case 'motivation':
        return (l10n.moodFactorMotivation, Icons.flash_on);
      case 'social':
        return (l10n.moodFactorSocial, Icons.people_outline);
      case 'exams':
        return (l10n.moodFactorExams, Icons.school);
      default:
        return (key, Icons.more_horiz);
    }
  }
}
