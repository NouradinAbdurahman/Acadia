import 'package:flutter/widgets.dart';
import 'package:heroicons/heroicons.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.solid = false,
  });

  final HeroIcons icon;
  final double size;
  final Color? color;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return HeroIcon(
      icon,
      style: solid ? HeroIconStyle.solid : HeroIconStyle.outline,
      size: size,
      color: color,
    );
  }
}

