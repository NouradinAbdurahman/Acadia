import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:go_router/go_router.dart';
import '../../providers/semester_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_button.dart';
import '../../models/semester.dart';

class SemesterSwitcherBottomSheet extends ConsumerWidget {
  const SemesterSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(orderedSemestersProvider);
    final activeSemesterId = ref.watch(activeSemesterProvider);
    final isSwitching = ref.watch(isSemesterSwitchingProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Semester',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: isSwitching ? null : () => Navigator.pop(context),
                icon: const HeroIcon(HeroIcons.xMark),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          if (isSwitching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: AppSpacing.lg),
          semestersAsync.when(
            data: (semesters) {
              if (semesters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Column(
                      children: [
                        HeroIcon(
                          HeroIcons.calendar,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No semesters found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: semesters.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  final isActive = semester.id == activeSemesterId;

                  return _SemesterItem(
                    semester: semester,
                    isActive: isActive,
                    isSwitching: isSwitching,
                    onTap: () async {
                      if (!isActive && !isSwitching) {
                        try {
                          await ref
                              .read(activeSemesterProvider.notifier)
                              .setActiveSemester(semester.id);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          // Handle error if needed
                        }
                      } else if (isActive) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Manage Semesters',
            onPressed: isSwitching ? null : () {
                context.pop();
                context.push('/semesters');
            },
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _SemesterItem extends StatelessWidget {
  final Semester semester;
  final bool isActive;
  final bool isSwitching;
  final VoidCallback onTap;

  const _SemesterItem({
    required this.semester,
    required this.isActive,
    required this.isSwitching,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: HeroIcon(
                HeroIcons.calendarDays,
                size: 20,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? theme.colorScheme.primary : null,
                    ),
                  ),
                  if (isActive) 
                    Text(
                      'Current',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              HeroIcon(
                HeroIcons.checkCircle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
