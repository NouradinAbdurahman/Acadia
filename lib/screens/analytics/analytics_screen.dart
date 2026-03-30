import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/analytics_data.dart';
import '../../models/course.dart';
import '../../widgets/risk/risk_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: analyticsAsync.when(
            data: (data) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analytics,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                  ).animate().fade().slideX(begin: -0.1),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // 0. Academic Risk Breakdown
                  _buildSectionTitle(theme, l10n.academicRisk),
                  const SizedBox(height: AppSpacing.md),
                  const RiskBreakdownCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // 1. Study Hours by Course
                  _buildSectionTitle(theme, l10n.studyHoursByCourse),
                  Text(l10n.thisWeekLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  _StudyHoursBarChart(data: data),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // 2. Task Completion
                  _buildSectionTitle(theme, l10n.weeklyTaskCompletion),
                  Text(l10n.thisWeekLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  _TaskCompletionPieChart(data: data),
                  const SizedBox(height: AppSpacing.xl),

                  const SizedBox(height: 120),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.networkError, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _StudyHoursBarChart extends ConsumerWidget {
  final AnalyticsData data;
  const _StudyHoursBarChart({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(courseProvider);
    
    if (data.studyHoursPerCourse.isEmpty) {
      return AppGlassCard(
        height: 200,
        child: Center(child: Text(l10n.noStudyDataThisWeek)),
      );
    }

    return coursesAsync.when(
      data: (courses) {
        final List<_BarData> barData = [];
        data.studyHoursPerCourse.forEach((courseId, hours) {
          final course = courses.firstWhere(
            (c) => c.id == courseId,
            orElse: () => Course(
              id: courseId,
              userId: '',
              courseName: 'Unknown',
              credits: 0,
              ects: 0,
              color: '#9E9E9E',
              createdAt: DateTime.now(),
            ),
          );
          barData.add(_BarData(course, hours));
        });

        // Filter and sort for display
        barData.sort((a, b) => b.hours.compareTo(a.hours));
        final topBars = barData.take(5).toList();

        return AppGlassCard(
          height: 240,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topBars.isEmpty ? 5.0 : topBars.map((e) => e.hours).reduce((a, b) => a > b ? a : b) + 1,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < topBars.length) {
                        final name = topBars[index].course.courseName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            name.length > 15 ? '${name.substring(0, 14)}..' : name,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}${l10n.hoursAbbreviation}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: topBars.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.hours < 0.05 ? 0.05 : entry.value.hours,
                      color: entry.value.course.uiColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const AppGlassCard(height: 240, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => AppGlassCard(height: 240, child: Center(child: Text(l10n.networkError))),
    );
  }
}

class _BarData {
  final Course course;
  final double hours;
  _BarData(this.course, this.hours);
}

class _TaskCompletionPieChart extends StatelessWidget {
  final AnalyticsData data;
  const _TaskCompletionPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    if (data.totalTasks == 0) {
      return AppGlassCard(
        height: 200,
        child: Center(child: Text(l10n.noTasksThisWeek)),
      );
    }

    final percentage = data.taskCompletionRate.clamp(0.0, 1.0);
    
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: percentage * 100,
                    title: '${(percentage * 100).toInt()}%',
                    color: theme.colorScheme.primary,
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: (1 - percentage) * 100,
                    title: '',
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.weeklyTaskCompletion,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.tasksCompletedThisWeek(data.completedTasks, data.totalTasks),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

