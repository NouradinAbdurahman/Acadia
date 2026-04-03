import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/semester.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../widgets/common/animated_pressable.dart';
import 'create_semester_screen.dart';

class SemesterManagementScreen extends ConsumerWidget {
  const SemesterManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final semestersAsync = ref.watch(semesterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allSemesters),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSemesterScreen(),
                ),
              );
            },
            icon: const AppIcon(HeroIcons.plus),
            tooltip: l10n.addSemester,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: semestersAsync.when(
            data: (semesters) {
              if (semesters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          HeroIcons.calendar,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noSemestersYet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.createFirstSemester,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateSemesterScreen(),
                              ),
                            );
                          },
                          text: l10n.addSemester,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final sortedSemesters = [...semesters]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: sortedSemesters.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final semester = sortedSemesters[index];
                  return _SemesterCard(semester: semester);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text(l10n.networkError)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSemesterScreen(),
            ),
          );
        },
        icon: const AppIcon(HeroIcons.plus, color: Colors.white, size: 18),
        label: Text(l10n.addSemester),
      ),
    );
  }
}

class _SemesterCard extends ConsumerWidget {
  const _SemesterCard({required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String dateLabel(DateTime? date) {
      if (date == null) return '-';
      return '${date.day}/${date.month}/${date.year}';
    }

    return Dismissible(
      key: Key(semester.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const AppIcon(HeroIcons.trash, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.delete),
                content: Text(l10n.deleteSemesterWarning),
                actions: [
                  AppButton(
                    onPressed: () => Navigator.pop(context, false),
                    variant: AppButtonVariant.text,
                    text: l10n.cancel,
                  ),
                  AppButton(
                    onPressed: () => Navigator.pop(context, true),
                    variant: AppButtonVariant.text,
                    text: l10n.delete,
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        await ref.read(semesterProvider.notifier).deleteSemester(semester.id);
      },
      child: AnimatedPressable(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSemesterScreen(semesterToEdit: semester),
            ),
          );
        },
        child: AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(HeroIcons.calendarDays),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            semester.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (semester.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.currentSemesterLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.startDate}: ${dateLabel(semester.startDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${l10n.endDate}: ${dateLabel(semester.endDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: semester.isCurrent,
                onChanged: (value) async {
                  if (value) {
                    await ref
                        .read(semesterProvider.notifier)
                        .setCurrentSemester(semester.id);
                    return;
                  }

                  await ref
                      .read(semesterProvider.notifier)
                      .updateSemester(semester.copyWith(isCurrent: false));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

