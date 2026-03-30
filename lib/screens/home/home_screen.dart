import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/app_localizations.dart';
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
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../widgets/risk/risk_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appUserAsync = ref.watch(currentAppUserProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final studentProfile = ref.watch(studentProfileProvider).value;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final appUser = appUserAsync.asData?.value;

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: dashboardAsync.when(
            data: (data) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: HEADER & PROFILE ---
                  _buildHeader(context, theme, l10n, appUser, studentProfile, data, unreadNotifications),

                  const SizedBox(height: AppSpacing.lg),

                  // --- SECTION 2: RISK SCORE CARD ---
                  const RiskScoreCard(),

                  const SizedBox(height: AppSpacing.lg),

                  // --- SECTION 3: STATUS PANEL ---
                  _StatusPanel(data: data),

                  const SizedBox(height: AppSpacing.lg),

                  // --- SECTION 4: STUDY STATS CARD ---
                  _buildStudyStatsCard(context, theme, l10n, data),

                  const SizedBox(height: AppSpacing.lg),

                  // --- SECTION 4: TODAY OVERVIEW ---
                  _buildTodayOverview(context, ref, l10n, data),

                  const SizedBox(height: AppSpacing.xl),

                  // --- SECTION 5: UPCOMING DEADLINES ---
                  _buildUpcomingDeadlines(context, theme, l10n, data),

                  const SizedBox(height: AppSpacing.xl),

                  // --- SECTION 6: COURSE ACTIVITY ---
                  _buildCourseActivity(context, theme, l10n, data),

                  const SizedBox(height: 120),
                ],
              ),
            ),
            loading: () => _buildLoadingState(context),
            error: (e, s) => Center(child: Text(l10n.networkError)),
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
    int unreadNotifications
  ) {
    final greetingName = appUser?.name?.split(' ').first ?? l10n.student;
    
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          backgroundImage: appUser?.avatarUrl != null
              ? NetworkImage(appUser!.avatarUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
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
                  if (data.streakCount > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _StreakBadge(count: data.streakCount),
                  ],
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
        _NotificationButton(unreadCount: unreadNotifications),
      ],
    ).animate().fade().slideX(begin: -0.1);
  }

  Widget _buildStudyStatsCard(BuildContext context, ThemeData theme, AppLocalizations l10n, DashboardData data) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.studyGoal,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.thisWeekLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              Text(
                '${(data.weeklyStudyCompletedMinutes / 60).toStringAsFixed(1)} / ${(data.weeklyStudyGoalMinutes / 60).toStringAsFixed(0)}${l10n.hoursAbbreviation}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: data.weeklyStudyGoalMinutes > 0 
                  ? (data.weeklyStudyCompletedMinutes / data.weeklyStudyGoalMinutes).clamp(0, 1) 
                  : 0,
              minHeight: 12,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.studyGoalRemaining('${((data.weeklyStudyGoalMinutes - data.weeklyStudyCompletedMinutes).clamp(0, double.infinity) / 60).toStringAsFixed(1)}${l10n.hoursAbbreviation}'),
            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTodayOverview(BuildContext context, WidgetRef ref, AppLocalizations l10n, DashboardData data) {
    return Row(
      children: [
        Expanded(child: _OverviewSmallCard(
          title: l10n.tasksToday,
          value: '${data.pendingTasksToday}',
          icon: HeroIcons.checkCircle,
          color: Colors.blue,
          onTap: () => context.push('/tasks?filter=pending'),
        )),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _OverviewSmallCard(
          title: l10n.deadlines,
          value: '${data.upcomingDeadlines.length}',
          icon: HeroIcons.calendar,
          color: Colors.orange,
          onTap: () => context.push('/tasks?filter=deadlines'),
        )),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _OverviewSmallCard(
          title: l10n.study,
          value: '${data.studyMinutesToday ~/ 60}${l10n.hoursAbbreviation} ${data.studyMinutesToday % 60}${l10n.minutesAbbreviation}',
          icon: HeroIcons.clock,
          color: Colors.green,
          onTap: () {
            ref.read(bottomNavProvider.notifier).state = 2; // Tasks -> Study
            context.go('/home');
          },
        )),
      ],
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildUpcomingDeadlines(BuildContext context, ThemeData theme, AppLocalizations l10n, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.upcomingDeadlines,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (data.upcomingDeadlines.isEmpty)
          _buildEmptyState(
            theme, 
            l10n.noUpcomingDeadlines, 
            l10n.caughtUp, 
            HeroIcons.calendar
          )
        else
          ...data.upcomingDeadlines.take(3).map(
            (deadline) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DeadlineListItem(deadline: deadline),
            ),
          ),
      ],
    ).animate().fade(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildCourseActivity(BuildContext context, ThemeData theme, AppLocalizations l10n, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myCourses,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle, HeroIcons icon, {Widget? action}) {
    return AppGlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Opacity(
                opacity: 0.3,
                child: AppIcon(icon, size: 48),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
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
                      Container(width: 150, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)))),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg))),
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _StreakBadge extends StatelessWidget {
  final int count;
  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(HeroIcons.fire, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    ).animate().scale().shake();
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const AppIcon(HeroIcons.bell),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends ConsumerWidget {
  final DashboardData data;
  const _StatusPanel({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Use consistent primary color for operational overview
    const accentColor = AppColors.primary;
    const icon = HeroIcons.squares2x2;
    
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return AnimatedPressable(
      onTap: () => _handleNavigation(context),
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
                  child: const AppIcon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.overviewTitle,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.lastUpdated('$hh:$mm'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                AppIcon(HeroIcons.chevronRight, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Bullet points summary
            if (data.overdueTasksCount > 0)
              _buildSummaryRow(l10n.overviewOverdueTasksAction(data.overdueTasksCount), theme, true),
            
            const SizedBox(height: 4),
            _buildSummaryRow(
              data.upcomingDeadlinesCount > 0 
                ? l10n.overviewUpcomingTasks(data.upcomingDeadlinesCount)
                : l10n.overviewNoUpcomingTasks,
              theme, 
              false
            ),
            
            const SizedBox(height: 4),
            _buildSummaryRow(
              data.completedTodayCount > 0
                ? l10n.overviewCompletedToday(data.completedTodayCount)
                : l10n.overviewNoCompletedToday,
              theme, 
              false
            ),
          ],
        ),
      ).animate().fade().slideY(begin: 0.1),
    );
  }

  Widget _buildSummaryRow(String text, ThemeData theme, bool isWarning) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isWarning ? theme.colorScheme.error : theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isWarning ? theme.colorScheme.error : null,
              fontWeight: isWarning ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  void _handleNavigation(BuildContext context) {
    // Navigate to Pending Tasks tab
    context.push('/tasks?filter=pending');
  }
}


class _OverviewSmallCard extends StatelessWidget {
  final String title;
  final String value;
  final HeroIcons icon;
  final Color color;
  final VoidCallback onTap;

  const _OverviewSmallCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressable(
      onTap: onTap,
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 20, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.sm)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deadline.course, style: theme.textTheme.bodySmall),
                Text(deadline.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  diff <= 0 ? l10n.dueToday : l10n.dueInDays(diff),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: diff <= 2 ? AppColors.error : theme.colorScheme.primary,
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
                  Row(
                    children: [
                      Text(
                        '${stats.tasksCount} ${l10n.tasks}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.course.ects} ${l10n.ectsLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
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
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
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
