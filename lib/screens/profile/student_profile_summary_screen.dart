import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_back_button.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course.dart';
import '../../models/performance_summary.dart';
import '../../models/semester.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/course_provider.dart';
import '../../providers/deadlines_provider.dart';
import '../../providers/performance_summary_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/student_summary_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../utils/display_name_resolver.dart';
import '../../widgets/auth/auth_background_container.dart';

class StudentProfileSummaryScreen extends ConsumerWidget {
  const StudentProfileSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final studentProfile = ref.watch(studentProfileProvider).value;
    final appUser = ref.watch(currentAppUserProvider).asData?.value;
    final user = ref.watch(currentUserProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final summaryAsync = ref.watch(performanceSummaryProvider);
    final semestersAsync = ref.watch(orderedSemestersProvider);
    final activeSemesterId = ref.watch(activeSemesterProvider).value;
    final coursesAsync = ref.watch(courseProvider);
    final deadlinesAsync = ref.watch(deadlinesProvider);
    final tasksAsync = ref.watch(tasksProvider);

    final displayName = resolveDisplayName(studentProfile, appUser, user);
    final avatarUrl = appUser?.avatarUrl;
    final email = appUser?.email ?? user?.email ?? '';

    final analytics = analyticsAsync.value;
    final summary = summaryAsync.value;
    final semesters = semestersAsync.value ?? [];
    final courses = coursesAsync.value ?? [];
    final deadlines = deadlinesAsync.value ?? [];
    final completedDeadlines = deadlines.where((d) => d.isCompleted).length;
    final totalDeadlines = deadlines.length;
    final tasks = tasksAsync.value ?? [];
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackgroundContainer(
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.transparent
                    : const Color(0xFFF1F5F9),
                forceMaterialTransparency: theme.brightness == Brightness.dark,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: const AppBackButton(),
                title: Text(
                  l10n.studentProfileSummaryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ── HERO ID CARD ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
                  ),
                  child: _StudentIdCard(
                    displayName: displayName,
                    email: email,
                    avatarUrl: avatarUrl,
                    major: studentProfile?.major,
                    universityName: studentProfile?.universityName,
                    degreeType: studentProfile?.degreeType,
                    academicYear: studentProfile?.academicYear != null
                        ? '${studentProfile!.academicYear}'
                        : null,
                    graduationYear: studentProfile?.expectedGraduationYear != null
                        ? '${studentProfile!.expectedGraduationYear}'
                        : null,
                    l10n: l10n,
                  ),
                ),
              ),

