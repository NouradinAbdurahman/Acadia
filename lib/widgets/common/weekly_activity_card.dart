import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../components/app_glass_card.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({
    super.key,
    required this.data,
    required this.analytics,
  });

  final Map<int, int> data;
  final StudyAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final totals = analytics.weeklyTotals;
    final change = analytics.weeklyChange;

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weeklyActivity,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (analytics.currentStreak > 0)
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: analytics.streakWarning
                          ? Colors.orange.withValues(alpha: 0.5)
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.streakDays(analytics.currentStreak),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: analytics.streakWarning
                            ? Colors.orangeAccent.withValues(alpha: 0.6)
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (analytics.streakWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.streakWarningMessage,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final minutes = spot.y.toInt();
                        final label = minutes >= 60
                            ? '${(minutes / 60).toStringAsFixed(1)}h'
                            : '$minutes min';
                        return LineTooltipItem(
                          label,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 30,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        if (value % 60 == 0) {
                          return Text(
                            '${(value / 60).toInt()}h',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white38,
                            ),
                          );
                        }
                        return Text(
                          '${value.toInt()}m',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white12,
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1.0,
                      getTitlesWidget: (value, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final int val = value.toInt();
                        if (val < 1 || val > 7) return const SizedBox();
                        final isToday = DateTime.now().weekday == val;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[val - 1],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : Colors.white38,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.entries
                        .map(
                          (e) => FlSpot(e.key.toDouble(), e.value.toDouble()),
                        )
                        .toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final maxVal = data.values.fold(
                          0,
                          (max, v) => v > max ? v : max,
                        );
                        final isPeak = spot.y == maxVal && maxVal > 0;
                        return FlDotCirclePainter(
                          radius: isPeak ? 5 : 3,
                          color: isPeak
                              ? theme.colorScheme.primary
                              : Colors.white24,
                          strokeWidth: isPeak ? 2 : 1,
                          strokeColor: isPeak ? Colors.white : Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minX: 1,
                maxX: 7,
                minY: 0,
                maxY: (data.values.fold(0, (max, v) => v > max ? v : max) < 60
                        ? 60
                        : data.values.fold(0, (max, v) => v > max ? v : max) + 30)
                    .toDouble(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: Colors.white10),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thisWeekLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analytics.formatDuration(totals['thisWeek']!),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.preivousWeekLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analytics.formatDuration(totals['lastWeek']!),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (change == -1
                              ? Colors.blue
                              : (change >= 0 ? Colors.green : Colors.red))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      change == -1
                          ? Icons.star
                          : (change >= 0
                                ? Icons.trending_up
                                : Icons.trending_down),
                      size: 14,
                      color: change == -1
                          ? Colors.blueAccent
                          : (change >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change == -1
                          ? l10n.newWeekStart
                          : '${change.abs().toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: change == -1
                            ? Colors.blueAccent
                            : (change >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            analytics.getWeeklyStatus(l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.weeklyProgressLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      l10n.newBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: analytics.weeklyGoalProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    l10n.weeklyGoalProgressHours(
                      analytics.formatDuration(analytics.weeklyTotals['thisWeek']!),
                      '${(analytics.weeklyGoalMinutes / 60).toInt()}h',
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.activeDaysCount(data.values.where((v) => v > 0).length),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('•', style: TextStyle(color: Colors.white24)),
                  ),
                  Text(
                    l10n.peakDayLabel(analytics.getPeakDay(l10n)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white10),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (analytics.streakWarning
                          ? Colors.orange
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  analytics.streakWarning
                      ? Icons.priority_high
                      : Icons.auto_awesome,
                  color: analytics.streakWarning
                      ? Colors.orange
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analytics.streakWarning ? l10n.streakAtRisk : l10n.studyHabit,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      analytics.getStreakMessage(l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
