import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import 'quick_menu_screen.dart';
import 'widgets/study_heatmap.dart';
import '../study/widgets/live_study_session_card.dart';
import '../ai/ai_chat_screen.dart';
import '../../providers/app_providers.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../providers/mood_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_glass_card.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../widgets/semester/semester_comparison_card.dart';
import '../../widgets/semester/smart_insights_card.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/smart_notification_engine.dart';
import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/global_refresh_provider.dart';
import '../../providers/trend_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/decision_provider.dart';
import '../../providers/study_sessions_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../domain/decision/decision_result.dart';
import '../../domain/prediction/prediction_result.dart';
import '../../domain/decision/decision_rules.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../models/mood_log.dart';
import '../../models/trend_data.dart';
import '../../widgets/risk/risk_widgets.dart';
import '../../providers/risk_provider.dart';
import '../../providers/semester_provider.dart';
import 'widgets/home_skeleton_screen.dart';
import '../../widgets/mood/mood_daily_list.dart';
import '../../providers/course_provider.dart';
import '../../widgets/semester/semester_switcher_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Prevents rapid double-triggers (shake / multiple rebuild loops).
  bool _isRefreshing = false;
  // Stable scroll controller — survives provider rebuilds.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(globalRefreshProvider)();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Watch semester to force rebuild on change
    final semesterIdAsync = ref.watch(activeSemesterProvider);
    final semesterId = semesterIdAsync.value;
    
    // Evaluate Smart Notifications dynamically
    ref.listen(analyticsProvider, (prev, next) {
      next.whenData((data) {
        // Provide a direct repository fetcher to ensure notifications use
        // fresh task data (avoid relying on UI provider cache/state).
        Future<List<Task>> fetcher() async {
          final userId = ref.read(currentUserProvider)?.id;
          final semesterIdValue = ref.read(activeSemesterProvider).value;
          if (userId == null) return <Task>[];
          try {
            final repo = ref.read(taskRepositoryProvider);
            return await repo.getTasks(userId: userId, semesterId: semesterIdValue);
          } catch (_) {
            return <Task>[];
          }
        }
        if (semesterId != null && next.hasValue) {
          SmartNotificationEngine.evaluate(
            analytics: next.value!,
            fetchTasks: fetcher,
          );
        }
      });
    });

    // Select ONLY values to prevent rebuild spam during refreshing states
    final appUser = ref.watch(currentAppUserProvider.select((v) => v.asData?.value));
    final data = ref.watch(dashboardProvider.select((v) => v.value));
    final trendAsync = ref.watch(trendProvider(7));
    final studentProfile = ref.watch(studentProfileProvider).value;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final todayMoodAsync = ref.watch(todayMoodProvider);
    final moodLogsAsync = ref.watch(dailyMoodLogsProvider);
    final analytics = ref.watch(analyticsProvider.select((v) => v.value));
    final decision = ref.watch(decisionProvider);
    final prediction = ref.watch(predictionProvider);

    final isFirstLoad = data == null;

    return Scaffold(
      key: Key('home_screen_${semesterId ?? 'none'}'),
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: (isFirstLoad || _isRefreshing)
                    ? const HomeSkeletonScreen()
                    : Container(
                        color: (analytics?.avgStress ?? 0) >= 8
                            ? Colors.red.withValues(alpha: 0.04)
                            : Colors.transparent,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- SECTION 1: HEADER & PROFILE ---
                              _buildHeader(
                                context,
                                theme,
                                l10n,
                                appUser,
                                studentProfile,
                                data,
                                unreadNotifications,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // --- SECTION 1.5: SEMESTER SELECTOR ---
                              const _SemesterBanner(),
                              const SizedBox(height: AppSpacing.md),

                              // --- SECTION 1.6: STUDY HEATMAP ---
                              const RepaintBoundary(child: StudyHeatmap()),
                              
                              const SizedBox(height: AppSpacing.lg),
                              const LiveStudySessionCard(),
                              const SizedBox(height: AppSpacing.md),

                              // --- SECTION 1.8: MOOD-INFLUENCED MESSAGE ---
                              if (analytics != null) ...[
                                if (analytics.avgStress >= 8)
                                  _buildCalmToneMessage(context, theme, l10n)
                                else if (analytics.avgMood >= 4.5)
                                  _buildEncouragementMessage(context, theme, l10n),
                                
                                if (analytics.avgStress >= 8 || analytics.avgMood >= 4.5)
                                  const SizedBox(height: AppSpacing.md),
                              ],

                              // --- SECTION 2: RISK SCORE CARD ---
                              if (ref.watch(riskProvider).hasData) ...[
                                const RiskScoreCard(),
                                const SizedBox(height: AppSpacing.lg),
                              ],

                              // --- SECTION 2.1: MOOD ENTRY CARD OR SUMMARY (CONDITIONAL) ---
                              ref.watch(moodSettingsProvider.notifier).shouldShowDaily
                                  ? todayMoodAsync.when(
                                      data: (hasLoggedToday) {
                                        if (!hasLoggedToday) {
                                          return _buildMoodEntryCard(context, theme, l10n);
                                        }
                                        return const SizedBox.shrink();
                                      },
                                      loading: () => const SizedBox.shrink(),
                                      error: (e, st) => const SizedBox.shrink(),
                                    )
                                  : const SizedBox.shrink(),
                               if (ref.watch(moodSettingsProvider.notifier).shouldShowDaily &&
                                  todayMoodAsync.asData?.value != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.dailyMoodHistory,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Haptics.vibrate(HapticsType.selection);
                                        context.push('/mood/history');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          l10n.view,
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppGlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: MoodDailyList(
                                    moodLogsAsync: moodLogsAsync,
                                    days: 7,
                                    showDate: false,
                                    isFixed: true,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],



                              // --- SECTION 3: OVERVIEW & EMPTY STATE ---
                              Builder(builder: (context) {
                                final coursesAsync = ref.watch(courseProvider);
                                final isRefreshing = coursesAsync.isLoading;

                                if (isRefreshing && data.topCourses.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return data.topCourses.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                                        child: AppGlassCard(
                                          padding: const EdgeInsets.all(AppSpacing.xl),
                                          child: Column(
                                            children: [
                                              HeroIcon(
                                                HeroIcons.sparkles,
                                                size: 48,
                                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: AppSpacing.md),
                                              Text(
                                                l10n.noCoursesForSemester,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: AppSpacing.sm),
                                              Text(
                                                l10n.addCoursesPrompt,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: AppSpacing.lg),
                                              AppButton(
                                                text: l10n.addCourse,
                                                onPressed: () => context.push('/create-course'),
                                                variant: AppButtonVariant.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ).animate().fade().slideY(begin: 0.1)
                                    : const SizedBox.shrink();
                              }),
                              if (data.topCourses.isNotEmpty || ref.watch(courseProvider).isLoading) ...[
                                if (!ref.watch(courseProvider).isLoading || data.topCourses.isNotEmpty)
                                  _StatusPanel(data: data),

                                const SizedBox(height: AppSpacing.lg),

                                // --- SECTION 4: PROGRESS OVERVIEW ---
                                _ProgressOverviewCard(trendAsync: trendAsync),

                                const SizedBox(height: AppSpacing.md),
                                const SmartInsightsCard(),
                              ],

                              const SizedBox(height: AppSpacing.lg),

                              // --- SECTION 5: QUICK MENU STRIP ---
                              _buildQuickMenuStrip(context, theme, l10n),

                              const SizedBox(height: AppSpacing.lg),

                              // --- SECTION 6: STUDY STATS CARD ---
                              _buildStudyStatsCard(context, ref, theme, l10n, data),

                              const SizedBox(height: AppSpacing.xl),

                              // --- SECTION 7: UPCOMING DEADLINES ---
                              _buildUpcomingDeadlines(context, theme, l10n, data),

                              const SizedBox(height: AppSpacing.xl),

                              // --- SECTION 8: COURSE ACTIVITY ---
                              _buildCourseActivity(context, theme, l10n, data),

                              const SizedBox(height: 120),
                            ],
                          ),
                        ), // closes SingleChildScrollView
                      ), // closes Container
                ), // closes AnimatedSwitcher
              ), // closes RefreshIndicator
              if (_isRefreshing)
                const Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ), // Closes Stack
        ), // Closes SafeArea
      ), // Closes AuthBackgroundContainer
    ); // Closes Scaffold
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    dynamic appUser,
    dynamic studentProfile,
    DashboardData data,
    int unreadNotifications,
  ) {

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          backgroundImage: appUser?.avatarUrl != null
              ? NetworkImage(appUser!.avatarUrl!)
              : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcome,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                appUser?.name ?? l10n.student,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  decorationColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              if (studentProfile?.universityName != null)
                Text(
                  studentProfile!.universityName!,
                  softWrap: true,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              Text(
                studentProfile?.major ?? l10n.student,
                softWrap: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NotificationButton(unreadCount: unreadNotifications),
            const SizedBox(width: AppSpacing.md),
            const _AiAssistantButton(),
          ],
        ),
      ],
    ).animate().fade().slideX(begin: -0.1);
  }

  Widget _buildAnalysisTag(ThemeData theme, String text, {Color? color, HeroIcons? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 12, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyStatsCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    DashboardData data,
  ) {
    final analytics = ref.watch(studyAnalyticsProvider);
    final double progressVal = data.weeklyStudyGoalMinutes > 0
        ? (data.weeklyStudyCompletedMinutes / data.weeklyStudyGoalMinutes).clamp(0, 1)
        : 0;

    // 1. Logic: Urgency & Reward
    final todayWeekday = DateTime.now().weekday;
    final bool isUrgent = todayWeekday >= 4 && progressVal < 0.4;
    
    String motivationText = l10n.justGettingStarted;
    if (analytics.trackedSessionCount >= 5) {
      if (analytics.trend == 'improving') {
        motivationText = l10n.statusImproving;
      } else if (analytics.trend == 'declining') {
        motivationText = l10n.statusDeclining;
      } else {
        motivationText = l10n.statusStable;
      }
    }
    
    if (isUrgent) {
      motivationText = l10n.behindThisWeek;
    }

    // 2. Score Interpretation
    String scoreLabel = l10n.moderateFocus;
    if (analytics.focusScore < 40) {
      scoreLabel = l10n.lowFocus;
    } else if (analytics.focusScore >= 70) {
      scoreLabel = l10n.highFocus;
    }

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Goal Header - Responsive Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(
                          HeroIcons.cursorArrowRays,
                          size: 18,
                          color: theme.colorScheme.primary,
                          solid: true,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.studyGoal,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motivationText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isUrgent ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(data.weeklyStudyCompletedMinutes / 60).toStringAsFixed(1)}${l10n.hoursAbbreviation} / ${(data.weeklyStudyGoalMinutes / 60).toStringAsFixed(1)}${l10n.hoursAbbreviation}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // 2. Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressVal,
              minHeight: 12,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // 3. Focus Intelligence Center - Adaptive Column + Wrap
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified Score Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      analytics.hasData ? "${analytics.focusScore}" : "--",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      analytics.hasData ? scoreLabel : l10n.gettingStarted,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Adaptive Tags Wrap - Solves All Overflow
                if (!analytics.hasData)
                  Text(
                    l10n.noDataYet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 1. Trend tag
                      _buildAnalysisTag(
                        theme, 
                        analytics.trend == 'improving' 
                            ? l10n.statusImproving 
                            : (analytics.trend == 'declining' 
                                ? l10n.statusDeclining 
                                : l10n.statusStable),
                        color: analytics.trend == 'improving' 
                            ? Colors.green 
                            : (analytics.trend == 'declining' ? Colors.orange : theme.colorScheme.primary),
                        icon: analytics.trend == 'improving' 
                            ? HeroIcons.arrowTrendingUp 
                            : (analytics.trend == 'declining' ? HeroIcons.arrowTrendingDown : HeroIcons.checkCircle),
                      ),
                      // 2. Pattern tag
                      _buildAnalysisTag(
                        theme, 
                        analytics.consistency >= 0.6 ? l10n.patternConsistent : l10n.patternIrregular,
                        icon: analytics.consistency >= 0.6 ? HeroIcons.checkCircle : HeroIcons.exclamationTriangle,
                        color: analytics.consistency >= 0.6 ? Colors.green : Colors.orange,
                      ),
                      // 3. Confidence tag
                      _buildAnalysisTag(
                        theme, 
                        analytics.trackedSessionCount >= 10 
                            ? l10n.confidenceHigh 
                            : (analytics.trackedSessionCount >= 5 
                                ? l10n.confidenceMedium 
                                : l10n.confidenceLow),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 4. Action Command - Integrated Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrgent
                  ? l10n.trySessionNow(analytics.suggestedDuration)
                  : l10n.trySessionNow(analytics.suggestedDuration), // Harmonized wording
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(bottomNavProvider.notifier).state = 2;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: Text(l10n.startNow),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          Text(
            isUrgent 
              ? l10n.catchUpMessage((data.weeklyStudyGoalMinutes - data.weeklyStudyCompletedMinutes).clamp(0, 9999) ~/ 60)
              : l10n.remainingHours((data.weeklyStudyGoalMinutes - data.weeklyStudyCompletedMinutes).clamp(0, 9999) ~/ 60),
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 11,
              color: isUrgent ? theme.colorScheme.error.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickMenuStrip(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final items = _dashboardQuickMenuItems(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.quickMenu,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            AnimatedPressable(
              onTap: () => QuickMenuScreen.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.all,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const AppIcon(HeroIcons.squares2x2, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return _CompactQuickMenuCard(item: item);
            },
          ),
        ),
      ],
    ).animate().fade(delay: 120.ms).slideY(begin: 0.08);
  }

  List<_DashboardQuickMenuItem> _dashboardQuickMenuItems(
    AppLocalizations l10n,
  ) {
    return <_DashboardQuickMenuItem>[
      _DashboardQuickMenuItem(
        icon: HeroIcons.academicCap,
        title: l10n.myCourses,
        route: '/courses',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.chartBar,
        title: l10n.examResults,
        route: '/course-results',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.calendar,
        title: l10n.manageSemesters,
        route: '/semesters',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.bookOpen,
        title: l10n.academicHistory,
        route: '/academic-history',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.plusCircle,
        title: l10n.addCourse,
        route: '/create-course',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.checkCircle,
        title: l10n.createTask,
        route: '/create-task',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.clock,
        title: l10n.createDeadline,
        route: '/create-deadline',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.faceSmile,
        title: l10n.logMoodTitle,
        route: '/mood/log',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.clock,
        title: l10n.moodHistoryTitle,
        route: '/mood/history',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.bell,
        title: l10n.notifications,
        route: '/notifications',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.userCircle,
        title: l10n.editProfile,
        route: '/profile/edit',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.adjustmentsHorizontal,
        title: l10n.studyPreferences,
        route: '/profile/study-preferences',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.cog6Tooth,
        title: l10n.moodSettingsTitle,
        route: '/settings/mood-stress',
      ),
      _DashboardQuickMenuItem(
        icon: HeroIcons.lockClosed,
        title: l10n.changePassword,
        route: '/profile/change-password',
      ),
    ];
  }

  Widget _buildMoodEntryCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: AppGlassCard(
        key: ValueKey('mood-card'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppIcon(
              HeroIcons.faceSmile,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.moodDailyPromptTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.moodDailyPromptSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push('/mood/log'),
              child: Text(
                l10n.logMoodTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.08);
  }

  Widget _buildMoodSummaryCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    MoodLog todayLog,
  ) {
    final emojiMap = {
      1: '😞', 2: '🙁', 3: '😐', 4: '🙂', 5: '😄'
    };
    final emoji = emojiMap[todayLog.moodLevel] ?? '😐';
    
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Text(emoji, style: theme.textTheme.headlineSmall),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todaysMoodTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      _getMoodLabel(l10n, todayLog.moodLevel),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('•', style: theme.textTheme.bodySmall),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.stressOutOfTen(todayLog.stressLevel),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/mood/history'),
            icon: const AppIcon(HeroIcons.clock, size: 16),
            label: Text(l10n.view),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.08);
  }

  Widget _buildCalmToneMessage(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.psychology, color: Colors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.takeItSlowerTodayTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.takeItSlowerTodayBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementMessage(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.orange),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.strongStateTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.strongStateBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodLabel(AppLocalizations l10n, int level) {
    switch (level) {
      case 1: return l10n.moodTerrible;
      case 2: return l10n.moodBad;
      case 3: return l10n.moodNeutral;
      case 4: return l10n.moodGood;
      case 5: return l10n.moodAmazing;
      default: return l10n.moodUnknown;
    }
  }

  Widget _buildDecisionInsightsCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    DecisionResult decision,
  ) {
    final signature = decision.sortedItems
        .map((item) => '${item.priority}:${item.title}')
        .join('|');
    final primary = decision.primaryDecision;
    if (primary == null) {
      return const SizedBox.shrink();
    }

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
          _buildPrimaryDecisionBlock(context, theme, l10n, primary),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: l10n.startNow,
              onPressed: () => _startNowFromDecision(
                context,
                ref,
                decision.suggestedSessionMinutes,
              ),
              icon: const AppIcon(HeroIcons.play, size: 16, color: Colors.white),
            ),
          ),
          if (decision.secondaryDecisions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...decision.secondaryDecisions.map<Widget>(
              (item) => _buildPriorityDecisionItem(context, theme, l10n, item),
            ),
          ],
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            _confidenceLabel(l10n, decision.confidence),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
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
    final analytics = ref.read(analyticsProvider).value;
    final minutes = suggestedMinutes ?? DecisionRules.getRecommendedSessionLength(analytics?.avgSessionStress ?? 0.0);
    final timerState = ref.read(studyTimerProvider);
    final timer = ref.read(studyTimerProvider.notifier);

    timer.setDuration(Duration(minutes: minutes));
    if (timerState.courseId != null) {
      timer.start();
    }
    ref.read(bottomNavProvider.notifier).state = 2;
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
          Row(
            children: [
              AppIcon(HeroIcons.chartBar, color: levelColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.predictionStressTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                levelText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: levelColor,
                  fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $reason',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
          Row(
            children: [
              AppIcon(HeroIcons.calendar, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.predictionPlanTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...prediction.recommendedPlan.map((item) {
            final day = _relativeDayLabel(l10n, item.scheduledAt);
            final time = timeLabel.formatTimeOfDay(
              TimeOfDay(hour: item.scheduledAt.hour, minute: item.scheduledAt.minute),
              alwaysUse24HourFormat: true,
            );
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• ${l10n.predictionPlanLine(
                  day,
                  time,
                  item.durationMinutes,
                  item.focusKey,
                )}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          if (prediction.explanationKeys.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.predictionWhyTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...prediction.explanationKeys.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $reason',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildPredictionRiskSection(theme, l10n, prediction),
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
    return DateFormat.EEEE().format(date);
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
    return DateFormat.EEEE().format(date);
  }

  Widget _buildUpcomingDeadlines(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DashboardData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.upcomingDeadlines,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (data.upcomingDeadlines.isEmpty)
          _buildEmptyState(
            theme,
            l10n.noUpcomingDeadlines,
            l10n.caughtUp,
            HeroIcons.calendar,
          )
        else
          ...data.upcomingDeadlines
              .take(3)
              .map(
                (deadline) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _DeadlineListItem(deadline: deadline),
                ),
              ),
      ],
    ).animate().fade(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildCourseActivity(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DashboardData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myCourses,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppButton(
              onPressed: () => context.push('/courses'),
              variant: AppButtonVariant.text,
              text: l10n.all,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.topCourses.isEmpty)
          _buildEmptyState(
            theme,
            l10n.noCoursesYet,
            l10n.addCoursesPrompt,
            HeroIcons.academicCap,
            action: AppButton(
              onPressed: () => context.push('/create-course'),
              text: l10n.addFirstCourseBtn,
            ),
          )
        else
          ...data.topCourses.map((stats) => _CourseActivityCard(stats: stats)),
      ],
    ).animate().fade(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String title,
    String subtitle,
    HeroIcons icon, {
    Widget? action,
  }) {
    return AppGlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Opacity(opacity: 0.3, child: AppIcon(icon, size: 48)),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// --- SUB-WIDGETS ---

class _ProgressOverviewCard extends ConsumerWidget {
  const _ProgressOverviewCard({required this.trendAsync});

  final AsyncValue<TrendData> trendAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnimatedPressable(
      onTap: () {
        ref.read(analyticsJumpToTrendsTokenProvider.notifier).state++;
        ref.read(bottomNavProvider.notifier).state = 3;
        context.go('/home');
      },
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: () {
          if (!trendAsync.hasValue || trendAsync.value == null) {
            return const SizedBox(height: 64);
          }
          final trend = trendAsync.value!;
          const accentColor = AppColors.primary;
            final totalStudyHours = trend.studyTrend.values.fold<double>(
              0,
              (sum, value) => sum + value,
            );
            final studyStatus = totalStudyHours < 0.5
                ? l10n.trendVeryLowActivity
                : totalStudyHours < 1
                ? l10n.trendLowActivity
                : l10n.trendImproving;
            final studyColor = totalStudyHours < 1
                ? Colors.orange
                : Colors.green;

            final taskPercent = (trend.taskCompletionRate * 100).round();
            final taskColor = taskPercent >= 60
                ? Colors.green
                : (taskPercent > 0 ? Colors.orange : theme.colorScheme.error);

            final totalWorkload = trend.workloadTrend.values.fold<int>(
              0,
              (sum, value) => sum + value,
            );
            final workloadStatus = totalWorkload == 0
                ? l10n.trendNoWorkload
                : trend.workloadChangePercent > 10
                ? l10n.trendIncreased
                : trend.workloadChangePercent < -10
                ? l10n.trendReducedComparedLastPeriod
                : l10n.trendStable;
            final workloadColor = trend.workloadChangePercent > 10
                ? Colors.orange
                : theme.colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const AppIcon(
                        HeroIcons.chartBarSquare,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.dashboardProgressOverviewTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _progressLine(
                  context: context,
                  l10n: l10n,
                  label: l10n.study,
                  value: studyStatus,
                  color: studyColor,
                ),
                _progressLine(
                  context: context,
                  l10n: l10n,
                  label: l10n.tasks,
                  value: l10n.trendPercentCompleted(taskPercent),
                  color: taskColor,
                ),
                _progressLine(
                  context: context,
                  l10n: l10n,
                  label: l10n.workloadTrend,
                  value: workloadStatus,
                  color: workloadColor,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.dashboardViewDetailedAnalysis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }(),
        ),
    );
  }

  Widget _progressLine({
    required BuildContext context,
    required AppLocalizations l10n,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final useStackedLayout = value.length > 20;

    if (useStackedLayout) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.labelWithColon(label), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                value,
                softWrap: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(l10n.labelWithColonAndSpace(label), style: theme.textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  const _NotificationButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressable(
      onTap: () => context.push('/notifications'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const AppIcon(HeroIcons.bell, size: 24),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantButton extends StatelessWidget {
  const _AiAssistantButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AIChatScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: const AppIcon(
          HeroIcons.sparkles, 
          size: 24, 
          solid: true,
        ),
      ),
    );
  }
}

class _QuickMenuButton extends StatelessWidget {
  const _QuickMenuButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressable(
      onTap: () => QuickMenuScreen.show(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: const AppIcon(HeroIcons.bars3BottomRight, size: 24),
      ),
    );
  }
}

class _CompactQuickMenuCard extends StatelessWidget {
  const _CompactQuickMenuCard({required this.item});

  final _DashboardQuickMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressable(
      onTap: () => context.push(item.route),
      child: AppGlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          width: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(item.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardQuickMenuItem {
  const _DashboardQuickMenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  final HeroIcons icon;
  final String title;
  final String route;
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const accentColor = AppColors.primary;
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    final overviewFilter = _overviewFilterForData(data);

    return AnimatedPressable(
      onTap: () => context.push('/tasks?filter=$overviewFilter&source=dashboard'),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppIcon(
                    HeroIcons.squares2x2,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.overviewTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.lastUpdated('$hh:$mm'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppIcon(
                  HeroIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _summaryLine(
              context,
              data.overdueTasksCount > 0
                  ? l10n.overviewOverdueTasksAction(data.overdueTasksCount)
                  : l10n.allTasksUpToDate,
              isWarning: data.overdueTasksCount > 0,
            ),
            const SizedBox(height: 4),
            _summaryLine(
              context,
              data.upcomingDeadlinesCount > 0
                  ? l10n.overviewUpcomingTasks(data.upcomingDeadlinesCount)
                  : l10n.overviewNoUpcomingTasks,
            ),
            const SizedBox(height: 4),
            _summaryLine(
              context,
              data.completedTodayCount > 0
                  ? l10n.overviewCompletedToday(data.completedTodayCount)
                  : l10n.overviewNoCompletedToday,
            ),
          ],
        ),
      ),
    );
  }

  String _overviewFilterForData(DashboardData data) {
    final hasDeadlines = data.upcomingDeadlinesCount > 0;
    final hasTasks = data.pendingTasksToday > 0 ||
        data.overdueTasksCount > 0 ||
        data.completedTodayCount > 0 ||
        data.workloadAddedTodayCount > 0;

    if (hasDeadlines && hasTasks) return 'all';
    if (hasDeadlines) return 'deadlines';
    return 'tasks';
  }

  Widget _summaryLine(
    BuildContext context,
    String text, {
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    return Text(
      '• $text',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isWarning ? theme.colorScheme.error : null,
        fontWeight: isWarning ? FontWeight.w600 : null,
      ),
    );
  }
}

class _DeadlineListItem extends StatelessWidget {
  final dynamic deadline;
  const _DeadlineListItem({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final diff = deadline.deadlineDate.difference(DateTime.now()).inDays;

    return AppGlassCard(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: BoxDecoration(
              color: diff <= 2 ? AppColors.error : theme.colorScheme.primary,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deadline.course, style: theme.textTheme.bodySmall),
                Text(
                  deadline.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  diff <= 0 ? l10n.dueToday : l10n.dueInDays(diff),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: diff <= 2
                        ? AppColors.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseActivityCard extends StatelessWidget {
  final CourseStats stats;
  const _CourseActivityCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: stats.course.uiColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.course.courseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        '${stats.tasksCount} ${l10n.tasks}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.course.credits} ${l10n.creditsLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: stats.course.uiColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.course.ects} ${l10n.ectsLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.studyMinutes ~/ 60}${l10n.hoursAbbreviation} ${stats.studyMinutes % 60}${l10n.minutesAbbreviation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.study,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterBanner extends ConsumerWidget {
  const _SemesterBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemesterAsync = ref.watch(activeSemesterFullProvider);
    final isSwitching = ref.watch(isSemesterSwitchingProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return activeSemesterAsync.when(
      data: (activeSemester) {
        if (activeSemester == null) return const SizedBox.shrink();

        return AnimatedPressable(
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
            child: AppGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HeroIcon(
                       HeroIcons.calendarDays,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectedSemester,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeSemester.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSwitching)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    )
                  else
                    HeroIcon(
                      HeroIcons.chevronUpDown,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Silent during initial load
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