              // ── OVERVIEW STATS ───────────────────────────────────────────
              _SectionHeader(title: l10n.profileSummaryOverviewSection),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _CleanCard(
                    child: Column(
                      children: [
                        // Row 1: semesters | courses | GPA
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.calendarDays,
                                  value: '${semesters.length}',
                                  label: l10n.profileSemestersCount(semesters.length),
                                ),
                              ),
                              _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.bookOpen,
                                  value: '${courses.length}',
                                  label: l10n.profileCoursesCount(courses.length),
                                ),
                              ),
                              _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.trophy,
                                  value: analytics != null && analytics.averageGPA > 0
                                      ? analytics.averageGPA.toStringAsFixed(2)
                                      : l10n.profileNoGpaYet,
                                  label: l10n.profileGpaLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.12),
                        ),
                        // Row 2: CGPA | tasks | deadlines
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.chartBar,
                                  value: analytics != null && analytics.cumulativeGPA > 0
                                      ? analytics.cumulativeGPA.toStringAsFixed(2)
                                      : l10n.profileNoGpaYet,
                                  label: l10n.profileCgpaLabel,
                                ),
                              ),
                              _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.checkCircle,
                                  value: l10n.profileTaskSummary(
                                    completedTasks,
                                    totalTasks,
                                  ),
                                  label: l10n.tasks,
                                ),
                              ),
                              _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.flag,
                                  value: l10n.profileDeadlineSummary(
                                    completedDeadlines,
                                    totalDeadlines,
                                  ),
                                  label: l10n.deadlines,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── STUDY STATS ──────────────────────────────────────────────
              _SectionHeader(title: l10n.profileStudyStatsSection),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _CleanCard(
                    child: Column(
                      children: [
                        // Row 1: Sessions | Avg hrs/week | Consistency
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.clock,
                                  value: analytics != null
                                      ? '${analytics.totalTrackedSessions}'
                                      : l10n.profileNotSet,
                                  label: l10n.profileStudySessions,
                                ),
                              ),
                              const _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.chartBar,
                                  value: analytics != null && analytics.hasData
                                      ? analytics.weeklyAverageStudyHours
                                          .toStringAsFixed(1)
                                      : l10n.profileNotSet,
                                  label: l10n.profileWeeklyAvgHours,
                                ),
                              ),
                              const _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.bolt,
                                  value: analytics != null && analytics.hasData
                                      ? '${(analytics.consistency * 100).round()}%'
                                      : l10n.profileNotSet,
                                  label: l10n.profileStudyConsistency,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.12),
                        ),
                        // Row 2: This week | Weekly goal
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.fire,
                                  value: analytics != null
                                      ? '${analytics.studyHours.toStringAsFixed(1)} hrs'
                                      : l10n.profileNotSet,
                                  label: l10n.profileThisWeekHours,
                                ),
                              ),
                              const _VDivider(),
                              Expanded(
                                child: _StatCell(
                                  icon: HeroIcons.flag,
                                  value: analytics != null
                                      ? '${analytics.studyGoal.toStringAsFixed(1)} hrs'
                                      : l10n.profileNotSet,
                                  label: l10n.profileStudyGoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── SEMESTER HISTORY ─────────────────────────────────────────
              if (semesters.isNotEmpty) ...[
                _SectionHeader(title: l10n.profileSemesterHistorySection),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final semester = semesters[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _SemesterHistoryRow(
                            semester: semester,
                            activeSemesterId: activeSemesterId,
                            summary: summary,
                          ),
                        );
                      },
                      childCount: semesters.length,
                    ),
                  ),
                ),
              ],

              // ── ACTIVE SEMESTER COURSES ──────────────────────────────────
              if (courses.isNotEmpty) ...[
                _SectionHeader(title: l10n.profileCoursesThisSemester),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: _CleanCard(
                      child: Column(
                        children: [
                          for (int i = 0; i < courses.length; i++) ...[
                            _CourseRow(course: courses[i]),
                            if (i < courses.length - 1)
                              Divider(
                                height: 1,
                                indent: AppSpacing.lg + 20,
                                color: Theme.of(context).colorScheme.outline
                                    .withValues(alpha: 0.15),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ── PERFORMANCE HIGHLIGHTS ───────────────────────────────────
              _SectionHeader(title: l10n.profilePerformanceHighlightsSection),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _CleanCard(
                    child: _HighlightRow(
                      icon: HeroIcons.trophy,
                      title: l10n.profileBestSemester,
                      subtitle: summary?.bestSemester?.name,
                      value: summary?.highestGpa != null &&
                              summary!.highestGpa! > 0
                          ? summary.highestGpa!.toStringAsFixed(2)
                          : l10n.profileNotSet,
                      valueLabel: 'GPA',
                      valueColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg * 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Student ID card ───────────────────────────────────────────────────────────

class _StudentIdCard extends StatelessWidget {
  const _StudentIdCard({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.major,
    required this.universityName,
    required this.degreeType,
    required this.academicYear,
    required this.graduationYear,
    required this.l10n,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? major;
  final String? universityName;
  final String? degreeType;
  final String? academicYear;
  final String? graduationYear;
  final AppLocalizations l10n;

  static const double _avatarRadius = 46.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glass surface colours
    final glassTop = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.white.withValues(alpha: 0.72);
    final glassBottom = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.10)
        : theme.colorScheme.primary.withValues(alpha: 0.06);
    final borderTopColor =
        Colors.white.withValues(alpha: isDark ? 0.28 : 0.85);
    final dividerColor =
        Colors.white.withValues(alpha: isDark ? 0.10 : 0.40);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── 3-D shadow container ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: _avatarRadius),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg + 4),
              boxShadow: [
                // Deep lift shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
                  blurRadius: 40,
                  spreadRadius: -6,
                  offset: const Offset(0, 20),
                ),
                // Primary ambient glow
                BoxShadow(
                  color: theme.colorScheme.primary
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                // Top-edge specular (white highlight for 3D)
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.50),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            // ── Frosted glass surface ─────────────────────────────────
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg + 4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [glassTop, glassBottom],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg + 4),
                    border: Border.all(color: borderTopColor, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Inner top-edge highlight (light refracting off glass)
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(
                                    alpha: isDark ? 0.55 : 0.95),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          // Space for avatar overlap
                          const SizedBox(height: _avatarRadius + AppSpacing.sm),

                          // Full name
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Text(
                              displayName.toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Email
                          Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (major != null && major!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _IdRow(
                              icon: HeroIcons.bookOpen,
                              text: major!,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.90)
                                  : theme.colorScheme.primary,
                            ),
                          ],

                          if (universityName != null &&
                              universityName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _IdRow(
                              icon: HeroIcons.buildingLibrary,
                              text: universityName!,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.60)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.70),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.lg),

                          // Gradient divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.primary
                                      .withValues(alpha: isDark ? 0.7 : 0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // 3-column academic info
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AcademicCell(
                                    label: l10n.degreeType,
                                    value: degreeType ?? l10n.profileNotSet,
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: dividerColor,
                                ),
                                Expanded(
                                  child: _AcademicCell(
                                    label: l10n.academicYear,
                                    value: academicYear ?? l10n.profileNotSet,
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: dividerColor,
                                ),
                                Expanded(
                                  child: _AcademicCell(
                                    label: 'GRADUATION',
                                    value:
                                        graduationYear ?? l10n.profileNotSet,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Avatar — floats at top center, half outside the card
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.80),
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 14,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? AppIcon(HeroIcons.user, size: 44, color: theme.colorScheme.primary)
                : null,
          ),
        ),
      ],
    );
  }
}

class _IdRow extends StatelessWidget {
  const _IdRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final HeroIcons icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AcademicCell extends StatelessWidget {
  const _AcademicCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Clean card ────────────────────────────────────────────────────────────────

class _CleanCard extends StatelessWidget {
  const _CleanCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.08 : 0.60),
                Colors.white.withValues(alpha: isDark ? 0.03 : 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.65),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.07),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final HeroIcons icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Vertical divider ──────────────────────────────────────────────────────────

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
    );
  }
}

// ── Highlight row ─────────────────────────────────────────────────────────────

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
    this.valueLabel,
  });

  final HeroIcons icon;
  final String title;
  final String? subtitle;
  final String value;
  final Color valueColor;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Semester history row ──────────────────────────────────────────────────────

