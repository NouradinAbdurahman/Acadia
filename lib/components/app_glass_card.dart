import 'package:flutter/material.dart';
import '../core/design/app_spacing.dart';

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24), // Smoother edges
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08) 
                : Colors.black.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
