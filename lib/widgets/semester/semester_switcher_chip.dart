import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/semester_provider.dart';
import 'semester_switcher_bottom_sheet.dart';

class SemesterSwitcherChip extends ConsumerWidget {
  const SemesterSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterFullProvider);
    final isSwitching = ref.watch(isSemesterSwitchingProvider);
    final theme = Theme.of(context);

    if (activeSemester == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: isSwitching ? null : () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const SemesterSwitcherBottomSheet(),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSwitching ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSwitching)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              else
                HeroIcon(
                  HeroIcons.academicCap,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              const SizedBox(width: 6),
              Text(
                activeSemester.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              HeroIcon(
                HeroIcons.chevronDown,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