class _SemesterHistoryRow extends ConsumerWidget {
  const _SemesterHistoryRow({
    required this.semester,
    required this.activeSemesterId,
    required this.summary,
  });

  final Semester semester;
  final String? activeSemesterId;
  final PerformanceSummary? summary;

  String _dateLabel(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isActive = semester.id == activeSemesterId;
    final countAsync = ref.watch(courseCountForSemesterProvider(semester.id));

    SemesterPerformance? perf;
    if (summary != null) {
      for (final h in summary!.history) {
        if (h.semester.id == semester.id) {
          perf = h;
          break;
        }
      }
    }
    final gpa = perf?.data.averageGPA ?? 0.0;
    final gpaText = gpa > 0 ? gpa.toStringAsFixed(2) : l10n.profileNoGpaYet;

    final courseCountText = countAsync.when(
      data: (n) => l10n.profileCoursesCount(n),
      loading: () => '—',
      error: (e, st) => '—',
    );

    return _CleanCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Row(
          children: [
            // Active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 3,
              height: 56,
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppIcon(
                HeroIcons.calendarDays,
                size: 16,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            semester.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.currentSemesterLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_dateLabel(semester.startDate)} – ${_dateLabel(semester.endDate)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GPA $gpaText',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gpa > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    courseCountText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course row ────────────────────────────────────────────────────────────────

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = course.uiColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              course.courseName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (course.courseCode != null && course.courseCode!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                course.courseCode!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
