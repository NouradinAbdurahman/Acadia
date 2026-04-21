import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = GoRouter.of(context).canPop();

    if (!canPop && onPressed == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
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
