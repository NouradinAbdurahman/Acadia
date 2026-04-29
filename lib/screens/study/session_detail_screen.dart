import 'package:flutter/material.dart';
import '../../models/study_session.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../providers/analytics_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionDetailScreen extends ConsumerWidget {
  final StudySession session;

  const SessionDetailScreen({super.key, required this.session});



  String _formatSessionType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'pomodoro':
        return l10n.pomodoro;
      case 'deep_work':
        return l10n.deepWork;
      case 'review':
        return l10n.review;
      default:
        return type;
    }
  }

  String _getMoodEmoji(double mood) {
    if (mood >= 4.5) return '😄';
    if (mood >= 3.5) return '🙂';
    if (mood >= 2.5) return '😐';
    if (mood >= 1.5) return '🙁';
    return '😞';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final mutedTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.58);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final analytics = ref.watch(studyAnalyticsProvider);

    final focusLabel = analytics.getFocusLabel(session.durationMinutes, l10n);
    final insight = analytics.getInsight(session, l10n);
    final impact = analytics.calculateImpact(session);
    
    final dateFormat = DateFormat('MMM d, y • HH:mm', localeTag);
    final timeFormatted = dateFormat.format(session.createdAt);
    final sessionTypeStr = _formatSessionType(l10n, session.sessionType);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.statusCompleted),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.iconTheme.copyWith(color: theme.colorScheme.onSurface),
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// HEADER
                Text(
                  session.course?.courseName ?? l10n.course,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  session.isPomodoro
                      ? l10n.pomodoroSubtitle(session.cyclesCompleted ?? 0, session.totalCycles ?? 4)
                      : "$sessionTypeStr • ${session.durationMinutes}m",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormatted,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: mutedTextColor,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                /// FOCUS INSIGHT
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focusLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        insight,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                /// MOOD & STRESS
                if (session.mood != null || session.stress != null) ...[
                  AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mood & Stress",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (session.mood != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getMoodEmoji(session.mood!),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      "Mood",
                                      style: TextStyle(color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                                Text(
                                  session.mood!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (session.stress != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text("⚡", style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text("Stress Level", style: TextStyle(color: secondaryTextColor)),
                                ],
                              ),
                              Text(
                                "${session.stress!.toStringAsFixed(1)} / 10",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                /// SCORE IMPACT
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.focusScoreImpact,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: impact > 0 
                              ? Colors.green.withValues(alpha: 0.2) 
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.focusPoints("${impact >= 0 ? '+' : ''}$impact"),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: impact >= 0
                                ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                                : (isDark ? Colors.redAccent : Colors.red.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                /// SESSION DATA
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                if (session.isPomodoro) ...[ 
                  // ── Section 1: Overview ──
                  Text(
                    l10n.overview,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow(
                    theme, l10n.cycles,
                    "${session.cyclesCompleted ?? 0} / ${session.totalCycles ?? 4}",
                    primaryTextColor,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((session.cyclesCompleted ?? 0) / (session.totalCycles ?? 4)).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        session.completed
                            ? (isDark ? Colors.greenAccent : Colors.green.shade600)
                            : (isDark ? Colors.orangeAccent : Colors.orange.shade700),
                      ),
                    ),
                  ),
                  Divider(
                    height: 28,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  ),

                  // ── Section 2: Metrics ──
                  Text(
                    l10n.pomodoroMetrics,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow(
                    theme,
                    l10n.focusTimeLabel,
                    "${session.totalFocusMinutes ?? session.durationMinutes} min",
                    primaryTextColor,
                  ),
                  Divider(
                    height: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                  _buildDataRow(
                    theme,
                    l10n.breakTimeLabel,
                    "${session.totalBreakMinutes ?? 0} min",
                    secondaryTextColor,
                  ),
                  Divider(
                    height: 28,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  ),

                  // ── Section 3: Performance ──
                  Text(
                    l10n.pomodoroPerformance,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow(
                    theme, l10n.statusCompleted,
                    l10n.completionOfCycles((((session.cyclesCompleted ?? 0) / (session.totalCycles ?? 4)) * 100).round()),
                    session.completed
                        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                        : (isDark ? Colors.orangeAccent : Colors.orange.shade700),
                  ),
                  Divider(
                    height: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                  _buildDataRow(
                    theme, l10n.statusCompleted,
                    session.completed ? l10n.completedYes : l10n.completedNo,
                    session.completed
                        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                        : (isDark ? Colors.orangeAccent : Colors.orange.shade700),
                  ),
                  Divider(
                    height: 28,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  ),

                  // ── Cycle Timeline ──
                  Text(
                    l10n.pomodoroTimeline,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCycleTimeline(theme, l10n, session),
                ] else ...[
                  _buildDataRow(
                    theme,
                    l10n.statusCompleted,
                    session.completed ? l10n.completedYes : l10n.completedNo,
                    session.completed
                        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                        : (isDark ? Colors.redAccent : Colors.red.shade700),
                  ),
                  Divider(
                    height: 24,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  ),
                  _buildDataRow(
                    theme,
                    l10n.cycles,
                    "${session.completedCycles ?? '-'}",
                    primaryTextColor,
                  ),
                  Divider(
                    height: 24,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  ),
                  _buildDataRow(
                    theme,
                    l10n.breaksSkipped,
                    "${session.skippedBreaks ?? 0}",
                    primaryTextColor,
                  ),
                ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                /// INTENT
                if (session.intent != null && session.intent!.trim().isNotEmpty) ...[
                  AppGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.studyIntent,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          session.intent!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: primaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleTimeline(ThemeData theme, AppLocalizations l10n, StudySession session) {
    final isDark = theme.brightness == Brightness.dark;
    final subtleColor = theme.colorScheme.onSurface.withValues(alpha: 0.24);
    final mediumColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final completed = session.cyclesCompleted ?? 0;
    final total = session.totalCycles ?? 4;
    final rows = <Widget>[];

    for (int i = 1; i <= total; i++) {
      final isDone = i <= completed;
      // "in progress" = the cycle being worked when stopped (only for partial sessions)
      final isInProgress = !session.completed && i == completed + 1;

      // Focus row
      rows.add(Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? (isDark
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.10))
                  : isInProgress
                      ? (isDark
                          ? Colors.yellowAccent.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.10))
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(
                color: isDone
                    ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                    : isInProgress
                        ? (isDark ? Colors.yellowAccent : Colors.orange.shade700)
                        : subtleColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                isDone ? '✔' : isInProgress ? '⏳' : '○',
                style: TextStyle(
                  fontSize: 11,
                  color: isDone
                      ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                      : isInProgress
                          ? (isDark ? Colors.yellowAccent : Colors.orange.shade700)
                          : subtleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isDone
                ? l10n.focusCycleDone(i, 25)
                : isInProgress
                    ? l10n.focusCycleInProgress(i)
                    : l10n.focusCycleNotReached(i),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDone
                  ? mediumColor
                  : isInProgress
                      ? (isDark
                          ? Colors.yellowAccent.withValues(alpha: 0.85)
                          : Colors.orange.shade700)
                      : subtleColor,
            ),
          ),
        ],
      ));

      // Break separator (between cycles, not after last)
      if (i < total) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 13, top: 3, bottom: 3),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 23),
              Text(
                i <= completed ? l10n.breakDone(5) : l10n.breakPending,
                style: theme.textTheme.labelSmall?.copyWith(color: subtleColor),
              ),
            ],
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildDataRow(ThemeData theme, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
