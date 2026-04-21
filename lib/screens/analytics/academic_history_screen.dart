import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:go_router/go_router.dart';
import '../../providers/semester_provider.dart';
import '../../providers/app_providers.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_back_button.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../models/semester.dart';
import '../../models/analytics_data.dart';
import '../../widgets/semester/performance_summary_widget.dart';
import '../../l10n/app_localizations.dart';

class AcademicHistoryScreen extends ConsumerWidget {
  const AcademicHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(orderedSemestersProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.academicHistory),
        leading: AppBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: semestersAsync.when(
            data: (semesters) {
              if (semesters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.noAcademicHistory,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.startLoggingContext,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          text: l10n.setUpSemester,
                          onPressed: () => context.go('/settings'), // Assuming settings is where they manage semesters
                        ),
                      ],
                    ),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: PerformanceSummaryWidget(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final semester = semesters[index];
                          return _SemesterHistoryItem(semester: semester);
                        },
                        childCount: semesters.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}

class _SemesterHistoryItem extends ConsumerWidget {
  final Semester semester;
  const _SemesterHistoryItem({required this.semester});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(analyticsRepositoryProvider);
    final currentUser = ref.watch(currentAppUserProvider).value;
    final activeSemesterId = ref.watch(activeSemesterProvider);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<AnalyticsData>(
      future: repository.getAnalyticsData(currentUser?.id ?? '', semesterId: semester.id),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasSemesterData =
            data != null &&
            (data.totalTasks > 0 ||
                data.studyHoursPerCourse.isNotEmpty ||
                data.gradeDistribution.isNotEmpty);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        semester.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (semester.id == activeSemesterId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          l10n.activeLabel.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isLoading)
                  const LinearProgressIndicator()
                else if (hasSemesterData) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CompactStat(
                        icon: HeroIcons.clock,
                        label: l10n.focusLabel,
                        value: '${data.weeklyAverageStudyHours.toStringAsFixed(1)}h',
                      ),
                      _CompactStat(
                        icon: HeroIcons.checkBadge,
                        label: l10n.completed,
                        value: '${(data.taskCompletionRate * 100).round()}%',
                      ),
                      _CompactStat(
                        icon: HeroIcons.academicCap,
                        label: 'GPA',
                        value: data.averageGPA == 0 ? 'N/A' : data.averageGPA.toStringAsFixed(2),
                      ),
                       _CompactStat(
                        icon: HeroIcons.shieldExclamation,
                        label: l10n.academicRisk,
                        value: '${data.riskScore.toStringAsFixed(0)}%',
                        color: _getRiskColor(data.riskScore),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    l10n.noDataForSemesterYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: l10n.switchToSemester,
                  onPressed: () async {
                    await ref.read(activeSemesterProvider.notifier).setActiveSemester(semester.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color? _getRiskColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.redAccent;
  }
}

class _CompactStat extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final String value;
  final Color? color;

  const _CompactStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HeroIcon(icon, size: 10, color: displayColor.withValues(alpha: 0.5)),
            const SizedBox(width: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: displayColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: displayColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
