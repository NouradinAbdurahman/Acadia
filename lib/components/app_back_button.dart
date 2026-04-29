import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    /// Left-align the icon with padded screen content (removes default IconButton inset).
    this.alignToContentEdge = false,
  });

  final VoidCallback? onPressed;
  final Color? color;
  final bool alignToContentEdge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = GoRouter.of(context).canPop();

    if (!canPop && onPressed == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      style: alignToContentEdge
          ? IconButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(kMinInteractiveDimension, kMinInteractiveDimension),
            )
          : null,
      onPressed: () {
        Haptics.vibrate(HapticsType.medium);
        if (onPressed != null) {
          onPressed!();
        } else {
          context.pop();
        }
      },
      icon: HeroIcon(
        HeroIcons.chevronLeft,
        color: color ?? theme.colorScheme.onSurface,
        size: 24,
      ),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
