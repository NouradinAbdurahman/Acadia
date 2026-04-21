import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/design/app_spacing.dart';

class HomeSkeletonScreen extends StatelessWidget {
  const HomeSkeletonScreen({super.key});

  Widget _buildBlock(ThemeData theme, double height, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            // Header Profile Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Skeleton Cards Sequence mimicking the home layout
            _buildBlock(theme, 60), // Semester banner
            const SizedBox(height: AppSpacing.sm),
            _buildBlock(theme, 260), // Heatmap
            const SizedBox(height: AppSpacing.md),
            _buildBlock(theme, 100), // Live Study
            const SizedBox(height: AppSpacing.md),
            _buildBlock(theme, 240), // Risk Score
            const SizedBox(height: AppSpacing.md),
            _buildBlock(theme, 160), // Predicted Stress
            const SizedBox(height: AppSpacing.md),
            _buildBlock(theme, 200), // Recommended Plan
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
