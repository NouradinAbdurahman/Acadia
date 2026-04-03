import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_icons.dart';

import '../../core/design/app_durations.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';

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
  double _dragDelta = 0;

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
          height: 84,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl + AppRadius.sm),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.white.withValues(alpha: 0.88)
                      : const Color(0xFF0F172A).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(
                    AppRadius.xl + AppRadius.sm,
                  ),
                  border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.light
                            ? 0.08
                            : 0.5,
                      ),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / 5;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        _dragDelta += details.delta.dx;
                        const threshold = 40.0;
                        if (_dragDelta.abs() >= threshold) {
                          final direction = _dragDelta > 0 ? 1 : -1;
                          _dragDelta = 0;
                          final current = widget.selectedIndex;
                          final next = (current + direction)
                              .clamp(0, 4)
                              .toInt();
                          if (next != current) {
                            HapticFeedback.selectionClick();
                            widget.onSelectedIndex(next);
                          }
                        }
                      },
                      onHorizontalDragEnd: (_) {
                        _dragDelta = 0;
                      },
                      onHorizontalDragCancel: () {
                        _dragDelta = 0;
                      },
                      child: Stack(
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
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
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
                      ),
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
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);

    final baseColor = widget.isSelected
        ? widget.theme.colorScheme.primary
        : unselectedColor;

    final labelColor = widget.isSelected
        ? widget.theme.colorScheme.primary
        : unselectedColor;

    final iconScaleBase = widget.isSelected ? 1.08 : 1.0;
    final iconScale = _isPressed ? iconScaleBase * 0.9 : iconScaleBase;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedSlide(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        offset: widget.isSelected ? const Offset(0, -0.05) : Offset.zero,
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
                AppIcon(widget.icon, color: baseColor, size: 24)
                    .animate(target: widget.isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 220.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedDefaultTextStyle(
                  duration: AppDurations.normal,
                  curve: Curves.easeOut,
                  style:
                      (widget.theme.textTheme.bodySmall ??
                              const TextStyle(fontSize: 10))
                          .copyWith(
                            color: labelColor,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                  child: AnimatedOpacity(
                    duration: AppDurations.normal,
                    opacity: widget.isSelected ? 1 : 0.86,
                    child: Text(widget.label),
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
