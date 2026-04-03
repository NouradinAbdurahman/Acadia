import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/risk_provider.dart';

/// Displays the Academic Risk Score card on the Home screen.
class RiskScoreCard extends ConsumerWidget {
  const RiskScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final riskStateAsync = ref.watch(riskProvider);

    if (riskStateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (riskStateAsync.hasError || riskStateAsync.value == null) {
      return Center(child: Text(l10n.networkError));
    }

    final riskState = riskStateAsync.value!;
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: AppIcon(icon, size: 20.0, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.academicRisk,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Level pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
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
              // Trend indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrendBadge(delta: riskState.trendDelta),
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
          
          // Interpretation sentence (Smarter feedback)
          Text(
            riskState.getInterpretation(l10n),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Explanation list (reasons)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  AppIcon(HeroIcons.informationCircle, size: 14.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(r, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            )).toList(),
          ),
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
        return l10n.riskHigh;
      case 'medium':
        return l10n.riskMedium;
      default:
        return l10n.riskLow;
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
class RiskBreakdownCard extends ConsumerWidget {
  const RiskBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final riskStateAsync = ref.watch(riskProvider);

    if (!riskStateAsync.hasValue || riskStateAsync.value == null) {
      return AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text(l10n.networkError)),
      );
    }

    final riskState = riskStateAsync.value!;
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
            maxContribution: 45.0,
            color: const Color(0xFFEF4444), // red
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
            label: l10n.riskUpcomingTasks,
            value: input.upcomingTasks.toString(),
            contribution: risk.upcomingContribution,
            maxContribution: 15.0,
            color: const Color(0xFFF97316), // orange
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
            label: l10n.totalEctsLabel,
            value: input.totalECTS.toString(),
            contribution: risk.ectsContribution,
            maxContribution: 15.0,
            color: const Color(0xFF8B5CF6), // purple
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
            label: l10n.riskStudyDeficit,
            value: input.studyHours >= input.studyGoal
                ? l10n.riskGoalReached
                : l10n.riskHoursRemaining((input.studyGoal - input.studyHours).toStringAsFixed(1)),
            contribution: risk.studyContribution,
            maxContribution: 15.0,
            color: const Color(0xFF3B82F6), // blue
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
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: AppSpacing.sm),
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
