import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/app_localizations.dart';
import 'quick_menu_screen.dart';
import 'widgets/study_heatmap.dart';
import '../study/widgets/live_study_session_card.dart';
import '../../providers/app_providers.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_glass_card.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/global_refresh_provider.dart';
import '../../providers/trend_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../models/trend_data.dart';
import '../../widgets/risk/risk_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appUserAsync = ref.watch(currentAppUserProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final trendAsync = ref.watch(trendProvider(7));
    final studentProfile = ref.watch(studentProfileProvider).value;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final appUser = appUserAsync.asData?.value;

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(globalRefreshProvider)(),
            child: dashboardAsync.when(
              data: (data) => SingleChildScrollView(
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

                    // --- SECTION 1.5: STUDY HEATMAP ---
                    const StudyHeatmap(),
                    const SizedBox(height: AppSpacing.lg),
                    const LiveStudySessionCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // --- SECTION 2: RISK SCORE CARD ---
                    const RiskScoreCard(),

                    const SizedBox(height: AppSpacing.lg),

                    // --- SECTION 3: OVERVIEW ---
                    _StatusPanel(data: data),

                    const SizedBox(height: AppSpacing.lg),

                    // --- SECTION 4: PROGRESS OVERVIEW ---
                    _ProgressOverviewCard(trendAsync: trendAsync),

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
              ),
              loading: () => _buildLoadingState(context),
              error: (e, s) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [Center(child: Text(l10n.networkError))],
              ),
            ),
          ),
        ),
      ),
    );
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
    final greetingName = appUser?.name?.split(' ').first ?? l10n.student;

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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.helloUser(greetingName),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${studentProfile?.major ?? l10n.student} • ${l10n.semester} ${studentProfile?.currentSemester ?? "?"}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
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
            const _QuickMenuButton(),
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
    
    String motivationText = analytics.isStable 
        ? l10n.justGettingStarted 
        : l10n.justGettingStarted;
    if (analytics.trend == 'improving') motivationText = l10n.statusImproving; // Improving as a placeholder for positive progress
    if (isUrgent) motivationText = l10n.behindThisWeek;

    // 2. Score Interpretation
    String scoreLabel = l10n.moderateFocus;
    if (analytics.focusScore < 40) scoreLabel = l10n.lowFocus;
    else if (analytics.focusScore >= 70) scoreLabel = l10n.highFocus;

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
                          HeroIcons.flag,
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
                      _buildAnalysisTag(theme, l10n.statusStable),
                      _buildAnalysisTag(
                        theme, 
                        analytics.trend == 'improving' ? l10n.statusImproving : l10n.statusDeclining,
                        color: analytics.trend == 'improving' ? Colors.green : Colors.orange,
                        icon: analytics.trend == 'improving' ? HeroIcons.arrowTrendingUp : HeroIcons.arrowTrendingDown,
                      ),
                      _buildAnalysisTag(theme, analytics.isStable ? l10n.patternConsistent : l10n.patternIrregular),
                      _buildAnalysisTag(theme, analytics.isStable ? l10n.confidenceHigh : l10n.confidenceMedium),
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
        icon: HeroIcons.lockClosed,
        title: l10n.changePassword,
        route: '/profile/change-password',
      ),
    ];
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

  String _formatDuration({
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
        child: trendAsync.when(
          loading: () => const SizedBox(
            height: 64,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.networkError),
          data: (trend) {
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
                  label: l10n.study,
                  value: studyStatus,
                  color: studyColor,
                ),
                _progressLine(
                  context: context,
                  label: l10n.tasks,
                  value: l10n.trendPercentCompleted(taskPercent),
                  color: taskColor,
                ),
                _progressLine(
                  context: context,
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
          },
        ),
      ),
    );
  }

  Widget _progressLine({
    required BuildContext context,
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
            Text('$label:', style: theme.textTheme.bodyMedium),
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
          Text('$label: ', style: theme.textTheme.bodyMedium),
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

    return AnimatedPressable(
      onTap: () => context.push('/tasks?filter=pending&source=dashboard'),
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
