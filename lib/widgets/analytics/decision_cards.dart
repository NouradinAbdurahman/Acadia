import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/decision_snapshot.dart';

class TodayPlanCard extends StatelessWidget {
  final DecisionNextAction primary;
  final DecisionFocusRecommendation? secondary;

  const TodayPlanCard({
    super.key,
    required this.primary,
    this.secondary,
  });

  int _secondaryMinutes(int primaryMinutes) {
    final raw = primaryMinutes * 0.67;
    final roundedToFive = (raw / 5).round() * 5;
    return roundedToFive.clamp(25, 90);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final secondaryMinutes = _secondaryMinutes(primary.durationMinutes);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.calendarCheck(PhosphorIconsStyle.bold),
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.todayPlanTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlanRow(
            minutes: primary.durationMinutes,
            course: primary.courseName,
          ),
          if (secondary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _PlanRow(
              minutes: secondaryMinutes,
              course: secondary!.courseName,
            ),
          ],
        ],
      ),
    );
  }
}

class RecoveryPlanCard extends StatelessWidget {
  final int todayMinutes;
  final int tomorrowMinutes;
  final int day3Minutes;

  const RecoveryPlanCard({
    super.key,
    required this.todayMinutes,
    required this.tomorrowMinutes,
    required this.day3Minutes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.recoveryPlanTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.recoveryPlanSplitFromWeeklyDeficit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _RecoveryRow(label: l10n.today, minutes: todayMinutes),
          const SizedBox(height: AppSpacing.xs),
          _RecoveryRow(label: l10n.tomorrow, minutes: tomorrowMinutes),
          const SizedBox(height: AppSpacing.xs),
          _RecoveryRow(label: l10n.planDay3Label, minutes: day3Minutes),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final int minutes;
  final String course;

  const _PlanRow({required this.minutes, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        PhosphorIcon(
          PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
          size: 22,
          color: Colors.green,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.minutesCourseValue(minutes, course),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final String label;
  final int minutes;

  const _RecoveryRow({required this.label, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
        Text(
          l10n.minutesValue(minutes),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class DecisionNextActionCard extends StatelessWidget {
  final DecisionNextAction action;
  final VoidCallback? onStartSession;

  const DecisionNextActionCard({
    super.key,
    required this.action,
    this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final courseLine = action.courseId.isEmpty
        ? l10n.decisionStudyAnyCourse
        : l10n.decisionStudyCourse(action.courseName);

    return InkWell(
      onTap: onStartSession,
      borderRadius: BorderRadius.circular(24),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.bold),
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.decisionNextActionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _DecisionConfidenceBadge(confidence: action.confidence),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              courseLine,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.decisionMinutesToday(action.durationMinutes),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _localizeDecisionReason(context, action.reason),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: l10n.startSession,
              onPressed: onStartSession,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class DecisionFocusRecommendationCard extends StatelessWidget {
  final DecisionFocusRecommendation recommendation;

  const DecisionFocusRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.graduationCap(PhosphorIconsStyle.bold),
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.decisionFocusRecommendationTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            recommendation.courseName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _localizeDecisionReason(context, recommendation.reason),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class DecisionWhatChangedCard extends StatelessWidget {
  final DecisionWhatChanged whatChanged;

  const DecisionWhatChangedCard({super.key, required this.whatChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.decisionWhatChangedTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChangeRow(label: l10n.study, value: whatChanged.study),
          const SizedBox(height: AppSpacing.xs),
          _ChangeRow(label: l10n.decisionTaskLoadLabel, value: whatChanged.taskLoad),
          const SizedBox(height: AppSpacing.xs),
          _ChangeRow(label: l10n.performanceTrend, value: whatChanged.performance),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final String label;
  final String value;

  const _ChangeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = switch (value) {
      'Increased' || 'Improving' => Colors.green,
      'Decreased' || 'Declining' => Colors.orange,
      _ => theme.colorScheme.onSurface,
    };
    final localizedValue = switch (value) {
      'Increased' => l10n.trendIncreased,
      'Decreased' => l10n.decreased,
      'Improving' => l10n.trendImproving,
      'Declining' => l10n.trendDeclining,
      _ => l10n.trendStable,
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Text(
          localizedValue,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DecisionConfidenceBadge extends StatelessWidget {
  final DecisionConfidence confidence;

  const _DecisionConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (label, color) = switch (confidence) {
      DecisionConfidence.high => (l10n.confidenceHigh, Colors.green),
      DecisionConfidence.medium => (l10n.confidenceMedium, theme.colorScheme.primary),
      DecisionConfidence.low => (l10n.decisionConfidenceLow, Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

String _localizeDecisionReason(BuildContext context, String reason) {
  final l10n = AppLocalizations.of(context)!;
  final lines = reason
      .split('\n')
      .map((line) => _localizeReasonLine(l10n, line.trim()))
      .toList();
  return lines.join('\n');
}

String _localizeReasonLine(AppLocalizations l10n, String line) {
  if (line.isEmpty) return line;

  if (line == 'Overdue tasks need immediate attention') {
    return l10n.decisionReasonOverdueAttention;
  }
  if (line == 'You studied this course the least this week') {
    return l10n.decisionReasonLeastStudied;
  }
  if (line == 'No urgent deadlines. Stay consistent.') {
    return l10n.decisionReasonNoUrgentDeadlines;
  }
  if (line == 'You are behind your weekly target') {
    return l10n.decisionReasonBehindWeeklyTarget;
  }
  if (line == 'Heavy open workload in this course') {
    return l10n.decisionReasonHeavyWorkload;
  }
  if (line == 'This is your highest-priority course right now') {
    return l10n.decisionReasonHighestPriority;
  }
  if (line == 'Start building your routine') {
    return l10n.decisionReasonBuildRoutine;
  }
  if (line == 'Lowest study time this week') {
    return l10n.decisionReasonLowestStudyWeek;
  }
  if (line == 'No study logged this week') {
    return l10n.decisionReasonNoStudyLogged;
  }
  if (line == 'Fallback recommendation: keep your consistency this week') {
    return l10n.decisionReasonFallbackConsistency;
  }

  final deadlineLowStudyMatch = RegExp(
    r'^Deadline in (\d+) days and you studied less than usual this week$',
  ).firstMatch(line);
  if (deadlineLowStudyMatch != null) {
    final days = int.tryParse(deadlineLowStudyMatch.group(1) ?? '') ?? 0;
    return l10n.decisionReasonDeadlineLowStudy(days);
  }

  final deadlineMatch = RegExp(r'^Deadline in (\d+) days$').firstMatch(line);
  if (deadlineMatch != null) {
    final days = int.tryParse(deadlineMatch.group(1) ?? '') ?? 0;
    return l10n.decisionReasonDeadlineInDays(days);
  }

  final lowStudyDeadlineMatch = RegExp(
    r'^Lowest study time this week and deadline in (\d+) days$',
  ).firstMatch(line);
  if (lowStudyDeadlineMatch != null) {
    final days = int.tryParse(lowStudyDeadlineMatch.group(1) ?? '') ?? 0;
    return l10n.decisionReasonLowestStudyWithDeadline(days);
  }

  final lowStudyOpenTasksMatch = RegExp(
    r'^Lowest study time this week and (\d+) open tasks$',
  ).firstMatch(line);
  if (lowStudyOpenTasksMatch != null) {
    final count = int.tryParse(lowStudyOpenTasksMatch.group(1) ?? '') ?? 0;
    return l10n.decisionReasonLowestStudyWithOpenTasks(count);
  }

  final progressMatch = RegExp(
    r'^You studied ([0-9]+(?:\.[0-9])?)h of your ([0-9]+(?:\.[0-9])?)h target$',
  ).firstMatch(line);
  if (progressMatch != null) {
    final studied = progressMatch.group(1) ?? '0.0';
    final target = progressMatch.group(2) ?? '0.0';
    return l10n.decisionReasonStudyProgress(studied, target);
  }

  final ectsMatch = RegExp(r'^Important course \((\d+) ECTS\)$').firstMatch(line);
  if (ectsMatch != null) {
    final ects = int.tryParse(ectsMatch.group(1) ?? '') ?? 0;
    return l10n.decisionReasonImportantCourse(ects);
  }

  final higherPriorityMatch = RegExp(
    r'^Higher priority than (.+) \(less urgent\)$',
  ).firstMatch(line);
  if (higherPriorityMatch != null) {
    final course = higherPriorityMatch.group(1)?.trim() ?? '';
    if (course.isNotEmpty) {
      return l10n.decisionReasonHigherPriorityThan(course);
    }
    return l10n.decisionReasonHigherPriorityGeneral;
  }

  final moreUrgentMatch = RegExp(r'^More urgent than (.+)$').firstMatch(line);
  if (moreUrgentMatch != null) {
    final course = moreUrgentMatch.group(1)?.trim() ?? '';
    if (course.isNotEmpty) {
      return l10n.decisionReasonHigherPriorityThan(course);
    }
    return l10n.decisionReasonHigherPriorityGeneral;
  }

  return line;
}
