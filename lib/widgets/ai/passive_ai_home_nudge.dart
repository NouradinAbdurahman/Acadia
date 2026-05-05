import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/risk_provider.dart';
import '../../screens/ai/ai_chat_screen.dart';
import '../../services/ai/academic_insight_layer.dart';
import 'passive_ai_constants.dart';
import 'recommendation_action_utils.dart';

/// Subtle home-row nudge when tasks or study deficit cross thresholds.
/// Uses [AcademicInsightInput] text only — same deterministic layer as chat.
class PassiveAiHomeNudge extends ConsumerWidget {
  const PassiveAiHomeNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider).valueOrNull;
    final risk = ref.watch(riskProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (analytics == null || !analytics.hasData) {
      return const SizedBox.shrink();
    }

    final overdue = analytics.overdueTasks;
    final deficit = analytics.studyDeficit;

    final consistencyLow = analytics.consistency < kPassiveAiLowConsistency;
    if (overdue <= 0 &&
        deficit < kPassiveAiStudyDeficitHours &&
        !consistencyLow) {
      return const SizedBox.shrink();
    }

    final effectiveRisk =
        risk.hasData ? risk.result.totalScore : analytics.riskScore;
    final parts = AcademicInsightInput.fromAnalytics(
      data: analytics,
      riskScoreOverride: effectiveRisk,
      riskTrendDelta: risk.hasData ? risk.trendDelta : null,
    ).parts;

    final kind = inferRecommendationActionKind(
      recommendation: parts.recommendation,
      insight: parts.insight,
      overdueTasks: overdue,
      studyDeficitHours: deficit,
      consistency01: analytics.consistency,
    );

    final rawTitle = overdue > 0 ? parts.insight : parts.recommendation;
    final title = _nudgeDisplayLine(
      rawTitle,
      preferActionFirst: overdue <= 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondary) => const AIChatScreen(),
                transitionDuration: const Duration(milliseconds: 380),
                transitionsBuilder: (context, animation, _, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AppIcon(
                  HeroIcons.sparkles,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (kind != null)
                  FilledButton(
                    onPressed: () {
                      invokeRecommendationAction(
                        kind: kind,
                        context: context,
                        ref: ref,
                      );
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(_passiveCtaLabel(l10n, kind)),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          pageBuilder: (context, animation, secondary) => const AIChatScreen(),
                          transitionDuration: const Duration(milliseconds: 380),
                          transitionsBuilder: (context, animation, _, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Text(l10n.aiPassiveOpenAssistant),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact strip: action-first wording for common session reco (matches insight layer).
  static String _nudgeDisplayLine(
    String raw, {
    required bool preferActionFirst,
  }) {
    final line = raw.split('\n').first.trim();
    if (!preferActionFirst) return line;
    if (line.startsWith('Today: complete 1 focused study session')) {
      return line.replaceFirst(
        'Today: complete 1 focused study session',
        'Start one focused session now',
      );
    }
    if (line.startsWith('Today: complete 1 focused session')) {
      return line.replaceFirst(
        'Today: complete 1 focused session',
        'Start one focused session now',
      );
    }
    return line;
  }

  static String _passiveCtaLabel(
    AppLocalizations l10n,
    RecommendationActionKind k,
  ) {
    return switch (k) {
      RecommendationActionKind.startStudySession => l10n.aiActionStartStudy,
      RecommendationActionKind.addTask => l10n.aiActionAddTask,
      RecommendationActionKind.viewTasksDeadlines => l10n.aiPassiveReviewTasksNow,
      RecommendationActionKind.openAnalytics => l10n.aiPassiveViewAnalytics,
    };
  }
}
