import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../providers/study_sessions_provider.dart';
import '../../providers/course_provider.dart';
import '../../l10n/app_localizations.dart';
import 'study_history_screen.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<StudyTimerState>(studyTimerProvider, (previous, next) {
      final transitionedToCompleted =
          !(previous?.hasCompleted ?? false) && next.hasCompleted;
      if (transitionedToCompleted && next.courseId != null) {
        ref.read(studySessionsProvider.notifier).saveFromTimer(next);
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timerState = ref.watch(studyTimerProvider);
    
    // States
    final bool isIdle = !timerState.isRunning && !timerState.isPaused && !timerState.hasCompleted;
    final bool isActive = timerState.isRunning || timerState.isPaused;
    final bool isCompleted = timerState.hasCompleted;

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              if (isActive) _buildActiveHeader(context, ref, theme, timerState),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      if (isIdle) _buildIdleState(context, ref, theme, l10n, timerState),
                      if (isActive) _buildActiveState(context, ref, theme, l10n, timerState),
                      if (isCompleted) _buildCompleteState(context, ref, theme, l10n, timerState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER (Active State Only) ---
  Widget _buildActiveHeader(BuildContext context, WidgetRef ref, ThemeData theme, StudyTimerState state) {
    final l10n = AppLocalizations.of(context)!;
    final courses = ref.watch(courseProvider).value ?? [];
    final course = courses.where((c) => c.id == state.courseId).firstOrNull;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(HeroIcons.sparkles, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${_formatSessionType(context, state.sessionType)} • ${course?.courseName ?? l10n.noCourseSelected}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2);
  }

  // --- 1. IDLE STATE ---
  Widget _buildIdleState(BuildContext context, WidgetRef ref, ThemeData theme, AppLocalizations l10n, StudyTimerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.study,
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
            ).animate().fade().slideX(begin: -0.1),
            IconButton(
              icon: AppIcon(
                HeroIcons.clock,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: l10n.recentStudySessions,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudyHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        
        // 1.1 Session Type Selector
        Text(l10n.sessionType, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildSessionTypeSelector(ref, state, context),
        const SizedBox(height: AppSpacing.xl),

        // 1.2 Course Selector
        Text(l10n.selectCourse, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildCourseDropdown(context, ref, state),
        const SizedBox(height: AppSpacing.xl),

        // 1.3 Duration Selector
        Text(l10n.duration, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildDurationSelector(context, ref, state),
        const SizedBox(height: AppSpacing.xxl * 2),

        // 1.4 Start Button
        AppButton(
          text: l10n.start,
          onPressed: state.courseId == null 
            ? null 
            : () => ref.read(studyTimerProvider.notifier).start(),
          isFullWidth: true,
          icon: const AppIcon(HeroIcons.play, size: 20, color: Colors.white),
        ),
      ],
    );
  }

  // --- 2. ACTIVE STATE ---
  Widget _buildActiveState(BuildContext context, WidgetRef ref, ThemeData theme, AppLocalizations l10n, StudyTimerState state) {
    return Column(
      children: [
        const SizedBox(height: 40),
        _FocusTimerCircle(state: state),
        const SizedBox(height: 60),
        
        // Stats
        AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: l10n.focusLevel, 
                value: _calculateFocusLevel(l10n, state.elapsed), 
                icon: HeroIcons.fire
              ),
              _StatItem(
                label: l10n.remaining.substring(0, 1).toUpperCase() + l10n.remaining.substring(1), 
                value: _formatDuration(state.targetDuration - state.elapsed), 
                icon: HeroIcons.clock
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: () => ref.read(studyTimerProvider.notifier).stop(),
              icon: const AppIcon(HeroIcons.stop, size: 28),
              style: IconButton.styleFrom(
                minimumSize: const Size(64, 64),
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                foregroundColor: AppColors.error,
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

  // --- 3. COMPLETE STATE ---
  Widget _buildCompleteState(BuildContext context, WidgetRef ref, ThemeData theme, AppLocalizations l10n, StudyTimerState state) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const AppIcon(
          HeroIcons.checkCircle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: AppSpacing.xl),
        
        Text(
          l10n.greatFocusSession,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        
        Text(
          l10n.youStudiedFor(_formatDurationShort(state.elapsed)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),

        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.studyLogged,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        
        AppButton(
          onPressed: () => ref.read(studyTimerProvider.notifier).reset(),
          variant: AppButtonVariant.text,
          text: l10n.backToHome,
        ),
      ],
    );
  }

  // --- HELPERS ---

  String _calculateFocusLevel(AppLocalizations l10n, Duration elapsed) {
    if (elapsed.inMinutes >= 45) return l10n.deepFlow;
    if (elapsed.inMinutes >= 20) return l10n.high;
    if (elapsed.inMinutes >= 10) return l10n.medium;
    return l10n.building;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDurationShort(Duration d) {
    if (d.inSeconds > 0 && d.inMinutes == 0) {
      return '1 minute';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes} minutes';
  }

  String _formatSessionType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'pomodoro':
        return l10n.pomodoro;
      case 'deep_work':
        return l10n.deepWork;
      case 'review':
        return l10n.review;
      default:
        return l10n.study;
    }
  }

  Widget _buildSessionTypeSelector(WidgetRef ref, StudyTimerState state, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final types = ['pomodoro', 'deep_work', 'review'];
    return Row(
      children: types.map((type) {
        final isSelected = state.sessionType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => ref.read(studyTimerProvider.notifier).setSessionType(type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(
                  _sessionTypeLabel(l10n, type),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _sessionTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'pomodoro':
        return l10n.pomodoro;
      case 'deep_work':
        return l10n.deepWork;
      case 'review':
        return l10n.review;
      case 'practice':
        return l10n.practice;
      default:
        return l10n.study;
    }
  }

  Widget _buildCourseDropdown(BuildContext context, WidgetRef ref, StudyTimerState state) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final courses = ref.watch(activeCoursesProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.14),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: state.courseId,
        isExpanded: true,
        menuMaxHeight: 360,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        icon: AppIcon(
          HeroIcons.chevronDown,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        decoration: InputDecoration(
          hintText: l10n.chooseACourse,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6, right: 4),
            child: AppIcon(
              HeroIcons.bookOpen,
              color: theme.colorScheme.primary.withValues(alpha: 0.92),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
        items: courses
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.uiColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.uiColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.courseName,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (val) => ref.read(studyTimerProvider.notifier).setCourseId(val),
      ),
    );
  }

  Widget _buildDurationSelector(BuildContext context, WidgetRef ref, StudyTimerState state) {
    final theme = Theme.of(context);
    final durations = [25, 45, 60, 90];
    return Row(
      children: durations.map((d) {
        final isSelected = state.targetDuration.inMinutes == d;
        return Expanded(
          child: GestureDetector(
            onTap: () => ref.read(studyTimerProvider.notifier).setDuration(Duration(minutes: d)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: isSelected ? 0.3 : 0.1)),
              ),
              child: Center(
                child: Text('$d${AppLocalizations.of(context)!.minutesAbbreviation}', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FocusTimerCircle extends StatelessWidget {
  final StudyTimerState state;
  const _FocusTimerCircle({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = (state.elapsed.inSeconds / state.targetDuration.inSeconds).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isStressed = progress > 0.7;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Glow
          if (isStressed)
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
          
          // Progress Ring
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              color: theme.colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          
          // Timer Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatRemaining(state.targetDuration - state.elapsed),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              Text(
                'remaining',
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
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AppIcon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
