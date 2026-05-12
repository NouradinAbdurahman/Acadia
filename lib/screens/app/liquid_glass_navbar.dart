import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_icons.dart';

import '../../core/design/app_durations.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class _GlassNavTokens {
  static const double navHeight = 88;
  static const double outerBlur = 30;
  static const double activeBlur = 12;
  static const double activeSize = 60;
  static const double activeRadius = 20;
}

class LiquidGlassNavbar extends StatefulWidget {
  const LiquidGlassNavbar({
    super.key,
    required this.selectedIndex,
    required this.onSelectedIndex,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectedIndex;

  @override
  State<LiquidGlassNavbar> createState() => _LiquidGlassNavbarState();
}

class _LiquidGlassNavbarState extends State<LiquidGlassNavbar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 0,
        ),
        child: SizedBox(
          height: _GlassNavTokens.navHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl + AppRadius.sm),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _GlassNavTokens.outerBlur,
                sigmaY: _GlassNavTokens.outerBlur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppRadius.xl + AppRadius.sm,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: theme.brightness == Brightness.light ? 0.22 : 0.2,
                    ),
                    width: 0.8,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / 5;

                    return Stack(
                      children: [
                          AnimatedPositioned(
                            duration: AppDurations.normal,
                            curve: Curves.easeOutCubic,
                            left: tabWidth * widget.selectedIndex,
                            top: 0,
                            bottom: 0,
                            child: SizedBox(
                              width: tabWidth,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _GlassNavTokens.activeRadius,
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: _GlassNavTokens.activeBlur,
                                      sigmaY: _GlassNavTokens.activeBlur,
                                    ),
                                    child: Container(
                                      width: _GlassNavTokens.activeSize,
                                      height: _GlassNavTokens.activeSize,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          _GlassNavTokens.activeRadius,
                                        ),
                                        border: Border.all(
                                          color: Color.alphaBlend(
                                            theme.colorScheme.primary.withValues(
                                              alpha: theme.brightness == Brightness.light
                                                  ? 0.08
                                                  : 0.06,
                                            ),
                                            theme.colorScheme.outlineVariant.withValues(
                                              alpha: theme.brightness == Brightness.light
                                                  ? 0.48
                                                  : 0.42,
                                            ),
                                          ),
                                          width: 0.7,
                                        ),
                                        boxShadow: [],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < 5; i++)
                                SizedBox(
                                  width: tabWidth,
                                  child: _NavItem(
                                    label: [
                                      AppLocalizations.of(context)!.home,
                                      AppLocalizations.of(context)!.tasks,
                                      AppLocalizations.of(context)!.study,
                                      AppLocalizations.of(context)!.analytics,
                                      AppLocalizations.of(context)!.profile,
                                    ][i],
                                    icon: const [
                                      HeroIcons.squares2x2,
                                      HeroIcons.rectangleStack,
                                      HeroIcons.clock,
                                      HeroIcons.chartBar,
                                      HeroIcons.user,
                                    ][i],
                                    isSelected: widget.selectedIndex == i,
                                    onTap: () => widget.onSelectedIndex(i),
                                    theme: theme,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final HeroIcons icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final unselectedColor = widget.theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.45);

    final baseColor = widget.isSelected
        ? widget.theme.colorScheme.primary
        : unselectedColor;

    final labelColor = widget.isSelected
        ? widget.theme.colorScheme.primary
        : unselectedColor;

    final iconScaleBase = widget.isSelected ? 1.05 : 1.0;
    final iconScale = _isPressed ? iconScaleBase * 0.92 : iconScaleBase;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTap: () {
        setState(() => _isPressed = false);
        Haptics.vibrate(HapticsType.medium);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedSlide(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        offset: widget.isSelected ? const Offset(0, -0.02) : Offset.zero,
        child: AnimatedScale(
          scale: iconScale,
          duration: AppDurations.fast,
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                AppIcon(widget.icon, color: baseColor, size: 21)
                    .animate(target: widget.isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 220.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: AppDurations.normal,
                  curve: Curves.easeOut,
                  style: (widget.theme.textTheme.labelSmall ??
                          const TextStyle(fontSize: 8))
                      .copyWith(
                    color: labelColor,
                    fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 10,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
