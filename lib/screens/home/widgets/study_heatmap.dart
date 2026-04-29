// ignore_for_file: deprecated_member_use, unnecessary_underscores, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../components/app_glass_card.dart';
import '../../../providers/study_heatmap_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../models/heatmap_day.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class StudyHeatmap extends ConsumerStatefulWidget {
  const StudyHeatmap({super.key});

  @override
  ConsumerState<StudyHeatmap> createState() => _StudyHeatmapState();
}

class _StudyHeatmapState extends ConsumerState<StudyHeatmap> {
  late final ScrollController _scrollController;
  // Tracks whether the previous frame was in a loading state, so we can
  // detect the loading→data transition and re-scroll to the current month.
  bool _wasLoading = false;
  HeatmapData? _lastHeatmapData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Scroll to today (far right) on first render.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heatmapAsync = ref.watch(studyHeatmapProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    // Re-scroll to current month whenever a refresh completes (loading → data).
    final isNowLoading = heatmapAsync.isLoading;
    if (_wasLoading && !isNowLoading && heatmapAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
    _wasLoading = isNowLoading;

    final theme = Theme.of(context);

    if (heatmapAsync.hasValue && heatmapAsync.value != null) {
      _lastHeatmapData = heatmapAsync.value;
    }

    final data = heatmapAsync.value ?? _lastHeatmapData;

    if (data == null) {
      // First load empty state, the global shimmer will wrap this.
      return const SizedBox(height: 250);
    }

    final days = data.days;
    if (days.isEmpty) return _buildEmptyState(context);

    final streak = dashboardAsync.value?.streakCount ?? 0;
    final maxScore = data.maxScore;

    return AppGlassCard(
      borderOnly: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, streak),
          const SizedBox(height: AppSpacing.md),
          Stack(
            children: [
               Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeekdayLabels(context),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 125,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMonthLabels(context, days),
                                SizedBox(
                                  height: 98,
                                  width: ((days.length / 7).ceil() * 14.5) + 30,
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: 2.5,
                                      crossAxisSpacing: 2.5,
                                    ),
                                    itemCount: days.length,
                                    itemBuilder: (context, index) {
                                      final day = days[index];
                                        return _HeatmapCell(
                                          day: day,
                                          maxScore: maxScore,
                                          index: index,
                                        );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Fade Overlays
              Positioned(
                left: 28,
                top: 0,
                bottom: 0,
                width: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          theme.colorScheme.surface.withOpacity(0.1),
                          theme.colorScheme.surface.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          theme.colorScheme.surface.withOpacity(0.2),
                          theme.colorScheme.surface.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ).animate().fade(duration: 400.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildHeader(BuildContext context, int streak) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.studyActivity,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              l10n.studyIntensitySubtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(
                  isDark ? 0.62 : 0.72,
                ),
                fontWeight: FontWeight.w500,
                fontSize: 9,
              ),
            ),
          ],
        ),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    
    // Get localized weekday names
    final monday = DateFormat.E(locale).format(DateTime(2024, 1, 1)); // Monday
    final wednesday = DateFormat.E(locale).format(DateTime(2024, 1, 3)); // Wednesday
    final friday = DateFormat.E(locale).format(DateTime(2024, 1, 5)); // Friday
    
    final labels = ['', monday, '', wednesday, '', friday, ''];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        ...List.generate(7, (i) {
          final label = labels[i];
          return SizedBox(
            height: 14.5,
            child: label.isEmpty 
              ? const SizedBox.shrink()
              : Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface.withOpacity(
                        isDark ? 0.56 : 0.64,
                      ),
                    ),
                  ),
                ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthLabels(BuildContext context, List<HeatmapDay> days) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<Widget> labels = [];

    final renderedMonthKeys = <String>{};
    for (int i = 0; i < days.length; i += 7) {
      final columnDays = days.sublist(i, (i + 7).clamp(0, days.length));

      DateTime? labelDate;

      // Prefer the column where the month actually starts.
      for (final d in columnDays) {
        if (d.date.day == 1) {
          labelDate = d.date;
          break;
        }
      }

      // Keep the first column labeled, even when it begins mid-month.
      labelDate ??= i == 0 && columnDays.isNotEmpty ? columnDays.first.date : null;

      if (labelDate != null) {
        final monthKey = '${labelDate.year}-${labelDate.month}';
        if (!renderedMonthKeys.add(monthKey)) {
          labels.add(const SizedBox(width: 14.5));
          continue;
        }

        final locale = Localizations.localeOf(context).toString();
        final monthName = DateFormat.MMM(locale).format(labelDate).toUpperCase();
        labels.add(
          SizedBox(
            width: 14.5,
            height: 18,
            child: OverflowBox(
              maxWidth: 40,
              maxHeight: 18,
              alignment: Alignment.centerLeft,
              child: Text(
                monthName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface.withOpacity(
                    isDark ? 0.56 : 0.64,
                  ),
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        );
      } else {
        labels.add(const SizedBox(width: 14.5));
      }
    }

    return Container(
      height: 18,
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: labels,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppGlassCard(
      borderOnly: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.buildStreak,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.buildStreakSubtitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = theme.colorScheme.primary;

    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(l10n.heatmapLegendLess, style: theme.textTheme.labelSmall?.copyWith(fontSize: 7, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.68), letterSpacing: 0.5)),
        const SizedBox(width: 8),
        _legendItem(theme, theme.colorScheme.onSurface.withOpacity(0.06), "0${l10n.min}", context),
        _legendItem(theme, baseColor.withOpacity(0.25), "30${l10n.min}", context),
        _legendItem(theme, baseColor.withOpacity(0.45), "1${l10n.hoursAbbreviation}", context),
        _legendItem(theme, baseColor.withOpacity(0.7), "2${l10n.hoursAbbreviation}", context),
        _legendItem(theme, baseColor, "3${l10n.hoursAbbreviation}+", context),
        const SizedBox(width: 8),
        Text(l10n.heatmapLegendMore, style: theme.textTheme.labelSmall?.copyWith(fontSize: 7, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.68), letterSpacing: 0.5)),
      ],
    );
  }

  Widget _legendItem(ThemeData theme, Color color, String label, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: l10n.heatmapActivityLegendTooltip(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          children: [
            _legendBox(theme, color),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(
                  isDark ? 0.52 : 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendBox(ThemeData theme, Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05), width: 0.5),
      ),
    );
  }


}

class _HeatmapCell extends StatelessWidget {
  final HeatmapDay day;
  final int maxScore;
  final int index;
  
  const _HeatmapCell({
    required this.day, 
    required this.maxScore,
    required this.index,
  });

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    if (day.score == 0) return theme.colorScheme.onSurface.withOpacity(0.06);
    final primary = theme.colorScheme.primary;
    
    final double ratio = day.score / maxScore;
    double opacity;
    if (ratio < 0.2) {
      opacity = 0.25;
    } else if (ratio < 0.5) opacity = 0.45;
    else if (ratio < 0.8) opacity = 0.75;
    else opacity = 1.0;
    
    return primary.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDay = DateTime(day.date.year, day.date.month, day.date.day);
    final isFuture = normalizedDay.isAfter(today);
    
    return GestureDetector(
      onTap: isFuture ? null : () {
        Haptics.vibrate(HapticsType.selection);
        _showDetails(context);
      },
      child: Opacity(
        opacity: isFuture ? 0.2 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.04),
              width: 0.5,
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMMEEEEd(locale).format(day.date);

    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
      barrierColor: theme.colorScheme.shadow.withValues(alpha: 0.45),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark ? AppGradients.darkBackground : AppGradients.lightBackground,
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    dateStr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Divider(
                    height: 32,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                  if (day.score > 0)
                    _highlightStat(context, Icons.check_circle, l10n.goodConsistency,
                        theme.colorScheme.primary),
                  _infoRow(context, l10n.activity, l10n.studySession),
                  _infoRow(context, l10n.duration, l10n.minutesShort(day.totalMinutes)),
                  _infoRow(context, l10n.sessions, '${day.sessionsCount}'),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _highlightStat(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 12), Text(text, style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

