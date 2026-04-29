import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_shadows.dart';
import '../core/design/app_durations.dart';
import '../core/design/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.text,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.child,
  });

  final Widget? child;
  final Widget? icon;
  final bool isFullWidth;

  @override
  AppButtonState createState() => AppButtonState();
}

class AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      Haptics.vibrate(HapticsType.medium);
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: AppDurations.normal,
            width: widget.isFullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.variant == AppButtonVariant.text ? AppSpacing.xs : AppSpacing.md,
              vertical: widget.variant == AppButtonVariant.text ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderXl,
              gradient: isDisabled
                  ? null
                  : (widget.variant == AppButtonVariant.primary
                      ? AppGradients.primaryAction
                      : null),
              color: isDisabled
                  ? theme.colorScheme.surface.withValues(alpha: 0.2)
                  : (widget.variant == AppButtonVariant.secondary
                      ? (isDark ? AppColors.glassSurface : Colors.white)
                      : (widget.variant == AppButtonVariant.text ? Colors.transparent : null)),
              border: widget.variant == AppButtonVariant.secondary
                  ? Border.all(
                      color: isDark
                          ? AppColors.glassBorder
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    )
                  : null,
              boxShadow: isDisabled || widget.variant == AppButtonVariant.secondary || widget.variant == AppButtonVariant.text
                  ? null
                  : AppShadows.primaryGlow,
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: widget.child ?? Text(
                            widget.text,
                            textAlign: TextAlign.center,
                            style: (widget.variant == AppButtonVariant.text
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)?.copyWith(
                                  color: isDisabled
                                      ? theme.textTheme.bodySmall?.color
                                      : (widget.variant == AppButtonVariant.primary
                                          ? Colors.white
                                          : theme.colorScheme.primary),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: AppDurations.fast),
            ),
        ),
      ),
    );
  }
}
