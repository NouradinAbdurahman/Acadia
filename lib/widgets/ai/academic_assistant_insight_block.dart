import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/adaptive_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/study_sessions_provider.dart';
import '../../services/ai/academic_insight_layer.dart';
import '../../services/ai/academic_data_guard.dart';
import 'insight_card.dart';
import 'insight_display_variant.dart';
import 'recommendation_card.dart';
import 'recommendation_action_utils.dart';

/// Same deterministic insight layer as AI chat — single source ([AcademicInsightInput]).
class AcademicAssistantInsightBlock extends ConsumerWidget {
  /// When false, hides the section title (chat embeds without title).
  final bool showSectionTitle;

  final InsightDisplayVariant variant;

  const AcademicAssistantInsightBlock({
    super.key,
    this.showSectionTitle = true,
    this.variant = InsightDisplayVariant.full,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemesterAsync = ref.watch(activeSemesterProvider);
    final activeSemesterId = activeSemesterAsync.valueOrNull;
    if (activeSemesterId == null) {
      return const SizedBox.shrink();
    }

    final analyticsAsync = ref.watch(analyticsProvider);
    final tasks = (ref.watch(tasksProvider).valueOrNull ?? const [])
        .where((t) => t.semesterId == activeSemesterId)
        .toList(growable: false);
    final sessions = (ref.watch(studySessionsProvider).valueOrNull ?? const [])
        .where((s) => s.semesterId == activeSemesterId)
        .toList(growable: false);
    if (!hasAcademicData(tasks: tasks, sessions: sessions)) {
      return const SizedBox.shrink();
    }
    if (!hasEnoughSignal(tasks: tasks, sessions: sessions)) {
      return const SizedBox.shrink();
    }

    return analyticsAsync.when(
      data: (analytics) {
        if (!analytics.hasData) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final risk = ref.watch(riskProvider);
        final adaptive = ref.watch(adaptiveProfileProvider);
        final studyAnalytics = ref.watch(studyAnalyticsProvider);

        final effectiveRisk =
            risk.hasData ? risk.result.totalScore : analytics.riskScore;
        final input = AcademicInsightInput.fromAnalytics(
          data: analytics,
          riskScoreOverride: effectiveRisk,
          riskTrendDelta: risk.hasData ? risk.trendDelta : null,
          adaptiveProfile: adaptive,
          burnoutRisk: studyAnalytics.burnoutScore,
          hasAcademicData: hasAcademicData(tasks: tasks, sessions: sessions),
          hasEnoughSignal: hasEnoughSignal(tasks: tasks, sessions: sessions),
        );
        final parts = input.partsWithL10n(l10n);
        if (parts.insight.trim().isEmpty || parts.recommendation.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final overdue = analytics.overdueTasks;
        final deficit = analytics.studyDeficit;
        final consistency = analytics.consistency;

        final kind = inferRecommendationActionKind(
          recommendation: parts.recommendation,
          insight: parts.insight,
          overdueTasks: overdue,
          studyDeficitHours: deficit,
          consistency01: consistency,
        );

        final theme = Theme.of(context);
        final compact = variant == InsightDisplayVariant.compact;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSectionTitle) ...[
              Text(
                variant == InsightDisplayVariant.full
                    ? l10n.aiInsightSectionTitle
                    : l10n.aiInsightTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            InsightCard(text: parts.insight, compact: compact),
            const SizedBox(height: AppSpacing.sm),
            RecommendationCard(
              text: parts.recommendation,
              compact: compact,
              actionKind: kind,
              onAction: compact || kind == null
                  ? null
                  : () => invokeRecommendationAction(
                        kind: kind,
                        context: context,
                        ref: ref,
                      ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.03, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
      },
      loading: () => _InsightBlockSkeleton(compact: variant == InsightDisplayVariant.compact),
      error: (Object err, StackTrace st) => const SizedBox.shrink(),
    );
  }
}

class _InsightBlockSkeleton extends StatelessWidget {
  const _InsightBlockSkeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Solid blocks only — nested bars + padding exceeded fixed heights and caused RenderFlex overflow.
    final cardHeight = compact ? 56.0 : 78.0;

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      highlightColor: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
