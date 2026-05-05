import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/semester_comparison_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../l10n/app_localizations.dart';

class SemesterComparisonCard extends ConsumerWidget {
  const SemesterComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(semesterComparisonProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return comparisonAsync.when(
      data: (comp) {
        if (comp == null || comp.previous == null) return const SizedBox.shrink();

        final focusDelta = comp.focusDelta ?? 0.0;
        final compDelta = comp.completionRateDelta ?? 0.0;
        final riskDelta = comp.riskDelta ?? 0.0;

        final focusDeltaText = (focusDelta * 100).toStringAsFixed(0);
        final compDeltaText = (compDelta * 100).toStringAsFixed(0);

        final focusDeltaColor = focusDelta >= 0 ? Colors.green : Colors.orange;
        final compDeltaColor = compDelta >= 0 ? Colors.green : Colors.orange;
        
        // Negative risk delta is GOOD (reduction in risk)
        final riskLabel = riskDelta > 0 
            ? l10n.riskIncreased(riskDelta.abs().round())
            : l10n.riskDecreased(riskDelta.abs().round());

        return AppGlassCard(
          borderOnly: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   PhosphorIcon(
                    PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.semesterTrend,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'vs ${comp.previousSemesterName}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _ComparisonMetric(
                    label: l10n.focusLabel,
                    delta: focusDelta,
                    deltaText: '$focusDeltaText%',
                    color: focusDeltaColor,
                    icon: PhosphorIcons.target,
                    iconStyle: PhosphorIconsStyle.regular,
                    subtitle: l10n.studyHours,
                  ),
                  _ComparisonMetric(
                    label: l10n.taskStatThisWeekByDeadline,
                    delta: compDelta,
                    deltaText: '$compDeltaText%',
                    color: compDeltaColor,
                    icon: PhosphorIcons.checkCircle,
                    iconStyle: PhosphorIconsStyle.regular,
                    subtitle: l10n.taskCompletionRate,
                  ),
                  if (comp.hasValidGpaComparison)
                    _ComparisonMetric(
                      label: 'GPA',
                      delta: comp.gpaDelta!,
                      deltaText: comp.gpaDelta! > 0 ? '+${comp.gpaDelta!.toStringAsFixed(2)}' : comp.gpaDelta!.toStringAsFixed(2),
                      color: comp.gpaDelta! >= 0 ? Colors.green : Colors.redAccent,
                      icon: PhosphorIcons.graduationCap,
                      iconStyle: PhosphorIconsStyle.regular,
                      subtitle: l10n.gradeAverage,
                    ),
                  _ComparisonMetric(
                    label: l10n.academicRisk,
                    delta: -riskDelta, // Invert for icon arrow (positive delta = more risk = bad)
                    deltaText: riskLabel,
                    color: riskDelta > 0 ? Colors.red : Colors.green,
                    icon: PhosphorIcons.warning,
                    iconStyle: PhosphorIconsStyle.regular,
                    subtitle: l10n.score,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...comp.generateInsights(l10n).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.regular),
                      size: 22,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        insight,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  final String label;
  final double delta;
  final String deltaText;
  final Color color;
  final PhosphorIconData Function([PhosphorIconsStyle]) icon;
  final PhosphorIconsStyle iconStyle;
  final String? subtitle;

  const _ComparisonMetric({
    required this.label,
    required this.delta,
    required this.deltaText,
    required this.color,
    required this.icon,
    required this.iconStyle,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = delta >= 0;
    final maxCardWidth = MediaQuery.of(context).size.width - (AppSpacing.lg * 4);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxCardWidth),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    icon(iconStyle),
                    size: 22,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      softWrap: true,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: 2,
                children: [
                  Text(
                    deltaText,
                    softWrap: true,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  PhosphorIcon(
                    (isPositive ? PhosphorIcons.trendUp : PhosphorIcons.trendDown)(PhosphorIconsStyle.regular),
                    size: 22,
                    color: color,
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  softWrap: true,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
