import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/trend_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../models/trend_data.dart';

class SmartInsightsCard extends ConsumerWidget {
  const SmartInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(trendProvider(7));
    final theme = Theme.of(context);

    return trendAsync.when(
      data: (trend) {
        final insights = trend.insights;
        if (insights.isEmpty) return const SizedBox.shrink();

        // Sort: critical > warning > good
        final sorted = List<TrendInsight>.from(insights)..sort((a, b) {
          final priority = {
            InsightType.critical: 0,
            InsightType.warning: 1,
            InsightType.good: 2,
          };
          return (priority[a.type] ?? 3).compareTo(priority[b.type] ?? 3);
        });

        final topInsight = sorted.first;

        return AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.bold),
                    size: 22,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Smart AI Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  _InsightIcon(type: topInsight.type),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                topInsight.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _insightColor(topInsight.type, theme),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                topInsight.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ).animate().shimmer(duration: 1500.ms, color: Colors.white10);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _InsightIcon extends StatelessWidget {
  final InsightType type;
  const _InsightIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case InsightType.good:
        return PhosphorIcon(
          PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
          size: 22,
          color: Colors.green,
        );
      case InsightType.warning:
        return PhosphorIcon(
          PhosphorIcons.warning(PhosphorIconsStyle.regular),
          size: 22,
          color: Colors.orange,
        );
      case InsightType.critical:
        return PhosphorIcon(
          PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
          size: 22,
          color: Colors.red,
        );
    }
  }
}

Color _insightColor(InsightType type, ThemeData theme) {
  switch (type) {
    case InsightType.good:
      return Colors.green;
    case InsightType.warning:
      return Colors.orange;
    case InsightType.critical:
      return Colors.red;
  }
}
