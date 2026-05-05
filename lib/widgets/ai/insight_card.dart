import 'package:flutter/material.dart';

import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Neutral info styling — reuse outside chat (Home, Analytics).
/// Supports an optional second line after `\n` when not [compact].
class InsightCard extends StatelessWidget {
  final String text;
  final bool compact;

  const InsightCard({
    super.key,
    required this.text,
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
    final mutedBlue = theme.colorScheme.primary.withValues(alpha: 0.85);
    final lines = _lines(text, compact);
    final secondary = lines.length > 1 ? lines[1] : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: mutedBlue),
                const SizedBox(width: 8),
                Text(
                  l10n.aiInsightTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: mutedBlue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              lines.first,
              maxLines: compact ? 1 : 4,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontSize: compact ? 13 : null,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
            if (!compact && secondary != null) ...[
              const SizedBox(height: 6),
              Text(
                secondary,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
