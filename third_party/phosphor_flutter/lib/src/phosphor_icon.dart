import 'package:flutter/material.dart';

// PATCHED: previously special-cased PhosphorDuotoneIconData to render a
// faint secondary layer beneath the primary icon. That type no longer
// exists (see phosphor_icon_data.dart) since IconData can't be subclassed,
// so this is now a plain Icon subclass. duotoneSecondaryOpacity/Color are
// kept as accepted-but-unused params so call sites don't need to change.
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    super.icon, {
    super.key,
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.shadows,
    super.semanticLabel,
    super.textDirection,
    this.duotoneSecondaryOpacity = 0.20,
    this.duotoneSecondaryColor,
  });

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;
}
