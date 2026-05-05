import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_colors.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../widgets/semester/semester_comparison_card.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../domain/decision/decision_rules.dart';
import '../../providers/decision_engine_provider_v2.dart';
import '../../providers/study_sessions_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/trend_provider.dart';
import '../../core/utils/trend_localizer.dart';
import '../../providers/mood_provider.dart';
import '../../providers/decision_provider.dart';
import '../../providers/adaptive_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../models/analytics_data.dart';
import '../../models/course.dart';
import '../../models/trend_data.dart';
import '../../models/mood_log.dart';
import '../../domain/decision/decision_result.dart';
import '../../domain/decision/decision_insights.dart';
import '../../domain/prediction/prediction_result.dart';
import '../../widgets/analytics/decision_cards.dart';
import '../../widgets/common/weekly_activity_card.dart';
import '../../widgets/risk/risk_widgets.dart';
import '../../widgets/ai/academic_assistant_insight_block.dart';
import '../../widgets/ai/ai_sparkle_hint.dart';
import '../../services/ai/academic_insight_layer.dart';
import '../../widgets/ai/insight_display_variant.dart';
import '../../providers/risk_provider.dart';
import '../../widgets/mood/mood_daily_list.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _trendsSectionKey = GlobalKey();
  bool _showTrendDetails = false;

  int _roundPlanMinutes(double minutes) {
    if (minutes <= 0) return 0;
    return ((minutes / 5).ceil() * 5).clamp(5, 240);
  }

  Widget _buildMoodSourceTabs(WidgetRef ref, ThemeData theme, String currentSource) {
    final l10n = AppLocalizations.of(ref.context)!;
    return RepaintBoundary(
      child: Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMoodStressTabItem(
              label: l10n.dailyBaseline,
              isSelected: currentSource == 'daily',
              theme: theme,
              accentColor: AppColors.moodSourceDailyAccent,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                ref.read(moodChartSourceProvider.notifier).state = 'daily';
              },
            ),
          ),
          Expanded(
            child: _buildMoodStressTabItem(
              label: l10n.studySessions,
              isSelected: currentSource == 'session',
              theme: theme,
              accentColor: AppColors.moodSourceSessionAccent,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                ref.read(moodChartSourceProvider.notifier).state = 'session';
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Same visual pattern as Mood History “Filter by source” tabs.
  Widget _buildMoodStressTabItem({
    required String label,
    required bool isSelected,
    required ThemeData theme,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Static container — AnimatedContainer lerps transparent↔surface and causes visible flicker.
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.cardColor : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? accentColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendDaysTabs(WidgetRef ref, ThemeData theme, int trendDays) {
    final l10n = AppLocalizations.of(ref.context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.14 : 0.16,
          ),
        ),
      ),
      child: Row(
        children: [7, 14, 30].map((days) {
          return Expanded(
            child: _buildTrendDaysTab(
              label: l10n.daysFilter(days),
              isSelected: trendDays == days,
              theme: theme,
              onTap: () {
                Haptics.vibrate(HapticsType.selection);
                ref.read(trendDaysProvider.notifier).state = days;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendDaysTab({
    required String label,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _startStudyFromDecision({
    required String courseId,
    required int minutes,
  }) {
    final timerState = ref.read(studyTimerProvider);
    final timer = ref.read(studyTimerProvider.notifier);

    // If a session is already running, only navigate to Study tab.
    if (timerState.isRunning || timerState.isPaused) {
      ref.read(bottomNavProvider.notifier).state = 2;
      return;
    }

    if (courseId.isEmpty) {
      ref.read(bottomNavProvider.notifier).state = 2;
      return;
    }

    // Analytics recommendations should always execute in Focus mode.
    // Manual Study screen starts keep their existing behavior.
    timer.setStudyType(StudyType.deepWork);
    timer.setIntent('analytics_recommendation');
    timer.setCourseId(courseId);
    timer.setDuration(Duration(minutes: minutes));
    timer.start();
    ref.read(bottomNavProvider.notifier).state = 2;
  }

  void _scrollToTrendsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _trendsSectionKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(analyticsJumpToTrendsTokenProvider, (previous, next) {
      if (previous != next) _scrollToTrendsSection();
    });

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(analyticsProvider);
    final studyAnalytics = ref.watch(studyAnalyticsProvider);
    final trendDays = ref.watch(trendDaysProvider);
    final trendAsync = ref.watch(trendProvider(trendDays));
    final moodSource = ref.watch(moodChartSourceProvider);
    final moodLogsAsync = moodSource == 'daily' 
        ? ref.watch(dailyMoodLogsProvider) 
        : ref.watch(sessionMoodLogsProvider);
    final moodTrendDays = ref.watch(moodTrendDaysProvider);
    final courses = ref.watch(courseProvider).valueOrNull ?? const <Course>[];
    final sessions = ref.watch(studySessionsProvider).valueOrNull ?? const [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
    final decision = ref.watch(decisionProvider);
    final prediction = ref.watch(predictionProvider);

    final semesterId = ref.watch(activeSemesterProvider).value;

    return Scaffold(
      key: Key('analytics_screen_${semesterId ?? 'none'}'),
      backgroundColor: Colors.transparent,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: analyticsAsync.when(
            data: (data) {
              final hasData = data.hasData;

              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  24,
                  AppSpacing.md,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.analytics,
                      style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                    ).animate().fade().slideX(begin: -0.1),
                    const SizedBox(height: AppSpacing.xl),

                    // --- MOVED FROM HOME ---
                    if (hasData && decision.hasContent) ...[
                      _buildDecisionInsightsCard(context, ref, theme, l10n, decision, studyAnalytics),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    if (hasData && decision.hasContent && prediction.hasData) ...[
                      _StudyProfileCard(studyAnalytics: studyAnalytics),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        height: AppSpacing.md,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],

                    if (hasData && prediction.hasData) ...[
                      _buildPredictedStressCard(context, theme, l10n, prediction),
                      const SizedBox(height: AppSpacing.md),
                      _buildRecommendedPlanCard(context, theme, l10n, prediction),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (hasData) ...[
                      const SemesterComparisonCard(),
                      if (!decision.hasContent &&
                          !ref.watch(riskProvider).hasData) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppGlassCard(
                          borderOnly: true,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: const AcademicAssistantInsightBlock(
                            variant: InsightDisplayVariant.full,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    // -------------------------
                    if (!hasData) ...[
                      AppGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroIcon(
                              HeroIcons.presentationChartLine,
                              size: 48,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.analyticsSparseDataTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.analyticsSparseDataBody,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              onPressed: () {
                                Haptics.vibrate(HapticsType.selection);
                                if (courses.isEmpty) {
                                  context.push('/courses');
                                  return;
                                }
                                if (sessions.isEmpty) {
                                  ref.read(bottomNavProvider.notifier).state = 2;
                                  context.go('/home');
                                  return;
                                }
                                ref.read(bottomNavProvider.notifier).state = 1;
                                if (tasks.isEmpty) {
                                  context.push('/create-task');
                                  return;
                                }
                                context.go('/home');
                              },
                              icon: HeroIcon(
                                courses.isEmpty
                                    ? HeroIcons.academicCap
                                    : (sessions.isEmpty
                                        ? HeroIcons.play
                                        : HeroIcons.clipboardDocumentCheck),
                                size: 18,
                              ),
                              label: Text(
                                courses.isEmpty
                                    ? l10n.manageCourses
                                    : (sessions.isEmpty
                                        ? l10n.startStudySession
                                        : l10n.createTask),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.whatYouCanTrack,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EmptyStateBulletRow(
                              icon: HeroIcons.checkCircle,
                              text: l10n.trackTasks,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _EmptyStateBulletRow(
                              icon: HeroIcons.checkCircle,
                              text: l10n.trackStudySessions,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _EmptyStateBulletRow(
                              icon: HeroIcons.checkCircle,
                              text: l10n.trackGrades,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.whyItMatters,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EmptyStateBulletRow(
                              icon: HeroIcons.sparkles,
                              text: l10n.monitorProgress,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _EmptyStateBulletRow(
                              icon: HeroIcons.shieldCheck,
                              text: l10n.reduceAcademicRisk,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ] else ...[
                      if (ref.watch(riskProvider).hasData) ...[
                        _buildSectionTitle(theme, l10n.academicRisk),
                        const SizedBox(height: AppSpacing.md),
                        const RiskBreakdownCard(),
                        if (!decision.hasContent) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppGlassCard(
                            borderOnly: true,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: const AcademicAssistantInsightBlock(
                              variant: InsightDisplayVariant.full,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      _buildSectionTitle(theme, l10n.moodAndStressTitle),
                      const SizedBox(height: AppSpacing.sm),
                      _buildMoodSourceTabs(ref, theme, moodSource),
                      const SizedBox(height: AppSpacing.md),
                      AppGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MoodMetricTile(
                                  title: l10n.moodAverageLabel,
                                  value: moodSource == 'daily'
                                      ? (data.dailyMoodLogCount == 0 ? l10n.moodNoData : data.avgDailyMood.toStringAsFixed(1))
                                      : (data.sessionMoodLogCount == 0 ? l10n.moodNoData : data.avgSessionMood.toStringAsFixed(1)),
                                  icon: HeroIcons.faceSmile,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _MoodMetricTile(
                                  title: l10n.stressAverageLabel,
                                  value: moodSource == 'daily'
                                      ? (data.dailyMoodLogCount == 0 ? l10n.moodNoData : data.avgDailyStress.toStringAsFixed(1))
                                      : (data.sessionMoodLogCount == 0 ? l10n.moodNoData : data.avgSessionStress.toStringAsFixed(1)),
                                  icon: HeroIcons.bolt,
                                ),
                              ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.moodOverLastDays(moodTrendDays),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                Theme(
                                  data: theme.copyWith(
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                  ),
                                  child: PopupMenuButton<int>(
                                    offset: const Offset(0, 36),
                                    elevation: 8,
                                    shadowColor: Colors.black26,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    color: theme.colorScheme.surface,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.daysFilter(moodTrendDays),
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (context) => [7, 14, 30].map((days) {
                                      final isSelected = days == moodTrendDays;
                                      return PopupMenuItem<int>(
                                        value: days,
                                        height: 44,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l10n.daysFilter(days),
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: isSelected 
                                                      ? theme.colorScheme.primary 
                                                      : theme.colorScheme.onSurface,
                                                  fontWeight: isSelected 
                                                      ? FontWeight.w700 
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: theme.colorScheme.primary,
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onSelected: (value) {
                                      Haptics.vibrate(HapticsType.selection);
                                      ref.read(moodTrendDaysProvider.notifier).state = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _MoodTrendChart(
                              moodLogsAsync: moodLogsAsync,
                              days: moodTrendDays,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MoodDailyList(
                              moodLogsAsync: moodLogsAsync,
                              days: moodTrendDays,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.historicalConsistencyScoreLine(
                                  (100 - studyAnalytics.timeInconsistencyScore).round(),
                                  studyAnalytics.consistencyTrendLabel,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      const BurnoutStatusCard(),
                      const SizedBox(height: AppSpacing.xl),

                      if (studyAnalytics.moodDurationImpactDetails['hasEnoughData'] as bool) ...[
                        _buildMoodVsStudyCard(theme, l10n, decision, studyAnalytics),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // 1. Study Hours by Course
                      _buildSectionTitle(theme, l10n.studyHoursByCourse,
                          showAiHint: true),
                      Text(l10n.thisWeekLabel, style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                      _StudyHoursBarChart(data: data),
                      const SizedBox(height: AppSpacing.lg),
                      WeeklyActivityCard(
                        data: studyAnalytics.weeklyMinutes,
                        analytics: studyAnalytics,
                      ),
                      const SizedBox(height: AppSpacing.xl),





                      // 4. Trend Analysis
                      KeyedSubtree(
                        key: _trendsSectionKey,
                        child: _buildSectionTitle(theme, l10n.trendAnalysis,
                            showAiHint: true),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTrendDaysTabs(ref, theme, trendDays),
                      const SizedBox(height: AppSpacing.md),
                      trendAsync.when(
                        data: (trend) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _TrendAnalysisSection(
                            key: ValueKey('trend-$trendDays'),
                            trend: trend,
                            data: data,
                            studyAnalytics: studyAnalytics,
                            showDetails: _showTrendDetails,
                            onToggleDetails: () => setState(() => _showTrendDetails = !_showTrendDetails),
                          ),
                        ),
                        loading: () => const AppGlassCard(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, s) => AppGlassCard(
                          height: 120,
                          child: Center(child: Text(l10n.networkError)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
            loading: () => _analyticsLoadingSkeleton(theme),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
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

  // --- HELPER METHODS MOVED FROM HOME ---

  Widget _buildDecisionInsightsCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    DecisionResult decision,
    StudyAnalytics studyAnalytics,
  ) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final riskState = ref.watch(riskProvider);
    final signature = decision.sortedItems
        .map((item) => '${item.priority}:${item.title}')
        .join('|');
    final primary = decision.primaryDecision;
    if (primary == null) {
      return const SizedBox.shrink();
    }

    final analyticsData = analyticsAsync.valueOrNull;
    final adaptive = ref.read(adaptiveProfileProvider);
    final layerParts = (analyticsData != null && analyticsData.hasData)
        ? AcademicInsightInput.fromAnalytics(
            data: analyticsData,
            riskScoreOverride: riskState.hasData
                ? riskState.result.totalScore
                : analyticsData.riskScore,
            riskTrendDelta: riskState.hasData ? riskState.trendDelta : null,
            adaptiveProfile: adaptive,
            burnoutRisk: studyAnalytics.burnoutScore,
          ).parts
        : null;

    final recoLines = layerParts == null
        ? const <String>[]
        : layerParts.recommendation
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return AppGlassCard(
      key: ValueKey('decision-$signature'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(HeroIcons.sparkles, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.decisionSmartInsights,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (layerParts != null) ...[
            Text(
              l10n.aiInsightPrimaryReasonLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              layerParts.insight,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiInsightWhatToDoLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 4),
            if (recoLines.isNotEmpty)
              Text(
                recoLines.first,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            if (recoLines.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                recoLines[1],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiInsightConfidenceHeading,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.decisionConfidenceWord(decision.confidence),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            Text(
              l10n.basedOnSessions(studyAnalytics.trackedSessionCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ] else ...[
            _buildPrimaryDecisionBlock(context, theme, l10n, primary),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Start ${_resolvedDecisionMinutes(ref, decision.suggestedSessionMinutes)} min session',
              onPressed: () => _startNowFromDecision(
                context,
                ref,
                decision.suggestedSessionMinutes,
              ),
              icon: const AppIcon(HeroIcons.play, size: 16, color: Colors.white),
            ),
          ),
          if (decision.suggestedSessionMinutes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.decisionRecommendedSession(decision.suggestedSessionMinutes!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    ).animate().scaleXY(begin: 0.98, end: 1.0, duration: 260.ms).fadeIn();
  }

  Widget _buildPrimaryDecisionBlock(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DecisionItem item,
  ) {
    final isPriorityOne = item.priority == 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isPriorityOne
            ? theme.colorScheme.error.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPriorityOne
              ? theme.colorScheme.error.withValues(alpha: 0.25)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.focusRecommendationPrimary,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPriorityOne ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankedFactorRow(ThemeData theme, AppLocalizations l10n, String text, {bool isMain = false}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: isMain ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isMain ? FontWeight.w800 : FontWeight.w600,
            color: isMain ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalChip(ThemeData theme, AppLocalizations l10n, String signal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Text(
        signal,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildStatBadge(ThemeData theme, String text, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning 
            ? theme.colorScheme.error.withValues(alpha: 0.1) 
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isWarning 
              ? theme.colorScheme.error.withValues(alpha: 0.2) 
              : theme.colorScheme.primary.withValues(alpha: 0.2)
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isWarning ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPriorityDecisionItem(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DecisionItem item,
  ) {
    final isPriorityOne = item.priority == 1;
    final icon = switch (item.type) {
      DecisionType.warning => HeroIcons.exclamationTriangle,
      DecisionType.recommendation => HeroIcons.lightBulb,
      DecisionType.insight => HeroIcons.chartBar,
    };
    final color = isPriorityOne
        ? theme.colorScheme.error
        : (item.type == DecisionType.warning
            ? theme.colorScheme.error.withValues(alpha: 0.7)
            : theme.colorScheme.primary);

    final title = item.title;
    final action = item.description;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isPriorityOne
              ? theme.colorScheme.error.withValues(alpha: 0.08)
              : theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isPriorityOne
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (action.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveDecisionTitle(AppLocalizations l10n, String message) {
    return message;
  }

  String _resolveDecisionAction(AppLocalizations l10n, String message) {
    final key = message.split('|').first;
    switch (key) {
      case 'decision_high_stress':
      case 'decision_short_sessions':
        return l10n.decisionActionShortSessions;
      case 'decision_deadline_pressure':
        return l10n.decisionActionBreakDown;
      case 'decision_stress_rising':
      case 'decision_mood_declining':
        return l10n.decisionActionMonitorWeekly;
      case 'decision_morning_planning':
        return l10n.decisionActionPlanning;
      case 'decision_afternoon_execution':
        return l10n.decisionActionExecution;
      case 'decision_night_light_review':
        return l10n.decisionActionLightReview;
      case 'decision_burnout_duration_cap':
        return l10n.decisionActionShortSessions;
      case 'decision_fixed_schedule':
        return l10n.decisionActionFixedSchedule;
      default:
        return '';
    }
  }

  String _confidenceLabel(AppLocalizations l10n, double confidence) {
    if (confidence >= 0.75) {
      return l10n.decisionConfidenceHigh;
    }
    if (confidence >= 0.45) {
      return l10n.decisionConfidenceMedium;
    }
    return l10n.decisionConfidenceLow;
  }

  void _startNowFromDecision(
    BuildContext context,
    WidgetRef ref,
    int? suggestedMinutes,
  ) {
    final minutes = _resolvedDecisionMinutes(ref, suggestedMinutes);
    final timerState = ref.read(studyTimerProvider);
    final timer = ref.read(studyTimerProvider.notifier);

    // 1. Update Timer State
    timer.setDuration(Duration(minutes: minutes));
    if (timerState.courseId != null) {
      timer.start();
    }

    // 2. Switch Tab first
    ref.read(bottomNavProvider.notifier).state = 2;

    // 3. Navigation with Extra (Requested Audit requirement)
    context.go('/app', extra: {
      'duration': minutes,
      'source': 'analytics',
    });
  }

  int _resolvedDecisionMinutes(WidgetRef ref, int? _) {
    final analytics = ref.read(analyticsProvider).valueOrNull;
    final studyAnalytics = ref.read(studyAnalyticsProvider);
    final adaptive = ref.read(adaptiveProfileProvider);
    return DecisionRules.getFinalRecommendedMinutes(
      consistency: analytics?.consistency ?? 1.0,
      stress: analytics?.avgSessionStress ?? 0.0,
      profile: adaptive,
      burnoutRisk: studyAnalytics.burnoutScore,
    );
  }

  Widget _buildPredictedStressCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    PredictionResult prediction,
  ) {
    final levelText = switch (prediction.stressLevel) {
      PredictionLevel.low => l10n.predictionLevelLow,
      PredictionLevel.medium => l10n.predictionLevelMedium,
      PredictionLevel.high => l10n.predictionLevelHigh,
    };

    final levelColor = switch (prediction.stressLevel) {
      PredictionLevel.low => Colors.green,
      PredictionLevel.medium => Colors.orange,
      PredictionLevel.high => theme.colorScheme.error,
    };

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.predictionStressTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIcon(HeroIcons.chartBar, color: levelColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  levelText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (prediction.stressReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.predictionMainReasonTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...prediction.stressReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $reason',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendedPlanCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    PredictionResult prediction,
  ) {
    final timeLabel = MaterialLocalizations.of(context);
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: prediction.recommendedPlan.map((item) {
              final day = _relativeDayLabel(l10n, item.scheduledAt);
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.predictionPlanLineSimple(
                    day,
                    item.durationMinutes,
                    item.focusKey,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  String _relativeDayLabel(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final delta = day.difference(today).inDays;
    if (delta == 0) return l10n.today;
    if (delta == 1) return l10n.tomorrow;
    return DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(date);
  }

  String _predictionRiskLine(AppLocalizations l10n, PredictionResult prediction) {
    final level = switch (prediction.performanceRiskLevel) {
      PredictionLevel.low => l10n.predictionLevelLow,
      PredictionLevel.medium => l10n.predictionLevelMedium,
      PredictionLevel.high => l10n.predictionLevelHigh,
    };
    return l10n.predictionPerformanceRisk(level);
  }

  Widget _buildPredictionRiskSection(
    ThemeData theme,
    AppLocalizations l10n,
    PredictionResult prediction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _predictionRiskLine(l10n, prediction),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (prediction.laggingCourses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.predictionAffectedTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 2),
          ...prediction.laggingCourses.map(
            (course) => Text(
              '• $course',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _factorLabel(AppLocalizations l10n, String raw) {
    switch (raw.toLowerCase()) {
      case 'sleep':
        return l10n.moodFactorSleep;
      case 'workload':
        return l10n.moodFactorWorkload;
      case 'health':
        return l10n.moodFactorHealth;
      case 'motivation':
        return l10n.moodFactorMotivation;
      case 'social':
        return l10n.moodFactorSocial;
      case 'exams':
        return l10n.moodFactorExams;
      default:
        return raw.isEmpty ? '-' : '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
  }

  String _weekdayNameFromInt(String? value) {
    final weekday = int.tryParse(value ?? '');
    if (weekday == null || weekday < DateTime.monday || weekday > DateTime.sunday) {
      return '-';
    }

    final now = DateTime.now();
    final date = now.subtract(Duration(days: now.weekday - weekday));
    return DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(date);
  }

  Widget _buildSectionTitle(ThemeData theme, String title,
      {bool showAiHint = false}) {
    if (!showAiHint) {
      return Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const AiSparkleHint(size: 15),
      ],
    );
  }

  Widget _analyticsLoadingSkeleton(ThemeData theme) {
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;
    Widget line(double h, {double width = double.infinity}) {
      return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          height: h,
          width: width,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(28, width: 160),
          const SizedBox(height: AppSpacing.xl),
          line(20, width: 120),
          const SizedBox(height: AppSpacing.md),
          line(140),
          const SizedBox(height: AppSpacing.xl),
          line(20, width: 140),
          const SizedBox(height: AppSpacing.md),
          line(180),
          const SizedBox(height: AppSpacing.xl),
          line(20, width: 100),
          const SizedBox(height: AppSpacing.md),
          line(100),
        ],
      ),
    );
  }

  Widget _buildSmallMetricBadge(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMoodVsStudyCard(ThemeData theme, AppLocalizations l10n, DecisionResult decision, StudyAnalytics studyAnalytics) {
    final details = studyAnalytics.moodDurationImpactDetails;
    final hasEnoughData = details['hasEnoughData'] as bool;
    final impact = details['impact'] as int;
    final mood = decision.avgMood;
    final isMoodGood = mood >= 3.5;
    final isMoodBad = mood <= 2.5;

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(HeroIcons.presentationChartLine, color: Colors.blueAccent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.analyticsMoodPerformanceTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            !hasEnoughData 
               ? l10n.analyticsNotEnoughData
               : (isMoodGood
                    ? l10n.analyticsMoodPerformanceGoodDesc
                    : (isMoodBad
                        ? l10n.analyticsMoodPerformanceBadDesc
                        : l10n.analyticsMoodPerformanceStableDesc)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.analyticsMoodBetterMood, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      hasEnoughData ? l10n.analyticsImpactPositive(impact) : l10n.analyticsNotEnoughData, 
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.greenAccent,
                        fontSize: hasEnoughData ? 20 : 10,
                      ),
                    ),
                    Text(l10n.analyticsMoodFocusBoost, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 16), // Adjusted spacing
                    Text(
                      hasEnoughData ? l10n.analyticsImpactNegative(impact + 5) : l10n.analyticsNotEnoughData, 
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.redAccent,
                        fontSize: hasEnoughData ? 20 : 10,
                      ),
                    ),
                    Text(l10n.analyticsMoodFocusDrain, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveStatusKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'decisionStatusHighStress':
        return l10n.decisionStatusHighStress;
      case 'decisionStatusModerateStress':
        return l10n.decisionStatusModerateStress;
      case 'decisionStatusLowStress':
        return l10n.decisionStatusLowStress;
      case 'statusStable':
        return l10n.statusStable;
      case 'decisionStatusDeficit':
        return l10n.decisionStatusDeficit;
      case 'decisionStatusInconsistent':
        return l10n.decisionStatusInconsistent;
      default:
        return key;
    }
  }
}

class _MoodMetricTile extends StatelessWidget {
  const _MoodMetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final HeroIcons icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendChart extends StatelessWidget {
  const _MoodTrendChart({
    required this.moodLogsAsync,
    required this.days,
  });

  final AsyncValue<List<MoodLog>> moodLogsAsync;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return moodLogsAsync.when(
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 140,
        child: Center(child: Text(l10n.networkError)),
      ),
      data: (logs) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final values = <double>[];

        for (var i = days - 1; i >= 0; i--) {
          final day = today.subtract(Duration(days: i));
          final sameDay = logs.where((entry) {
            final d = DateTime(
              entry.createdAt.year,
              entry.createdAt.month,
              entry.createdAt.day,
            );
            return d == day;
          }).toList();

          if (sameDay.isEmpty) {
            values.add(0.0);
          } else {
            final sum = sameDay
                .map((entry) => entry.moodLevel)
                .reduce((a, b) => a + b);
            values.add(sum / sameDay.length);
          }
        }

        final hasData = values.any((value) => value > 0);
        if (!hasData) {
          return SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.moodNoData,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.startTrackingToSeeTrends,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final dataPoints = values.where((value) => value > 0).length;
        if (dataPoints < 2) {
          return SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.moodKeepLogging,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.moodTrendNeedsData,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bars = <LineChartBarData>[];
        var currentContiguousSpots = <FlSpot>[];

        for (int i = 0; i < values.length; i++) {
          if (values[i] > 0) {
            currentContiguousSpots.add(FlSpot(i.toDouble(), values[i]));
          } else {
            if (currentContiguousSpots.isNotEmpty) {
              bars.add(_buildBarData(currentContiguousSpots, theme));
              currentContiguousSpots = [];
            }
          }
        }
        if (currentContiguousSpots.isNotEmpty) {
          bars.add(_buildBarData(currentContiguousSpots, theme));
        }

        return SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: days - 1.0,
              minY: 1,
              maxY: 5,
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days) return const SizedBox.shrink();
                      
                      final interval = days >= 30 ? 5 : (days >= 14 ? 2 : 1);
                      if (index % interval != 0 && index != days - 1) {
                        return const SizedBox.shrink();
                      }
                      
                      final daysAgo = (days - 1) - index;
                      final date = DateTime.now().subtract(Duration(days: daysAgo));
                      final label = DateFormat.E(Localizations.localeOf(context).languageCode).format(date);
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: bars,
            ),
          ),
        );
      },
    );
  }

  LineChartBarData _buildBarData(List<FlSpot> spots, ThemeData theme) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: _getMoodChartColor(spots),
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, line, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: _getMoodLevelColor(spot.y, theme),
            strokeColor: theme.colorScheme.surface,
            strokeWidth: 2,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getMoodChartColor(spots).withValues(alpha: 0.2),
            _getMoodChartColor(spots).withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }

  Color _getMoodChartColor(List<FlSpot> spots) {
    if (spots.isEmpty) return Colors.grey;
    final avgMood = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    return _getMoodLevelColor(avgMood, null);
  }

  Color _getMoodLevelColor(double moodLevel, ThemeData? theme) {
    if (moodLevel < 1.5) return Colors.red.shade400;
    if (moodLevel < 2.5) return Colors.orange.shade400;
    if (moodLevel < 3.5) return Colors.yellow.shade600;
    if (moodLevel < 4.5) return Colors.green.shade400;
    return Colors.green.shade600;
  }
}

class _EmptyStateBulletRow extends StatelessWidget {
  const _EmptyStateBulletRow({required this.icon, required this.text});

  final HeroIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HeroIcon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendAnalysisSection extends StatelessWidget {
  const _TrendAnalysisSection({
    super.key,
    required this.trend,
    required this.data,
    required this.studyAnalytics,
    required this.showDetails,
    required this.onToggleDetails,
  });

  final TrendData trend;
  final AnalyticsData data;
  final StudyAnalytics studyAnalytics;
  final bool showDetails;
  final VoidCallback onToggleDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrendSummaryCard(trend: trend),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: onToggleDetails,
          icon: Icon(
            showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 20,
          ),
          label: Text(
            showDetails ? l10n.hideDetails : l10n.viewFullAnalysis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (showDetails) ...[
          const SizedBox(height: AppSpacing.sm),
          _OverallStatusCard(
            trend: trend,
            riskScore: data.riskScore,
            consistency: studyAnalytics.historicalConsistency,
          ),
          const SizedBox(height: 20),
          AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16),
                      SizedBox(width: 6),
                      Text(l10n.studyTrend),
                    ],
                  ),
                  Text(
                    l10n.trendTodayDuration(
                      _formatDurationFromHours(
                        _latestDouble(trend.studyTrend),
                        l10n,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trendStudySubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: _TrendLineChart(
                  data: trend.studyTrend,
                  valueSuffix: l10n.hoursAbbreviation,
                  emptyMessage: l10n.trendStudyEmptyMessage,
                  useDurationLabels: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, size: 16),
                      SizedBox(width: 6),
                      Text(l10n.taskCompletionTrend),
                    ],
                  ),
                  Text(
                    l10n.trendCompletedToday(_latestInt(trend.taskTrend)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trendTaskSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: _TrendBarChart(data: trend.taskTrend, valueSuffix: ''),
              ),
              if (_activeDaysCount(trend.taskTrend) <= 2 &&
                  trend.taskTrend.values.fold<int>(
                        0,
                        (sum, value) => sum + value,
                      ) >
                      0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.trendTasksOneDayHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(l10n.workloadTrend),
                    ],
                  ),
                  Text(
                    l10n.trendNewToday(_latestInt(trend.workloadTrend)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trendWorkloadSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: _TrendLineChart(
                  data: trend.workloadTrend.map(
                    (key, value) => MapEntry(key, value.toDouble()),
                  ),
                  valueSuffix: '',
                  minActivePoints: 1,
                  emptyMessage: l10n.trendWorkloadEmptyMessage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, size: 16),
                  SizedBox(width: 6),
                  Text(l10n.performanceTrend),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trendPerformanceSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: _TrendGradeLineChart(points: trend.gradeTrend),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._sortedInsights(trend.insights).map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: switch (insight.type) {
                      InsightType.good => Colors.green,
                      InsightType.warning => Colors.orange,
                      InsightType.critical => Colors.red,
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TrendLocalizer.localizeTitle(l10n, insight),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(TrendLocalizer.localizeMessage(l10n, insight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

  double _latestDouble(Map<DateTime, double> values) {
    if (values.isEmpty) return 0;
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.last.value;
  }

  int _latestInt(Map<DateTime, int> values) {
    if (values.isEmpty) return 0;
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.last.value;
  }

  int _activeDaysCount(Map<DateTime, int> values) {
    return values.values.where((value) => value > 0).length;
  }

  List<TrendInsight> _sortedInsights(List<TrendInsight> insights) {
    int rank(InsightType type) => switch (type) {
      InsightType.critical => 0,
      InsightType.warning => 1,
      InsightType.good => 2,
    };
    final sorted = [...insights];
    sorted.sort((a, b) => rank(a.type).compareTo(rank(b.type)));
    return sorted;
  }


  String _formatDurationFromHours(double hoursValue, AppLocalizations l10n) {
    final totalMinutes = (hoursValue * 60).round();
    if (totalMinutes <= 0) return '0${l10n.minutesAbbreviation}';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes${l10n.minutesAbbreviation}';
    if (minutes == 0) return '$hours${l10n.hoursAbbreviation}';
    return '$hours${l10n.hoursAbbreviation} $minutes${l10n.minutesAbbreviation}';
  }
}

class _TrendSummaryCard extends ConsumerWidget {
  const _TrendSummaryCard({required this.trend});

  final TrendData trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyAnalytics = ref.watch(studyAnalyticsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final totalStudyHours = trend.studyTrend.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final totalCompletedTasks = trend.taskTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final totalTasksInRange = _estimatedTotalTasks(trend);
    final totalWorkload = trend.workloadTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final perfLabel = studyAnalytics.trackedSessionCount < 3
        ? l10n.trendNotEnoughData
        : trend.performanceChange.abs() < 0.1
        ? l10n.trendStable
        : trend.performanceChange > 0
        ? l10n.trendImproving
        : l10n.trendDeclining;
    final workloadLabel = _workloadSummaryLabel(trend, l10n);
    final studyLabel = _studySummaryLabel(trend, l10n);
    final tasksLabel = _taskSummaryLabel(trend, l10n);
    final studyColor = _studyColor(theme, trend);
    final tasksColor = _tasksColor(theme, trend);
    final workloadColor = _workloadColor(theme, trend);
    final performanceColor = _performanceColor(theme, trend);
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trendSummaryTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.study}: $studyLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: studyColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            totalStudyHours < 0.5
                ? l10n.trendLessThan30Minutes
                : l10n.trendHoursInPeriod(totalStudyHours.toStringAsFixed(1)),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '${l10n.tasks}: $tasksLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tasksColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (totalTasksInRange > 0)
            Text(
              l10n.trendTasksCompletedFraction(
                totalCompletedTasks,
                totalTasksInRange,
              ),
              style: theme.textTheme.bodySmall,
            ),
          Text(
            '${l10n.workloadTrend}: $workloadLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: workloadColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.trendTasksDeadlinesAdded(totalWorkload),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '${l10n.performanceTrend}: $perfLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: performanceColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (studyAnalytics.isMoodStudyCorrelationDetected) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const AppIcon(HeroIcons.exclamationTriangle, size: 16, color: Colors.orange),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "${l10n.analyticsMoodCorrelationDetected}: "
                      "${l10n.analyticsMoodStudyDropped(studyAnalytics.weeklyChange.abs().toStringAsFixed(0))}, "
                      "${l10n.analyticsMoodMoodDropped(studyAnalytics.moodChangePercent.abs().toStringAsFixed(0))}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            studyAnalytics.getBurnoutShortExplanation(l10n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: studyAnalytics.burnoutLevel == BurnoutLevel.stable 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _signedPercent(double value) {
    final rounded = value.round();
    if (rounded > 0) return '+$rounded%';
    return '$rounded%';
  }

  String _studySummaryLabel(TrendData trend, AppLocalizations l10n) {
    final total = trend.studyTrend.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total < 0.5) return l10n.trendVeryLowActivity;
    if (total < 1) return l10n.trendLowActivity;
    return _signedPercent(trend.studyChangePercent);
  }

  String _taskSummaryLabel(TrendData trend, AppLocalizations l10n) {
    final totalTasks = _estimatedTotalTasks(trend);
    if (totalTasks == 0) return l10n.trendNoTasksCompletedPeriod;
    final percent = (trend.taskCompletionRate * 100).round();
    if (percent <= 0) return l10n.trendNoTasksCompletedPeriod;
    return l10n.trendPercentCompleted(percent);
  }

  String _workloadSummaryLabel(TrendData trend, AppLocalizations l10n) {
    final total = trend.workloadTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (total == 0) return l10n.trendNoWorkload;
    if (trend.workloadChangePercent > 10) return l10n.trendIncreased;
    if (trend.workloadChangePercent < -10) {
      return l10n.trendReducedComparedLastPeriod;
    }
    return l10n.trendStable;
  }

  Color _studyColor(ThemeData theme, TrendData trend) {
    final total = trend.studyTrend.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total < 1) return Colors.orange;
    if (trend.studyChangePercent > 10) return Colors.green;
    if (trend.studyChangePercent < -10) return theme.colorScheme.error;
    return theme.colorScheme.onSurface;
  }

  Color _tasksColor(ThemeData theme, TrendData trend) {
    final percent = (trend.taskCompletionRate * 100).round();
    if (percent >= 60) return Colors.green;
    if (percent > 0) return Colors.orange;
    return theme.colorScheme.error;
  }

  Color _workloadColor(ThemeData theme, TrendData trend) {
    final total = trend.workloadTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (total == 0) return theme.colorScheme.onSurface;
    if (trend.workloadChangePercent > 10) return Colors.orange;
    if (trend.workloadChangePercent < -10) return theme.colorScheme.onSurface;
    return theme.colorScheme.onSurface;
  }

  Color _performanceColor(ThemeData theme, TrendData trend) {
    if (trend.gradeTrend.isEmpty) return theme.colorScheme.onSurface;
    if (trend.performanceChange > 0) return Colors.green;
    if (trend.performanceChange < 0) return theme.colorScheme.error;
    return theme.colorScheme.onSurface;
  }

  int _estimatedTotalTasks(TrendData trend) {
    final completed = trend.taskTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (trend.taskCompletionRate <= 0) return completed == 0 ? 0 : completed;
    return (completed / trend.taskCompletionRate).round();
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({
    required this.data,
    required this.valueSuffix,
    this.emptyMessage,
    this.useDurationLabels = false,
    this.minActivePoints = 1,
  });

  final Map<DateTime, double> data;
  final String valueSuffix;
  final String? emptyMessage;
  final bool useDurationLabels;
  final int minActivePoints;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final activePoints = entries.where((entry) => entry.value > 0).length;
    if (activePoints < minActivePoints) {
      return Center(
        child: Text(
          emptyMessage ?? AppLocalizations.of(context)!.trendStudyEmptyMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    final values = entries.map((entry) => entry.value).toList();
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) + 1;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY <= 4 ? 1 : (maxY / 4),
              getTitlesWidget: (value, meta) => Text(
                useDurationLabels
                    ? _formatDurationFromHours(
                        value,
                        AppLocalizations.of(context)!,
                      )
                    : (valueSuffix.isEmpty
                          ? value.toInt().toString()
                          : '${value.toInt()}$valueSuffix'),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (!_isWholeTick(value)) return const SizedBox.shrink();
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                final step = _xAxisStep(entries.length);
                if (index % step != 0) return const SizedBox.shrink();
                final date = entries[index].key;
                return Text(
                  _formatDayLabel(date, context),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 3),
            ),
            barWidth: 4,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
              ],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDurationFromHours(double hoursValue, AppLocalizations l10n) {
    final totalMinutes = (hoursValue * 60).round();
    if (totalMinutes <= 0) return '0${l10n.minutesAbbreviation}';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes${l10n.minutesAbbreviation}';
    if (minutes == 0) return '$hours${l10n.hoursAbbreviation}';
    return '$hours${l10n.hoursAbbreviation} $minutes${l10n.minutesAbbreviation}';
  }
}

class _TrendBarChart extends StatelessWidget {
  const _TrendBarChart({required this.data, required this.valueSuffix});

  final Map<DateTime, int> data;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalCompleted = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    if (totalCompleted == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.trendTaskEmptyMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    final values = entries.map((entry) => entry.value).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble() + 1;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY <= 4 ? 1 : (maxY / 4),
              getTitlesWidget: (value, meta) => Text(
                valueSuffix.isEmpty
                    ? value.toInt().toString()
                    : '${value.toInt()}$valueSuffix',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (!_isWholeTick(value)) return const SizedBox.shrink();
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                final step = _xAxisStep(entries.length);
                if (index % step != 0) return const SizedBox.shrink();
                final date = entries[index].key;
                return Text(
                  _formatDayLabel(date, context),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
        ),
        barGroups: values
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    width: 12,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TrendGradeLineChart extends StatelessWidget {
  const _TrendGradeLineChart({required this.points});
  final List<GradePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noGpaDataAvailable,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (points.length < 3) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.startTrackingToSeeTrends,
          textAlign: TextAlign.center,
        ),
      );
    }
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 4.0,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (!_isWholeTick(value)) return const SizedBox.shrink();
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final step = _xAxisStep(points.length);
                if (index % step != 0) return const SizedBox.shrink();
                final date = points[index].date;
                return Text(
                  _formatDayLabel(date, context),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 3),
            ),
            barWidth: 4,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35),
              ],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                  Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallStatusCard extends StatelessWidget {
  const _OverallStatusCard({
    required this.trend,
    required this.riskScore,
    required this.consistency,
  });

  final TrendData trend;
  final double riskScore;
  final double consistency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalStudyHours = trend.studyTrend.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final completed = trend.taskTrend.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final totalTasks = _estimatedTotalTasks(trend, completed);
    final l10n = AppLocalizations.of(context)!;
    
    // New unified logic based on user request
    final bool isCriticalRisk = riskScore >= 50;
    final bool isStudyDeclining = trend.studyChangePercent < 0;
    final bool isLowConsistency = consistency < 0.5;
    
    final String status;
    final String detail;
    final Color color;
    
    if (isCriticalRisk) {
      status = l10n.trendStatusNeedsAttention; // Map to appropriate L10n
      detail = l10n.trendStatusCriticalRiskDetail;
      color = Colors.red;
    } else if (isStudyDeclining && isLowConsistency) {
      status = l10n.trendStatusNeedsImprovement;
      detail = l10n.trendStatusLowActivityHighCompletion; // Or similar
      color = Colors.orange;
    } else {
      status = l10n.trendStatusOnTrack;
      detail = l10n.trendStatusOnTrackDetail;
      color = Colors.green;
    }

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.assessment_rounded, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.trendOverallStatusTitle}: $status',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _estimatedTotalTasks(TrendData trend, int completed) {
    if (trend.taskCompletionRate <= 0) return completed == 0 ? 0 : completed;
    return (completed / trend.taskCompletionRate).round();
  }
}

class _StudyHoursBarChart extends ConsumerStatefulWidget {
  final AnalyticsData data;
  const _StudyHoursBarChart({required this.data});

  @override
  ConsumerState<_StudyHoursBarChart> createState() => _StudyHoursBarChartState();
}

class _StudyHoursBarChartState extends ConsumerState<_StudyHoursBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(courseProvider);
    final sessionsAsync = ref.watch(studySessionsProvider);
    final data = widget.data;

    if (data.studyHoursPerCourse.isEmpty) {
      return AppGlassCard(
        height: 200,
        child: Center(child: Text(l10n.noStudyDataThisWeek)),
      );
    }

    return coursesAsync.when(
      data: (courses) {
        final fallbackCoursesById = sessionsAsync.maybeWhen(
          data: (sessions) {
            final map = <String, Course>{};
            for (final session in sessions) {
              final course = session.course;
              if (course == null) continue;
              map[session.courseId] = course;
            }
            return map;
          },
          orElse: () => const <String, Course>{},
        );

        final List<_BarData> barData = [];
        data.studyHoursPerCourse.forEach((courseId, hours) {
          final course = courses.firstWhere(
            (c) => c.id == courseId,
            orElse: () =>
                fallbackCoursesById[courseId] ??
                Course(
                  id: courseId,
                  userId: '',
                  courseName: l10n.unknown,
                  academicSemester: 1,
                  credits: 0,
                  ects: 0,
                  color: '#9E9E9E',
                  createdAt: DateTime.now(),
                ),
          );
          barData.add(
            _BarData(course, hours * 60.0, _formatCourseName(course.courseName)),
          );
        });

        // Keep all courses that have recorded sessions.
        barData.sort((a, b) => b.minutes.compareTo(a.minutes));
        final allBars = barData;
        final maxMinutes = allBars.isEmpty
            ? 60.0
          : allBars
                  .map((e) => e.minutes)
                  .reduce((a, b) => a > b ? a : b)
                  .clamp(1.0, 24 * 60.0)
                  .toDouble();
        final maxY = maxMinutes <= 60
            ? 75.0
            : ((maxMinutes / 30).ceil() * 30 + 30).toDouble();
        final yInterval = maxY <= 75 ? 15.0 : 60.0;

        return GestureDetector(
          onTap: () {
            if (_selectedIndex != null) {
              Haptics.vibrate(HapticsType.selection);
              setState(() => _selectedIndex = null);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 240,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chartWidth = math.max(
                        constraints.maxWidth,
                        allBars.length * 56.0,
                      );
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          height: 240,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchCallback: (FlTouchEvent event, barResponse) {
                                  if (event is FlTapUpEvent) {
                                    final tappedIndex = (barResponse == null ||
                                            barResponse.spot == null)
                                        ? null
                                        : barResponse.spot!.touchedBarGroupIndex;

                                    final newIndex =
                                        tappedIndex == _selectedIndex ? null : tappedIndex;

                                    if (_selectedIndex != newIndex) {
                                      Haptics.vibrate(HapticsType.selection);
                                      setState(() {
                                        _selectedIndex = newIndex;
                                      });
                                    }
                                  }
                                },
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => theme.colorScheme.surface,
                                  tooltipRoundedRadius: 8,
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  tooltipMargin: 12,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final bar = allBars[groupIndex];
                                    final courseCode =
                                        (bar.course.courseCode ?? '')
                                            .replaceAll(RegExp(r'[\s\-]'), '')
                                            .toUpperCase();
                                    final shortName =
                                        bar.displayName.length > 15
                                            ? '${bar.displayName.substring(0, 15)}...'
                                            : bar.displayName;
                                    final duration = _formatDurationFromMinutes(
                                      l10n: l10n,
                                      totalMinutes: rod.toY.round(),
                                    );

                                    return BarTooltipItem(
                                      '',
                                      theme.textTheme.labelMedium!,
                                      children: [
                                        TextSpan(
                                          text: courseCode.isEmpty
                                              ? ''
                                              : '$courseCode\n',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$shortName\n',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextSpan(
                                          text: duration,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      textAlign: TextAlign.center,
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 34,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < allBars.length) {
                                        final bar = allBars[index];
                                        final rawCode = bar.course.courseCode ??
                                            (bar.displayName.length > 8
                                                ? bar.displayName.substring(0, 7)
                                                : bar.displayName);
                                        final normalizedCode = rawCode
                                            .replaceAll(RegExp(r'[\s\-]'), '')
                                            .toUpperCase();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            normalizedCode,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: index == _selectedIndex
                                                  ? FontWeight.w900
                                                  : FontWeight.bold,
                                              color: _selectedIndex == null ||
                                                      _selectedIndex == index
                                                  ? theme.colorScheme.onSurface
                                                  : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.3),
                                            ),
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
                                    reservedSize: 42,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) => Text(
                                      _formatDurationFromMinutes(
                                        l10n: l10n,
                                        totalMinutes: value.round(),
                                      ),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 24,
                                    getTitlesWidget: (_, __) => const SizedBox.shrink(),
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: allBars.asMap().entries.map((entry) {
                                final isSelected = _selectedIndex == entry.key;
                                final isDimmed =
                                    _selectedIndex != null && !isSelected;
                                return BarChartGroupData(
                                  x: entry.key,
                                  showingTooltipIndicators: isSelected ? [0] : [],
                                  barRods: [
                                    BarChartRodData(
                                      toY:
                                          entry.value.minutes < 1
                                              ? 1
                                              : entry.value.minutes,
                                      color: isDimmed
                                          ? entry.value.course.uiColor
                                              .withValues(alpha: 0.2)
                                          : entry.value.course.uiColor,
                                      width: isSelected ? 18 : 16,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      borderSide: isSelected
                                          ? BorderSide(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              width: 1.5,
                                            )
                                          : BorderSide.none,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            swapAnimationDuration: const Duration(milliseconds: 350),
                            swapAnimationCurve: Curves.easeOutCubic,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        children: allBars.asMap().entries.map((entry) {
                          final index = entry.key;
                          final bar = entry.value;
                          final isSelected = _selectedIndex == index;
                          const legendFontSize = 10.0;

                          final displayCode = (bar.course.courseCode ??
                                  (bar.displayName.length > 8
                                      ? bar.displayName.substring(0, 7)
                                      : bar.displayName))
                              .replaceAll(RegExp(r'[\s\-]'), '')
                              .toUpperCase();

                          final durationStr = _formatDurationFromMinutes(
                            l10n: l10n,
                            totalMinutes: bar.minutes.round(),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                Haptics.vibrate(HapticsType.selection);
                                setState(() {
                                  _selectedIndex = isSelected ? null : index;
                                });
                              },
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _selectedIndex == null || isSelected ? 1.0 : 0.3,
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: isSelected ? 12 : 8,
                                      height: isSelected ? 12 : 8,
                                      decoration: BoxDecoration(
                                        color: bar.course.uiColor,
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: bar.course.uiColor
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 4,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: displayCode,
                                              style: TextStyle(
                                                fontSize: legendFontSize,
                                                fontWeight: isSelected
                                                    ? FontWeight.w900
                                                    : FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' – ${bar.displayName}',
                                              style: TextStyle(
                                                fontSize: legendFontSize,
                                                color: theme.colorScheme.onSurface
                                                    .withValues(alpha: isSelected ? 0.9 : 0.6),
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' • $durationStr',
                                              style: TextStyle(
                                                fontSize: legendFontSize,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: theme.colorScheme.onSurface
                                                    .withValues(alpha: isSelected ? 1.0 : 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const AppGlassCard(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => AppGlassCard(
        height: 240,
        child: Center(child: Text(l10n.networkError)),
      ),
    );
  }

  String _formatDurationFromMinutes({
    required AppLocalizations l10n,
    required int totalMinutes,
  }) {
    if (totalMinutes <= 0) return '0${l10n.minutesAbbreviation}';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes${l10n.minutesAbbreviation}';
    if (minutes == 0) return '$hours${l10n.hoursAbbreviation}';
    return '$hours${l10n.hoursAbbreviation} $minutes${l10n.minutesAbbreviation}';
  }
}

class _BarData {
  final Course course;
  final double minutes;
  final String displayName;
  _BarData(this.course, this.minutes, this.displayName);
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
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

class _GradeDistributionCard extends StatelessWidget {
  const _GradeDistributionCard({required this.data});

  final AnalyticsData data;

  static const List<String> _gradeOrder = [
    'AA',
    'BA',
    'BB',
    'CB',
    'CC',
    'DC',
    'DD',
    'FF',
    'EX',
    'NA',
    'S',
    'U',
    'I',
    'P',
    'W',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distribution = data.gradeDistribution;

    if (distribution.isEmpty) {
      return AppGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text(l10n.noGradeDistributionYet)),
        ),
      );
    }

    final orderedGrades = distribution.keys.toList()
      ..sort((a, b) {
        final aIndex = _gradeOrder.indexOf(a);
        final bIndex = _gradeOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    return AppGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: orderedGrades
              .map(
                (grade) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          grade,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        distribution[grade].toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

String _formatDayLabel(DateTime date, BuildContext context) {
  return DateFormat('d', Localizations.localeOf(context).languageCode).format(date);
}

int _xAxisStep(int length) {
  if (length <= 7) return 1;
  if (length <= 14) return 2;
  return 4;
}

bool _isWholeTick(double value) {
  return (value - value.roundToDouble()).abs() < 0.001;
}

String _formatCourseName(String input) {
  if (input.trim().isEmpty) return input;

  return input
      .toLowerCase()
      .split(RegExp(r'[\s_-]+'))
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

class _StudyProfileCard extends StatelessWidget {
  final StudyAnalytics studyAnalytics;

  const _StudyProfileCard({required this.studyAnalytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profile = studyAnalytics.studyProfile;

    String windowLabel(String window) {
      if (window == 'Morning') return l10n.studyProfileMorning;
      if (window == 'Afternoon') return l10n.studyProfileAfternoon;
      return l10n.studyProfileEvening;
    }

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(HeroIcons.identification, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.studyProfileTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileRow(
            icon: HeroIcons.clock,
            text:
                "${l10n.studyProfileOptimalDuration(profile['optimalMin'], profile['optimalMax'])} (adaptive)",
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileRow(
            icon: HeroIcons.bolt,
            text: l10n.studyProfileStressThreshold(profile['stressThreshold'].toStringAsFixed(1)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileRow(
            icon: HeroIcons.sun,
            text: l10n.studyProfilePeakWindow(windowLabel(profile['peakWindow'])),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final HeroIcons icon;
  final String text;

  const _ProfileRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppIcon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
