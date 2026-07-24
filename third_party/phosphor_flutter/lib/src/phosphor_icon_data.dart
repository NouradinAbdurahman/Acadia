import 'package:flutter/widgets.dart';

// PATCHED: Flutter's IconData became a `final class`, which forbids
// extending it from outside its own library, and Flutter's icon
// tree-shaker requires IconData(...) call sites to use constant arguments.
// Every generated icon constant (phosphor_icons_*.dart) is now a plain
// `const IconData(...)` literal instead of a PhosphorFlatIconData/
// PhosphorDuotoneIconData subclass, so PhosphorIconData is just an alias
// for IconData to keep existing type annotations (PhosphorIcons.acorn(),
// PhosphorIconData Function(...) fields, etc.) working unchanged.
//
// Dropped in this patch: true dual-color duotone rendering (the secondary
// layer previously carried on PhosphorDuotoneIconData). Nothing in this
// app selects PhosphorIconsStyle.duotone, so duotone icons still render
// correctly, just as a single layer instead of two.
typedef PhosphorIconData = IconData;
