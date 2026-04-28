import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/risk_provider.dart';
import '../../domain/risk/risk_state.dart';

class RiskScoreCard extends ConsumerStatefulWidget {
  const RiskScoreCard({super.key});

  @override
  ConsumerState<RiskScoreCard> createState() => _RiskScoreCardState();
}

class _RiskScoreCardState extends ConsumerState<RiskScoreCard> {
  RiskState? _lastRisk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final riskState = ref.watch(riskProvider);

    if (!riskState.hasData) {
      return const SizedBox.shrink();
    }

    final risk = riskState.result;

    final color = _colorForLevel(risk.riskLevel);
    final icon = _iconForLevel(risk.riskLevel);
    final label = _labelForLevel(l10n, risk.riskLevel);
    final reasons = riskState.getReasons(l10n);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (Risk level pill & title)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.academicRisk,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Score row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                    risk.totalScore.toInt().toString(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ' / 100',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: (risk.totalScore >= 30) 
                          ? _TrendBadge(delta: riskState.trendDelta)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: risk.totalScore / 100,
              minHeight: 8.0,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          

        ],
      ),
    ).animate().fade(delay: 50.ms).slideY(begin: 0.08);
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'high':
        return const Color(0xFFEF4444); // red
      case 'medium':
        return const Color(0xFFF97316); // orange
      default:
        return const Color(0xFF22C55E); // green
    }
  }

  HeroIcons _iconForLevel(String level) {
    switch (level) {
      case 'high':
        return HeroIcons.exclamationCircle;
      case 'medium':
        return HeroIcons.exclamationTriangle;
      default:
        return HeroIcons.checkCircle;
    }
  }

  String _labelForLevel(AppLocalizations l10n, String level) {
    switch (level) {
      case 'high':
        return l10n.riskLevelCritical;
      case 'medium':
        return l10n.riskLevelWarning;
      default:
        return l10n.riskLevelSafe;
    }
  }
}

class _TrendBadge extends StatelessWidget {
  final int? delta;

  const _TrendBadge({this.delta});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (delta == null) {
      return _buildContainer(
        theme,
        l10n.riskTrendNew,
        theme.colorScheme.onSurface.withValues(alpha: 0.5),
        null,
      );
    }

    if (delta == 0) {
      return _buildContainer(
        theme,
        l10n.riskTrendStable,
        theme.colorScheme.onSurface.withValues(alpha: 0.5),
        null,
      );
    }

    final isUp = delta! > 0;
    // For academic risk, going UP is BAD (red), going DOWN is GOOD (green)
    final color = isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final icon = isUp ? HeroIcons.arrowTrendingUp : HeroIcons.arrowTrendingDown;
    final text = isUp 
        ? l10n.riskTrendUp(delta!) 
        : l10n.riskTrendDown(delta!.abs());

