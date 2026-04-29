import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_icons.dart';
import '../../../components/app_glass_card.dart';
import '../../../providers/study_sessions_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'study_session_dialogs.dart';

class LiveStudySessionCard extends ConsumerWidget {
  const LiveStudySessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // We only watch structural changes here, not the elapsed time which updates every second
    final isActive = ref.watch(studyTimerProvider.select((s) => s.isRunning || s.isPaused));
    if (!isActive) return const SizedBox.shrink();

    final courseId = ref.watch(studyTimerProvider.select((s) => s.courseId));
    final courses = ref.watch(courseProvider).valueOrNull ?? [];
    final selectedCourse = courses.where((c) => c.id == courseId).firstOrNull;
    final sortedCourses = List.from(courses)..sort((a, b) => a.courseCode.compareTo(b.courseCode));

    return AppGlassCard(
      borderOnly: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Course Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 4, right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1200.ms)
                   .boxShadow(
                      begin: const BoxShadow(color: Color(0x224ADE80), blurRadius: 2, spreadRadius: 0),
                      end: const BoxShadow(color: Color(0x554ADE80), blurRadius: 6, spreadRadius: 1),
                      duration: 1200.ms,
                   ),
                  Text(
                    l10n.liveStudySessions,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (!isActive)
                _CoursePicker(
                  selectedCourse: selectedCourse,
                  courses: sortedCourses,
                  onSelected: (id) => ref.read(studyTimerProvider.notifier).setCourseId(id),
                )
              else if (selectedCourse != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (selectedCourse.courseCode ?? '').toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Timer Display
          const _TimerDisplaySection(),
          const SizedBox(height: AppSpacing.xl),

          // Controls
          const _TimerControlsSection(),
        ],
      ),
    ).animate().fade().slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _TimerDisplaySection extends ConsumerWidget {
  const _TimerDisplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(studyTimerProvider.select((s) => s.elapsed));
    final target = ref.watch(studyTimerProvider.select((s) => s.targetDuration));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      return "$twoDigitMinutes:$twoDigitSeconds";
    }

    Color getTypeColor(StudyType type, bool isBreak) {
      if (isBreak) return const Color(0xFF4ADE80);
      switch (type) {
        case StudyType.pomodoro: return const Color(0xFFFACC15);
        case StudyType.deepWork: return const Color(0xFF3B82F6);
        case StudyType.review: return const Color(0xFFA855F7);
      }
    }

    final sessionType = ref.watch(studyTimerProvider.select((s) => s.sessionType));
    final isBreak = ref.watch(studyTimerProvider.select((s) => s.isBreak));
    final accentColor = getTypeColor(sessionType, isBreak);

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: target.inSeconds > 0
                      ? (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0)
                      : 0.0,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDuration(elapsed),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    l10n.targetPrefix("${target.inMinutes}m"),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerControlsSection extends ConsumerWidget {
  const _TimerControlsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(studyTimerProvider.select((s) => s.isRunning));
    final isPaused = ref.watch(studyTimerProvider.select((s) => s.isPaused));
    final courseId = ref.watch(studyTimerProvider.select((s) => s.courseId));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isActive = isRunning || isPaused;

    return Row(
      children: [
        if (isActive) ...[
          if (isPaused) ...[
            Expanded(
              child: _ControlButton(
                icon: HeroIcons.arrowPath,
                label: l10n.reset,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                onPressed: () => ref.read(studyTimerProvider.notifier).reset(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: _ControlButton(
              icon: HeroIcons.stop,
              label: l10n.stop,
              color: theme.colorScheme.error,
              onPressed: () => StudySessionDialogs.showStopConfirm(context, ref),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ControlButton(
              icon: isRunning ? HeroIcons.pause : HeroIcons.play,
              label: isRunning ? l10n.pause : l10n.resume,
              color: theme.colorScheme.primary,
              onPressed: () {
                if (isRunning) {
                  ref.read(studyTimerProvider.notifier).pause();
                } else {
                  ref.read(studyTimerProvider.notifier).resume();
                }
              },
            ),
          ),
        ] else
          Expanded(
            child: _ControlButton(
              icon: HeroIcons.play,
              label: l10n.startSession,
              color: theme.colorScheme.primary,
              onPressed: courseId == null
                  ? null
                  : () => ref.read(studyTimerProvider.notifier).start(),
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDisabled 
                ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDisabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon,
                size: 20,
                color: isDisabled 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                    : color,
                solid: true,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDisabled 
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoursePicker extends StatelessWidget {
  final dynamic selectedCourse;
  final List<dynamic> courses;
  final ValueChanged<String?> onSelected;

  const _CoursePicker({
    required this.selectedCourse,
    required this.courses,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      onSelected: (id) {
        Haptics.vibrate(HapticsType.selection);
        onSelected(id);
      },
      tooltip: l10n.selectCourse,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      itemBuilder: (context) => courses.map((course) {
        final courseColor = course.color != null 
            ? Color(int.parse(course.color!.replaceFirst('#', '0xFF')))
            : theme.colorScheme.primary;
            
        return PopupMenuItem<String>(
          value: course.id,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: courseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: courseColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${course.courseCode} - ${course.courseName}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (selectedCourse?.courseCode?.toString() ?? l10n.selectCourse).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: selectedCourse == null 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
