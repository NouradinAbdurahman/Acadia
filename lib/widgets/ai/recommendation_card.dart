import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'recommendation_action_utils.dart';

/// Stronger accent — primary + optional second line (`\n` in [text]). Max 2 lines shown.
class RecommendationCard extends StatelessWidget {
  final String text;
  final RecommendationActionKind? actionKind;
  final VoidCallback? onAction;
  final bool compact;

  const RecommendationCard({
    super.key,
    required this.text,
    this.actionKind,
    this.onAction,
    this.compact = false,
  });

  static List<String> _lines(String raw, bool compact) {
    final parts = raw
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return [''];
    if (compact) return [parts.first];
    return parts.length > 2 ? [parts[0], parts[1]] : parts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = theme.colorScheme.tertiary;
    final lines = _lines(text, compact);
    final primaryLine = lines.first;
    final secondaryLine = lines.length > 1 ? lines[1] : null;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  l10n.aiRecommendationTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              primaryLine,
              maxLines: compact ? 1 : 3,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontSize: compact ? 13 : null,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
              ),
            ),
            if (!compact && secondaryLine != null) ...[
              const SizedBox(height: 6),
              Text(
                secondaryLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (!compact && onAction != null && actionKind != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(_iconFor(actionKind!)),
                  label: Text(_label(l10n, actionKind!)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return content
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, end: 0, duration: 240.ms, curve: Curves.easeOutCubic);
  }

  static IconData _iconFor(RecommendationActionKind k) {
    return switch (k) {
      RecommendationActionKind.startStudySession => Icons.play_circle_outline_rounded,
      RecommendationActionKind.addTask => Icons.add_task_rounded,
      RecommendationActionKind.viewTasksDeadlines => Icons.event_note_rounded,
      RecommendationActionKind.openAnalytics => Icons.insights_rounded,
    };
  }

  static String _label(AppLocalizations l10n, RecommendationActionKind k) {
    return switch (k) {
      RecommendationActionKind.startStudySession => l10n.aiActionStartStudy,
      RecommendationActionKind.addTask => l10n.aiActionAddTask,
      RecommendationActionKind.viewTasksDeadlines => l10n.aiActionViewTasks,
      RecommendationActionKind.openAnalytics => l10n.aiActionOpenAnalytics,
    };
  }
}