    return _buildContainer(theme, text, color, icon);
  }

  Widget _buildContainer(ThemeData theme, String text, Color color, HeroIcons? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HeroIcon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed risk breakdown panel used in the Analytics screen.
class RiskBreakdownCard extends ConsumerStatefulWidget {
  const RiskBreakdownCard({super.key});

  @override
  ConsumerState<RiskBreakdownCard> createState() => _RiskBreakdownCardState();
}

class _RiskBreakdownCardState extends ConsumerState<RiskBreakdownCard> {
  RiskState? _lastRisk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final riskState = ref.watch(riskProvider);

    if (!riskState.hasData) {
      return const SizedBox.shrink();
    }

    final risk = riskState.result;
    final input = riskState.input;

    final color = _colorForLevel(risk.riskLevel);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.riskBreakdownTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${risk.totalScore.toInt()} / 100',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Breakdown rows
          _BreakdownRow(
            label: l10n.riskOverdueTasks,
            value: input.overdueTasks.toString(),
            contribution: risk.overdueContribution,
            maxContribution: 30.0,
            color: const Color(0xFFEF4444), // red
          ),
          _BreakdownRow(
            label: l10n.riskUpcomingTasks,
            value: input.upcomingTasks.toString(),
            contribution: risk.upcomingContribution,
            maxContribution: 15.0,
            color: const Color(0xFFF97316), // orange
          ),
          const SizedBox(height: AppSpacing.sm),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
            label: l10n.riskStudyDeficit,
            value: input.studyHours >= input.studyGoal
                ? l10n.riskGoalReached
                : l10n.riskHoursRemaining((input.studyGoal - input.studyHours).toStringAsFixed(1)),
            contribution: risk.studyContribution,
            maxContribution: 25.0,
            color: const Color(0xFF3B82F6), // blue
          ),
          const SizedBox(height: AppSpacing.sm),
          _BreakdownRow(
            label: l10n.riskSessionStress,
            value: input.avgSessionStress.toStringAsFixed(1),
            contribution: risk.sessionStressContribution,
            maxContribution: 15.0,
            color: const Color(0xFF8B5CF6), // purple
          ),
          const SizedBox(height: AppSpacing.sm),
          _BreakdownRow(
            label: l10n.weeklyConsistency,
            value: '${(input.consistency * 100).toInt()}%',
            contribution: risk.consistencyContribution,
            maxContribution: 15.0,
            color: const Color(0xFFF59E0B), // amber
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.studyDeficitBasedOnWeeklyGoal(input.studyGoal.toStringAsFixed(0)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 150.ms).slideY(begin: 0.08);
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

class BurnoutStatusCard extends ConsumerWidget {
  const BurnoutStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final analytics = ref.watch(studyAnalyticsProvider);

    if (!analytics.hasData) {
      return const SizedBox.shrink();
    }

    final score = analytics.burnoutScore;
    final level = analytics.burnoutLevel;
    final color = _burnoutColor(level);
    final localizedLevel = _localizedBurnoutLevel(l10n, level);
    final localizedExplanation = _localizedBurnoutExplanation(l10n, level);
    final localizedReasons = _localizedBurnoutReasons(l10n, analytics);
    final localizedRecommendations = _localizedBurnoutRecommendations(l10n, level);
    final trendColor = _trendColor(analytics.burnoutTrendLabel);
    final deficitTrendColor = _trendColor(analytics.deficitTrendLabel);
    final consistencyTrendColor = _trendColor(analytics.consistencyTrendLabel);
    final hasFullyStableTrends =
      analytics.burnoutTrendLabel == 'stable' &&
      analytics.deficitTrendLabel == 'stable' &&
      analytics.consistencyTrendLabel == 'stable';
    final burnoutTrendLabel = _localizedTrendLabel(l10n, analytics.burnoutTrendLabel);
    final deficitTrendLabel = _localizedTrendLabel(l10n, analytics.deficitTrendLabel);
    final consistencyTrendLabel =
      _localizedTrendLabel(l10n, analytics.consistencyTrendLabel);

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: AppIcon(
                  HeroIcons.fire,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.burnoutStatusTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      localizedLevel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizedExplanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ).animate().fade().slideX(begin: 0.1),
          const SizedBox(height: AppSpacing.sm),

          if (!analytics.hasBurnoutTrendHistory && analytics.burnoutLevel != BurnoutLevel.stable)
            Text(
              l10n.burnoutExplanationNew,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (analytics.recoveryDetected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                l10n.recoveryImprovingThisWeek,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (analytics.hasBurnoutTrendHistory)
            Text(
              analytics.burnoutTrendFallbackMessage(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.studyDeficitBasedOnWeeklyGoal(
              analytics.weeklyGoalHours.toStringAsFixed(0),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...localizedReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: color.withValues(alpha: 0.9)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.softInterventionsTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...localizedRecommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, size: 16, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 120.ms).slideY(begin: 0.08);
  }
}

String _localizedTrendLabel(AppLocalizations l10n, String label) {
  switch (label.toLowerCase()) {
    case 'improving':
      return l10n.trendImproving;
    case 'worsening':
      return l10n.trendWorsening;
    case 'unstable':
      return l10n.trendUnstable;
    case 'moderate':
      return l10n.trendModerate;
    case 'stable':
      return l10n.trendStable;
    default:
      return label;
  }
}

String _localizedBurnoutLevel(AppLocalizations l10n, BurnoutLevel level) {
  switch (level) {
    case BurnoutLevel.stable:
      return l10n.burnoutLevelStable;
    case BurnoutLevel.warning:
      return l10n.burnoutLevelWarning;
    case BurnoutLevel.highRisk:
      return l10n.burnoutLevelHighRisk;
    case BurnoutLevel.burnoutRisk:
      return l10n.burnoutLevelBurnoutRisk;
  }
}

String _localizedBurnoutExplanation(AppLocalizations l10n, BurnoutLevel level) {
  switch (level) {
    case BurnoutLevel.stable:
      return l10n.burnoutExplanationStable;
    case BurnoutLevel.warning:
    case BurnoutLevel.highRisk:
    case BurnoutLevel.burnoutRisk:
      return l10n.burnoutExplanationFallingBehind;
  }
}

List<String> _localizedBurnoutReasons(AppLocalizations l10n, StudyAnalytics analytics) {
  final reasons = <String>[];
  
  // behavioral / pattern based reasons
  if (analytics.avgSessionStress >= 7) {
    reasons.add(l10n.burnoutBehaviorHighFatigue);
    if (analytics.hasMoodTrendDown) reasons.add(l10n.burnoutBehaviorMoodInstability);
    if (analytics.consistency < 0.6) reasons.add(l10n.burnoutBehaviorIrregularRest);
    return reasons;
  }

  if (analytics.timeInconsistencyScore >= 45) {
    reasons.add(l10n.burnoutBehaviorUnpredictableRhythm);
  }
  if (analytics.irregularStudyPattern) {
    reasons.add(l10n.burnoutBehaviorSwitchingContext);
  }
  if (analytics.excessiveStudy) {
    reasons.add(l10n.burnoutBehaviorMentalOverload);
  }
  if (reasons.isEmpty) {
    reasons.add(l10n.burnoutReasonNoMajorSignals);
  }
  return reasons;
}

List<String> _localizedBurnoutRecommendations(AppLocalizations l10n, BurnoutLevel level) {
  switch (level) {
    case BurnoutLevel.stable:
      return [
        l10n.burnoutRecommendationStable1,
        l10n.burnoutRecommendationStable2,
      ];
    case BurnoutLevel.warning:
      return [
        l10n.burnoutRecommendationWarning1,
        l10n.burnoutRecommendationWarning2,
      ];
    case BurnoutLevel.highRisk:
      return [
        l10n.burnoutRecommendationHigh1,
        l10n.burnoutRecommendationHigh2,
        l10n.burnoutRecommendationHigh3,
      ];
    case BurnoutLevel.burnoutRisk:
      return [
        l10n.burnoutRecommendationBurnout1,
        l10n.burnoutRecommendationBurnout2,
        l10n.burnoutRecommendationBurnout3,
      ];
  }
}

Color _burnoutColor(BurnoutLevel level) {
  switch (level) {
    case BurnoutLevel.stable:
      return const Color(0xFF22C55E);
    case BurnoutLevel.warning:
      return const Color(0xFFF59E0B);
    case BurnoutLevel.highRisk:
      return const Color(0xFFF97316);
    case BurnoutLevel.burnoutRisk:
      return const Color(0xFFEF4444);
  }
}

Color _trendColor(String label) {
  switch (label.toLowerCase()) {
    case 'improving':
      return const Color(0xFF22C55E);
    case 'worsening':
      return const Color(0xFFEF4444);
    case 'unstable':
      return const Color(0xFFF97316);
    default:
      return const Color(0xFF6B7280);
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final double contribution;
  final double maxContribution;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.contribution,
    required this.maxContribution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxContribution > 0
        ? (contribution / maxContribution).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Row(
              children: [
                if (value.isNotEmpty) ...[
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  '+${contribution.toInt()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6.0,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
