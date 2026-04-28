// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_glass_card.dart';
import 'widgets/active_session_view.dart';
import 'widgets/live_study_session_card.dart';
import '../../components/app_bottom_sheet_picker.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../providers/study_sessions_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/student_profile_provider.dart';
import '../../providers/decision_provider.dart';
import '../../providers/decision_engine_provider_v2.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../domain/decision/decision_rules.dart';
import 'study_history_screen.dart';

// ─── Minimum / Maximum session constraints ───────────────────────
const int _kMinMinutes = 10;
const int _kMaxMinutes = 240;

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  ProviderSubscription? _timerSub;
  ProviderSubscription<AdaptationMode>? _modeSub;
  ProviderSubscription<MoodPromptRequest?>? _moodPromptSub;
  bool _handledAnalyticsArgs = false;

  @override
  void initState() {
    super.initState();
    
    _timerSub = ref.listenManual(studyTimerProvider, (prev, next) {
      if (next.isCompleted && prev?.isCompleted != true) {
        debugPrint("LISTENER FIRED → (no save, provider handles it)");
      }
    });

    _modeSub = ref.listenManual<AdaptationMode>(
      studyAdaptationModeProvider,
      (previous, next) {
        if (!mounted) return;
        final timerState = ref.read(studyTimerProvider);
        final isIdle =
            !timerState.isRunning && !timerState.isPaused && !timerState.isCompleted;
        if (!isIdle) return;

        final analytics = ref.read(studyAnalyticsProvider);
        final minutes = _recommendedDurationForMode(analytics, next, ref);
        ref.read(studyTimerProvider.notifier).setDuration(Duration(minutes: minutes));
      },
    );

    _moodPromptSub = ref.listenManual<MoodPromptRequest?>(
      moodPromptRequestProvider,
      (previous, next) {
        if (!mounted || next == null) return;
        ref.read(moodActionsProvider).clearMoodPrompt();
        context.push('/mood/log?source=${next.source}');
      },
    );

    // Auto-apply suggested duration on screen load if idle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final timerState = ref.read(studyTimerProvider);
        final bool isIdle = !timerState.isRunning && !timerState.isPaused && !timerState.isCompleted;
        if (isIdle) {
          final notifier = ref.read(studyTimerProvider.notifier);
          final profile = ref.read(studentProfileProvider).valueOrNull;
          final breakPattern = profile?.breakPattern ?? 'mixed';
          notifier.setStudyType(_studyTypeFromPattern(breakPattern));
          
          // Unified logic: prioritize decisionProvider minutes
          final decision = ref.read(decisionProvider);
          final suggested = decision.suggestedSessionMinutes;
          
          if (suggested != null) {
            notifier.setDuration(Duration(minutes: suggested));
          } else {
            final analytics = ref.read(studyAnalyticsProvider);
            final adaptationMode = ref.read(studyAdaptationModeProvider);
            notifier.setDuration(
              Duration(
                minutes: _recommendedDurationForMode(analytics, adaptationMode, ref),
              ),
            );
          }
        }
      }
    });
  }

  StudyType _studyTypeFromPattern(String pattern) {
    switch (pattern) {
      case 'pomodoro':
        return StudyType.pomodoro;
      case 'deep_work':
        return StudyType.deepWork;
      default:
        return StudyType.review;
    }
  }

  String _preferredTimeLabel(AppLocalizations l10n, String? preferredTime) {
    switch (preferredTime) {
      case 'night':
        return l10n.night;
      case 'afternoon':
        return l10n.afternoon;
      default:
        return l10n.morning;
    }
  }

  String _breakPatternLabel(AppLocalizations l10n, String? breakPattern) {
    switch (breakPattern) {
      case 'pomodoro':
        return l10n.pomodoro;
      case 'deep_work':
        return l10n.deepWork;
      default:
        return l10n.mixed;
    }
  }

  int _roundPlanMinutes(double minutes) {
    if (minutes <= 0) return 0;
    return ((minutes / 5).ceil() * 5).clamp(5, 240);
  }

  int _roundToFive(double minutes) {
    if (minutes <= 0) return 0;
    return ((minutes / 5).round() * 5).clamp(5, 240);
  }

  int _recommendedDurationForMode(StudyAnalytics analytics, AdaptationMode mode, WidgetRef ref) {
    final stress = ref.read(analyticsProvider).value?.avgSessionStress ?? 0.0;
    if (mode == AdaptationMode.followBehavior) {
      return DecisionRules.getRecommendedSessionLength(stress);
    }
    return 60;
  }

  double _weeklyGoalHours(StudyAnalytics analytics) {
    return analytics.weeklyGoalMinutes / 60.0;
  }

  double _dailyTargetHours(StudyAnalytics analytics) {
    final weekHours = _currentWeekHours(analytics);
    final remainingWeeklyHours = (_weeklyGoalHours(analytics) - weekHours)
        .clamp(0.0, 40.0);
    final remainingDays = (8 - DateTime.now().weekday).clamp(1, 7);
    final dailyTarget = remainingWeeklyHours / remainingDays;
    return dailyTarget.clamp(0.0, 3.0);
  }

  double _currentWeekHours(StudyAnalytics analytics) {
    final thisWeekMinutes = analytics.weeklyTotals['thisWeek'] ?? 0;
    return thisWeekMinutes / 60.0;
  }

  double _expectedHoursByToday(StudyAnalytics analytics) {
    final weekday = DateTime.now().weekday.clamp(1, 7);
    final expectedMinutes = (analytics.weeklyGoalMinutes * (weekday / 7.0));
    return expectedMinutes / 60.0;
  }

  @override
  void dispose() {
    _timerSub?.close();
    _modeSub?.close();
    _moodPromptSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timerState = ref.watch(studyTimerProvider);
    final analytics = ref.watch(studyAnalyticsProvider);

    // States
    final bool isIdle =
        !timerState.isRunning &&
        !timerState.isPaused &&
        !timerState.isCompleted;
    final bool isActive = timerState.isRunning || timerState.isPaused;
    final bool isCompleted = timerState.isCompleted;

    // ─── AUDIT FIX: Navigation Execution & Data Passing ───────────
    if (!_handledAnalyticsArgs) {
      try {
        final routeState = GoRouterState.of(context);
        final extra = routeState.extra as Map<String, dynamic>?;
        if (extra != null && extra['source'] == 'analytics') {
          _handledAnalyticsArgs = true; // Mark as handled
          final stress = ref.read(analyticsProvider).value?.avgSessionStress ?? 0.0;
          final suggested = (extra['duration'] as int?) ?? DecisionRules.getRecommendedSessionLength(stress);
          if (isIdle && timerState.targetDuration.inMinutes != suggested) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref.read(studyTimerProvider.notifier).setDuration(
                Duration(minutes: suggested),
              );
            });
          }
        }
      } catch (_) {}
    }

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          top: false,
          bottom: false, // Allow full-screen overlay for active session
          child: Stack(
            children: [
              // Main Dashboard View (Visible when idle or completed)
              AnimatedOpacity(
                opacity: isActive ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: isActive,
                  child: SingleChildScrollView(
                    key: const ValueKey('dashboard'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.of(context).padding.top + 8,
                      AppSpacing.lg,
                      160,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isIdle)
                          _buildIdleState(context, ref, theme, l10n, timerState, analytics),
                        if (isCompleted)
                          _buildCompleteState(
                              context, ref, theme, l10n, timerState, analytics),
                      ],
                    ),
                  ),
                ),
              ),

              if (isActive)
                Container(
                  color: theme.scaffoldBackgroundColor,
                  width: double.infinity,
                  height: double.infinity,
                  child: const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: ActiveSessionView(),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER (Active State Only) ─────────────────────────────────
  Widget _buildActiveHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    StudyTimerState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final courses = ref.watch(courseProvider).value ?? [];
    final course = courses.where((c) => c.id == state.courseId).firstOrNull;
    final typeColor = _getTypeColor(state.sessionType);

    final label = _getSessionLabel(context, state);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            if (course != null)
              Text(
                '${course.courseCode} • ${course.courseName}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              )
            else
              Text(
                l10n.noCourseSelected,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: -0.2);
  }

  // ─── 1. IDLE STATE ──────────────────────────────────────────────
  Widget _buildIdleState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    StudyTimerState state,
    StudyAnalytics analytics,
  ) {
    final canStart = state.courseId != null &&
        state.targetDuration.inMinutes >= _kMinMinutes;
    final decisionAsync = ref.watch(decisionEngineActiveProvider);
    final sessionsToday = (ref.watch(studySessionsProvider).valueOrNull ?? const [])
        .where((s) {
          final now = DateTime.now();
          return s.createdAt.year == now.year &&
              s.createdAt.month == now.month &&
              s.createdAt.day == now.day;
        })
        .toList();
    final adaptationMode = ref.watch(studyAdaptationModeProvider);
    final profile = ref.watch(studentProfileProvider).valueOrNull;
    final decision = ref.watch(decisionProvider);
    final suggestedMinutes = decision.suggestedSessionMinutes ?? _recommendedDurationForMode(analytics, adaptationMode, ref);
    final followBehavior = adaptationMode == AdaptationMode.followBehavior;
    final dominantSlot = analytics.dominantStudyTime;
    final hasStableSignal = analytics.hasReliableBehaviorSignal;
    final recommendedSlot =
      adaptationMode == AdaptationMode.followBehavior && hasStableSignal
        ? (dominantSlot ?? profile?.preferredStudyTime)
        : profile?.preferredStudyTime;
    final dailyTargetHours = _dailyTargetHours(analytics);
    final weekHours = _currentWeekHours(analytics);
    final expectedHours = _expectedHoursByToday(analytics);
    final isBehindGoal = weekHours < expectedHours;
    final adaptiveHintTime = analytics.adaptiveHintStudyTime;
    final morningCount = analytics.sessionsForSlot('morning');
    final afternoonCount = analytics.sessionsForSlot('afternoon');
    final nightCount = analytics.sessionsForSlot('night');
    final behaviorConfidence = analytics.behaviorConfidence.toInt();
    final preferenceConfidence = analytics.preferenceConfidence.toInt();
    final weeklyDeficitHours = analytics.weeklyDeficitHours;
    final weeklyGoalHours = analytics.weeklyGoalHours;
    final inconsistencyScore = analytics.timeInconsistencyScore.toInt();
    final irregularPattern = analytics.irregularStudyPattern;
    final recoveryDetected = analytics.recoveryDetected;
    final hasBurnoutTrendHistory = analytics.hasBurnoutTrendHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LiveStudySessionCard(),
        const SizedBox(height: AppSpacing.lg),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.study,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  l10n.todayMinutesCompleted(analytics.todayMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: AppIcon(
                HeroIcons.clock,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: l10n.recentStudySessions,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudyHistoryScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recommendedForYouTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<AdaptationMode>(
                segments: [
                  ButtonSegment<AdaptationMode>(
                    value: AdaptationMode.keepPreference,
                    label: Text(l10n.keepMyPreference),
                  ),
                  ButtonSegment<AdaptationMode>(
                    value: AdaptationMode.followBehavior,
                    label: Text(l10n.followActualBehavior),
                  ),
                ],
                showSelectedIcon: true,
                emptySelectionAllowed: false,
                selected: {adaptationMode},
                onSelectionChanged: (selection) {
                  final next = selection.first;
                  ref.read(studyAdaptationModeProvider.notifier).setMode(next);
                  ref
                      .read(studyTimerProvider.notifier)
                      .setDuration(
                        Duration(
                          minutes: _recommendedDurationForMode(analytics, next, ref),
                        ),
                      );
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.resolveWith((states) {
                    return theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.bestStudyTimeBullet(_preferredTimeLabel(l10n, recommendedSlot)),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                followBehavior
                    ? l10n.suggestedShorterSessionsToday
                    : l10n.suggestedFlexibleSessionsToday,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              if (decision.avgSessionStress >= 7)
                Text(
                  l10n.recoveryMessageStressHigh,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (isBehindGoal)
                Text(
                  l10n.needHoursTodayToStayOnTrack(
                    '~${dailyTargetHours.toStringAsFixed(1)}',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Text(
                  l10n.dailyTargetNeededBullet(dailyTargetHours.toStringAsFixed(1)),
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 4),
              Text(
                l10n.burnoutInputsHumanized(
                  weeklyDeficitHours.toStringAsFixed(1),
                  inconsistencyScore,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (irregularPattern)
                Text(
                  l10n.patternIrregularThisWeek,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (adaptiveHintTime != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.adaptiveHintRecentStudyTime(
                    _preferredTimeLabel(l10n, adaptiveHintTime),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.weekSessionsBreakdown(morningCount, afternoonCount, nightCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.confidenceBreakdown(
                    behaviorConfidence,
                    preferenceConfidence,
                    dominantSlot != null
                        ? l10n.trendDeltaVsLastWeek(
                            analytics.slotTrendDelta(dominantSlot) >= 0
                                ? '+${analytics.slotTrendDelta(dominantSlot)}'
                                : analytics.slotTrendDelta(dominantSlot).toString(),
                          )
                        : '',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
              if (recoveryDetected) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    l10n.recoveryImprovingThisWeek,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  hasBurnoutTrendHistory
                      ? l10n.noRecoveryTrendDetectedYet
                      : l10n.notEnoughDataTrendYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        decisionAsync.when(
          data: (snapshot) {
            final secondMinutes =
                _roundToFive(snapshot.nextAction.durationMinutes * 0.67);
            final courseMinutesToday = <String, int>{};
            for (final session in sessionsToday) {
              courseMinutesToday[session.courseId] =
                  (courseMinutesToday[session.courseId] ?? 0) +
                      session.durationMinutes;
            }

            final firstDone =
                courseMinutesToday[snapshot.nextAction.courseId] ?? 0;
            final secondPlan =
              snapshot.todayPlanSecondaryRecommendation ?? snapshot.focusRecommendation;
            final secondCourseId = secondPlan?.courseId;
            final secondDone = secondCourseId == null
                ? 0
                : (courseMinutesToday[secondCourseId] ?? 0);

            return AppGlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.todayPlanTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStudyPlanRow(
                    context: context,
                    done: firstDone >= snapshot.nextAction.durationMinutes,
                    minutes: snapshot.nextAction.durationMinutes,
                    course: snapshot.nextAction.courseName,
                    remainingMinutes:
                        (snapshot.nextAction.durationMinutes - firstDone)
                            .clamp(0, 240),
                  ),
                  if (secondPlan != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildStudyPlanRow(
                      context: context,
                      done: secondDone >= secondMinutes,
                      minutes: secondMinutes,
                      course: secondPlan.courseName,
                      remainingMinutes:
                          (secondMinutes - secondDone).clamp(0, 240),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),

        if (profile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${l10n.preferredStudyTime}: ${_preferredTimeLabel(l10n, profile.preferredStudyTime)} • ${l10n.breakPattern}: ${_breakPatternLabel(l10n, profile.breakPattern)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // 1.1 Session Type
        Text(l10n.sessionType, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildSessionTypeSelector(ref, state, context),
        const SizedBox(height: AppSpacing.lg),

        // 1.2 Course
        Text(l10n.selectCourse, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildCourseDropdown(context, ref, state),
        const SizedBox(height: AppSpacing.lg),

        // 1.2.1 Intent Tag
        Text(l10n.studyIntent, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.studyIntentHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          onChanged: (val) => ref.read(studyTimerProvider.notifier).setIntent(val),
          decoration: InputDecoration(
            hintText: l10n.studyIntentPlaceholder,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1.2 Course
        // 1.3 Duration
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.duration, style: theme.textTheme.titleSmall),
            if (state.sessionType == StudyType.pomodoro)
              Text(
                l10n.structuredSession,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              )
            else
              Text(
                l10n.endsAt(_formatEndTime(state.targetDuration)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),

        if (state.sessionType == StudyType.pomodoro) ...[
          const SizedBox(height: 12),
          _buildPomodoroInfo(context, theme, l10n, state),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          _buildDurationSelector(context, ref, state),
          if (state.targetDuration.inMinutes < _kMinMinutes) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.minimumSessionMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),

        // 1.3.2 Weekly Progress Visualization
        Text(l10n.weeklyGoalProgress, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        ref.watch(dashboardProvider).when(
              data: (dash) {
                final progress = dash.weeklyStudyGoalMinutes > 0
                    ? (dash.weeklyStudyCompletedMinutes / dash.weeklyStudyGoalMinutes).clamp(0.0, 1.0)
                    : 0.0;
                return AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.minutesDone(dash.weeklyStudyCompletedMinutes),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.weeklyGoalTag(dash.weeklyStudyGoalMinutes),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (error, stack) => const SizedBox(height: 60),
            ),

        const SizedBox(height: AppSpacing.xl),

        if (decision.suggestedSessionMinutes != null) ...[
          Text(
            l10n.decisionRecommendedSession(decision.suggestedSessionMinutes!),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: l10n.startRecommendedSession(decision.suggestedSessionMinutes!),
            onPressed: canStart
                ? () {
                    Haptics.vibrate(HapticsType.medium);
                    ref
                        .read(studyTimerProvider.notifier)
                        .setDuration(Duration(minutes: decision.suggestedSessionMinutes!));
                    ref.read(studyTimerProvider.notifier).start();
                  }
                : null,
            isFullWidth: true,
            variant: AppButtonVariant.secondary,
            icon: const AppIcon(HeroIcons.sparkles, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 1.4 Start Button + helper
        AppButton(
          text: l10n.start,
          onPressed: canStart
              ? () {
                  Haptics.vibrate(HapticsType.medium);
                  ref.read(studyTimerProvider.notifier).start();
                }
              : null,
          isFullWidth: true,
          icon: const AppIcon(HeroIcons.play, size: 20, color: Colors.white),
        ),


        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            state.courseId == null
                ? l10n.selectCourseToStart
                : l10n.minimumSessionMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudyPlanRow({
    required BuildContext context,
    required bool done,
    required int minutes,
    required String course,
    required int remainingMinutes,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        AppIcon(
          done ? HeroIcons.checkCircle : HeroIcons.minusCircle,
          size: 16,
          color: done
              ? Colors.green
              : theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '$minutes min $course',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!done)
          Text(
            l10n.minutesRemainingShort(remainingMinutes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildPomodoroInfo(BuildContext context, ThemeData theme, AppLocalizations l10n, StudyTimerState state) {
    final focusMinutes = 25 * state.totalRounds;
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _buildPomodoroStepRow(
            context,
            Icons.center_focus_strong_rounded,
            l10n.pomodoroFocusStep,
          ),
          const SizedBox(height: 8),
          _buildPomodoroStepRow(
            context,
            Icons.coffee_rounded,
            l10n.pomodoroBreakStep,
          ),
          const SizedBox(height: 8),
          _buildPomodoroStepRow(
            context,
            Icons.repeat_rounded,
            l10n.pomodoroRepeatStep,
          ),
          const Divider(height: 24, thickness: 0.5),
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pomodoroTotalFocusSummary(focusMinutes),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Duration _getPomodoroTotalDuration(StudyTimerState state) {
    if (state.sessionType != StudyType.pomodoro) return state.targetDuration;
    // 4 rounds of focus (25m) + 3 breaks (5m)
    const focusMin = 25;
    const breakMin = 5;
    final totalMin = (focusMin * state.totalRounds) + (breakMin * (state.totalRounds - 1));
    return Duration(minutes: totalMin);
  }

  // ─── 2. ACTIVE STATE ───────────────────────────────────────────
  Widget _buildActiveState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    StudyTimerState state,
    StudyAnalytics analytics,
  ) {
    // Dynamic motivation line logic
    final Duration remaining = state.targetDuration - state.elapsed;
    final int remainingSecs = remaining.inSeconds;
    final int targetSecs = state.targetDuration.inSeconds;
    
    final bool isHalfway = targetSecs > 0 && remainingSecs < (targetSecs / 2);
    final bool isNearEnd = remainingSecs < 60;
    
    final motivationMsg = isNearEnd 
        ? l10n.almostDoneMsg 
        : (isHalfway ? l10n.halfwayMsg : l10n.stayFocusedMsg);

    return Column(
      children: [
        const SizedBox(height: 40),
        _FocusTimerCircle(state: state),
        const SizedBox(height: 60),

        const SizedBox(height: 16),
        
        // Session Context & Motivation
        if (state.sessionType == StudyType.pomodoro)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.totalRounds, (index) {
              final isCurrent = index == (state.currentRound - 1);
              final isDone = index < (state.currentRound - 1);
              final activeColor = state.isBreak ? Colors.green : theme.colorScheme.primary;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone 
                    ? activeColor.withValues(alpha: 0.8)
                    : isCurrent 
                      ? activeColor 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  boxShadow: isCurrent ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
              );
            }),
          )
        else
          Text(
            l10n.deepFocus,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),

        const SizedBox(height: 16),
        
        // Single Active Motivation Line
        Text(
          motivationMsg,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 40),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: () {
                Haptics.vibrate(HapticsType.selection);
                ref.read(studyTimerProvider.notifier).stop();
              },
              icon: const AppIcon(HeroIcons.stop, size: 28),
              style: IconButton.styleFrom(
                minimumSize: const Size(64, 64),
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            GestureDetector(
              onTap: () {
                if (state.isRunning) {
                  ref.read(studyTimerProvider.notifier).pause();
                } else {
                  ref.read(studyTimerProvider.notifier).resume();
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: AppIcon(
                  state.isRunning ? HeroIcons.pause : HeroIcons.play,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 3. COMPLETE STATE (Production-grade) ──────────────────────
  Widget _buildPomodoroStepRow(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }


  Widget _buildCompleteState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    StudyTimerState state,
    StudyAnalytics analytics,
  ) {
    if (state.elapsed.inMinutes < _kMinMinutes &&
        state.sessionType != StudyType.pomodoro) {
      return Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.error.withValues(alpha: 0.1),
            ),
            child: AppIcon(
              HeroIcons.exclamationTriangle,
              size: 40,
              color: theme.colorScheme.error,
            ),
          ).animate().shake(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.sessionTooShort,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              l10n.sessionTooShortDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            onPressed: () => ref.read(studyTimerProvider.notifier).reset(),
            text: l10n.tryAgain,
            isFullWidth: true,
          ),
        ],
      );
    }

    final isPomodoro = state.sessionType == StudyType.pomodoro;
    final courses = ref.watch(courseProvider).value ?? [];
    final course = courses.where((c) => c.id == state.courseId).firstOrNull;
    
    // For Pomodoro, use cumulative. For standard, use elapsed.
    final int displayMinutes = isPomodoro 
        ? state.totalFocusAccumulated.clamp(1, 999) 
        : state.elapsed.inMinutes.clamp(_kMinMinutes, 999);
        
    final focusLevel = _calculateFocusLevel(l10n, state.elapsed);
    final sessionTypeLabel = isPomodoro ? l10n.pomodoro : _formatSessionType(context, state.sessionType);
    final courseName = course?.courseName ?? l10n.noCourseSelected;

    final dashData = ref.watch(dashboardProvider);
    final int streakCount = dashData.valueOrNull?.streakCount ?? 0;

    return Column(
      children: [
        const SizedBox(height: 40),

        // 1. Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: AppIcon(
            HeroIcons.checkCircle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: AppDurations.slow,
              curve: Curves.elasticOut,
            )
            .fade(duration: AppDurations.normal),

        const SizedBox(height: AppSpacing.lg),

        // 2. Header
        Text(
          isPomodoro ? l10n.pomodoroCompleted : l10n.sessionCompleted,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

        const SizedBox(height: AppSpacing.md),

        // 3. Big stat
        Text(
          '${displayMinutes}m',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
            color: theme.colorScheme.primary,
          ),
        ).animate().fade(delay: 300.ms).scale(
              begin: const Offset(0.8, 0.8),
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: AppSpacing.xs),

        if (isPomodoro)
          Text(
            l10n.cyclesCompleted(state.completedCycles),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1)
        else
          Text(
            l10n.youStayedFocused(displayMinutes),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fade(delay: 400.ms),

        const SizedBox(height: AppSpacing.xl),

        if (isPomodoro) ...[
          // Cycle Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isDone = index < state.completedCycles;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ).animate().fade(delay: 450.ms).scaleX(),
          const SizedBox(height: AppSpacing.xl),
        ],

        // 4. Metadata row
        AppGlassCard(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CompletionStatChip(
                icon: HeroIcons.bolt,
                label: sessionTypeLabel,
              ),
              Container(
                width: 1,
                height: 28,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              _CompletionStatChip(
                icon: HeroIcons.bookOpen,
                label: courseName,
                maxWidth: 100,
              ),
            ],
          ),
        ).animate().fade(delay: 500.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.md),

        if (state.intent == 'analytics_recommendation') ...[
          AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  l10n.sessionImpactAddedToCourse(displayMinutes, courseName),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.sessionImpactCloserToGoal,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fade(delay: 520.ms).slideY(begin: 0.05),
          const SizedBox(height: AppSpacing.md),
        ],

        // 5. Progress context (today + weekly)
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (isPomodoro) ...[
                _ProgressRow(
                  leftLabel: l10n.focusTimeBreakdown(displayMinutes),
                  progress: 1.0,
                  color: theme.colorScheme.primary,
                  showTrack: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProgressRow(
                  leftLabel: l10n.breakTimeBreakdown(state.totalBreakAccumulated),
                  progress: 1.0,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  showTrack: false,
                ),
                const Divider(height: 24, thickness: 0.5),
              ],
              // Today progress
              _ProgressRow(
                leftLabel: l10n.today,
                rightLabel: l10n.minutesFocused(analytics.todayMinutes),
                progress: (analytics.todayMinutes / 120).clamp(0.0, 1.0),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressRow(
                leftLabel: l10n.thisWeekLabel,
                rightLabel: l10n.sessionsCount(analytics.sessionsThisWeek),
                progress: (analytics.sessionsThisWeek / 20).clamp(0.0, 1.0),
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ).animate().fade(delay: 550.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.md),

        // 6. Streak + Insight row
        Row(
          children: [
            // Streak
            Expanded(
              child: AppGlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🔥',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        streakCount > 0
                            ? l10n.streakDaysInARow(streakCount)
                            : l10n.noStreak,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF6B35),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Weekly goal pill
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    l10n.addedToWeeklyGoal(displayMinutes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fade(delay: 650.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.md),

        // 8. Actions
        AppButton(
          onPressed: () => ref.read(studyTimerProvider.notifier).reset(),
          text: l10n.startAnotherSession,
          isFullWidth: true,
          icon: const AppIcon(HeroIcons.play, size: 20, color: Colors.white),
        ).animate().fade(delay: 800.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.lg),

        Center(
          child: GestureDetector(
            onTap: () {
              ref.read(studyTimerProvider.notifier).reset();
              ref.read(bottomNavProvider.notifier).state = 0;
              context.go('/home');
            },
            child: Text(
              '← Back to Dashboard',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ).animate().fade(delay: 900.ms),

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  String _formatEndTime(Duration sessionDuration) {
    final end = DateTime.now().add(sessionDuration);
    final hour = end.hour.toString().padLeft(2, '0');
    final minute = end.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ─── HELPERS ────────────────────────────────────────────────────

  String _calculateFocusLevel(AppLocalizations l10n, Duration elapsed) {
    final minutes = elapsed.inMinutes;
    if (minutes < 15) return l10n.lowFocus;
    if (minutes < 40) return l10n.goodFocus;
    return l10n.deepFocus;
  }


  /// Smarter insight based on elapsed time.
  String _sessionInsight(AppLocalizations l10n, Duration elapsed) {
    if (elapsed.inMinutes < 10) {
      return 'This session was too short to be effective. Try at least 20 minutes next time.';
    }
    if (elapsed.inMinutes < 30) {
      return 'A solid start — aim for 30+ minutes to build deeper focus habits.';
    }
    return 'Great discipline. Sessions like this build real long-term progress.';
  }

  /// Format minutes to compact string — shows hours only when >= 60m.
  /// e.g. 25 → "25m", 129 → "2h", 60 → "1h"
  String _formatMinutesCompact(int totalMinutes) {
    if (totalMinutes >= 60) {
      final h = totalMinutes ~/ 60;
      return '${h}h';
    }
    return '${totalMinutes}m';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSessionType(BuildContext context, StudyType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case StudyType.pomodoro:
        return l10n.pomodoro;
      case StudyType.deepWork:
        return l10n.deepWork;
      case StudyType.review:
        return l10n.review;
    }
  }

  String _getSessionLabel(BuildContext context, StudyTimerState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.sessionType != StudyType.pomodoro) {
      return _formatSessionType(context, state.sessionType);
    }

    if (state.isBreak) {
      return state.currentRound == state.totalRounds
          ? l10n.longBreakLabel
          : l10n.breakLabel;
    }

    return l10n.focusSessionCount(state.currentRound, state.totalRounds);
  }

  Color _getTypeColor(StudyType type) {
    switch (type) {
      case StudyType.pomodoro:
        return Colors.orange;
      case StudyType.deepWork:
        return Colors.blue;
      case StudyType.review:
        return Colors.green;
    }
  }

  Widget _buildSessionTypeSelector(
    WidgetRef ref,
    StudyTimerState state,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final types = [StudyType.pomodoro, StudyType.deepWork, StudyType.review];

    return Row(
      children: types.map((type) {
        final isSelected = state.sessionType == type;
        final color = _getTypeColor(type);
        final isRecommended =
            state.targetDuration.inMinutes == getDefaultDuration(type);

        return Expanded(
          child: GestureDetector(
            onTap: () {
              Haptics.vibrate(HapticsType.selection);
              ref.read(studyTimerProvider.notifier).setStudyType(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatSessionType(context, type),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : null,
                    ),
                  ),
                  if (isSelected && isRecommended) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.recommended.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 0.5,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseDropdown(
    BuildContext context,
    WidgetRef ref,
    StudyTimerState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final courses = ref.watch(activeCoursesProvider);
    String selectedName = l10n.chooseACourse;
    Color? selectedCourseColor;
    final options = <AppPickerOption<String>>[];
    for (final c in courses) {
      options.add(
        AppPickerOption(
          value: c.id,
          title: c.courseName,
          subtitle: c.courseCode,
          swatchColor: c.uiColor,
        ),
      );
      if (c.id == state.courseId) {
        selectedName = c.courseName;
        selectedCourseColor = c.uiColor;
      }
    }

    return AppBottomSheetPicker<String>(
      icon: HeroIcons.bookOpen,
      fieldLabel: l10n.course,
      sheetTitle: l10n.chooseACourse,
      selectedValue: state.courseId,
      selectedDisplayText: selectedName,
      selectedSwatchColor: selectedCourseColor,
      options: options,
      onChanged: (val) =>
          ref.read(studyTimerProvider.notifier).setCourseId(val),
      emptyText: l10n.noCoursesYet,
    );
  }

  // ─── DURATION SELECTOR (with Custom + validation) ─────────────
  Widget _buildDurationSelector(
    BuildContext context,
    WidgetRef ref,
    StudyTimerState state,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentMinutes = state.targetDuration.inMinutes;
    final isPomodoro = state.sessionType == StudyType.pomodoro;

    if (isPomodoro) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildDurationChip(10, currentMinutes, theme, l10n, ref),
        _buildDurationChip(25, currentMinutes, theme, l10n, ref),
        _buildDurationChip(45, currentMinutes, theme, l10n, ref),
        _buildDurationChip(60, currentMinutes, theme, l10n, ref),
        _buildDurationChip(90, currentMinutes, theme, l10n, ref),
        _buildCustomChip(context, currentMinutes, theme, l10n, ref, state),
      ],
    );
  }

  Widget _buildDurationChip(
    int duration,
    int currentMinutes,
    ThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final isSelected = currentMinutes == duration;
    return GestureDetector(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
        ref.read(studyTimerProvider.notifier).setDuration(Duration(minutes: duration));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          '$duration${l10n.minutesAbbreviation}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip(
    BuildContext context,
    int currentMinutes,
    ThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
    StudyTimerState state,
  ) {
    final presetDurations = [10, 25, 45, 60, 90];
    final isCustom = !presetDurations.contains(currentMinutes);

    return GestureDetector(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
        _showCustomDurationSheet(context, ref, state);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.1),
            width: isCustom ? 1.5 : 1.0,
          ),
          boxShadow: isCustom
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          isCustom ? l10n.customDurationLabel(currentMinutes) : l10n.custom,
          style: TextStyle(
            fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
            color: isCustom ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  void _showCustomDurationSheet(
    BuildContext context,
    WidgetRef ref,
    StudyTimerState state,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: state.targetDuration.inMinutes
          .clamp(_kMinMinutes, _kMaxMinutes)
          .toString(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.xl),
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                l10n.duration,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Helper text
              Text(
                l10n.durationRangeHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Number input
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: l10n.enterMinutes,
                  suffixText: l10n.minutesAbbreviation,
                  suffixStyle: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick presets
              Text(
                l10n.quickPresets,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [15, 30, 120].map((preset) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.text = preset.toString();
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.04),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$preset${l10n.minutesAbbreviation}',
                            style:
                                theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Set button
              AppButton(
                text: l10n.setDuration,
                isFullWidth: true,
                onPressed: () {
                  final raw = int.tryParse(controller.text) ?? _kMinMinutes;
                  final clamped = raw.clamp(_kMinMinutes, _kMaxMinutes);
                  ref
                      .read(studyTimerProvider.notifier)
                      .setDuration(Duration(minutes: clamped));
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildActiveSessionStats(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    StudyTimerState state,
    StudyAnalytics analytics,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActiveStatMiniCard(
                label: l10n.focusScore,
                value: "${analytics.focusScore}%",
                icon: HeroIcons.bolt,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActiveStatMiniCard(
                label: l10n.status,
                value: analytics.isStable ? l10n.statusStable : l10n.statusVariable,
                icon: HeroIcons.signal,
                color: analytics.isStable ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        if (state.intent != null && state.intent!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            child: Row(
              children: [
                AppIcon(HeroIcons.tag, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.studyIntent,
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.intent!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


// ─── REUSABLE PRIVATE WIDGETS ────────────────────────────────────

class _FocusTimerCircle extends StatelessWidget {
  final StudyTimerState state;
  const _FocusTimerCircle({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.targetDuration.inSeconds > 0
        ? state.elapsed.inSeconds / state.targetDuration.inSeconds
        : 0.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Glow Layer
          if (state.isRunning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.2 + (0.1 * value)),
                        blurRadius: 30 + (10 * value),
                        spreadRadius: 2 + (4 * value),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Background Ring
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Animated Progress Ring
          SizedBox(
            width: 240,
            height: 240,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, val, child) {
                return CircularProgressIndicator(
                  value: val,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary,
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatRemaining(state.targetDuration - state.elapsed),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 58,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.remainingTime,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final HeroIcons icon;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AppIcon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class _CompletionStatChip extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final double? maxWidth;

  const _CompletionStatChip({
    required this.icon,
    required this.label,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: maxWidth,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
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

class _ProgressRow extends StatelessWidget {
  final String leftLabel;
  final String? rightLabel;
  final double progress;
  final Color color;
  final bool showTrack;

  const _ProgressRow({
    required this.leftLabel,
    required this.progress,
    required this.color,
    this.rightLabel,
    this.showTrack = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (rightLabel != null)
              Text(
                rightLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        if (showTrack) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveStatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final HeroIcons icon;
  final Color color;

  const _ActiveStatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 14, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
