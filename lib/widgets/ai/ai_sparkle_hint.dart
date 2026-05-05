import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

import '../../core/design/app_icons.dart';

/// Subtle cue that the unified AI layer informs this section.
class AiSparkleHint extends StatelessWidget {
  const AiSparkleHint({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: 'Uses your live academic data',
        child: AppIcon(
          HeroIcons.sparkles,
          size: size,
          color: theme.colorScheme.primary.withValues(alpha: 0.55),
          solid: true,
        ),
      ),
    );
  }
}
