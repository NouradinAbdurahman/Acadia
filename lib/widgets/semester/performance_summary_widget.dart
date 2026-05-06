import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/performance_summary_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../l10n/app_localizations.dart';

class PerformanceSummaryWidget extends ConsumerWidget {
  const PerformanceSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(performanceSummaryProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return summaryAsync.when(
      data: (summary) {
        if (summary == null || summary.history.length < 2) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.academicReport,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                   if (summary.bestSemester != null)
                    _PerformanceCard(
                      label: l10n.bestSemester,
                      value: summary.bestSemester!.name,
                      caption: l10n.gpaValueLabel(
                        summary.highestGpa?.toStringAsFixed(2) ?? '--',
                      ),
                      icon: null,
                      color: Colors.amber,
                    ),
                  if (summary.mostImprovedSemester != null && (summary.improvementDelta ?? 0) > 0.1)
                    _PerformanceCard(
                      label: l10n.mostImproved,
                      value: summary.mostImprovedSemester!.name,
                      caption: '+${summary.improvementDelta?.toStringAsFixed(2)} ${l10n.gpaPoints}',
                      icon: HeroIcons.rocketLaunch,
                      color: Colors.green,
                    ),
                   if (summary.worstSemester != null && summary.worstSemester?.id != summary.bestSemester?.id)
                    _PerformanceCard(
                      label: l10n.requiresFocus,
                      value: summary.worstSemester!.name,
                      caption: l10n.gpaValueLabel(
                        summary.lowestGpa?.toStringAsFixed(2) ?? '--',
                      ),
                      icon: HeroIcons.exclamationTriangle,
                      color: Colors.orange,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final HeroIcons? icon;
  final Color color;

  const _PerformanceCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  HeroIcon(icon!, size: 16, color: color),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
