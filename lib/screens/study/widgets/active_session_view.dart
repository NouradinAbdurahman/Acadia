import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/design/app_spacing.dart';
import '../../../providers/study_sessions_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'study_session_dialogs.dart';

class ActiveSessionView extends ConsumerWidget {
  const ActiveSessionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(studyTimerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final courses = ref.watch(courseProvider).value ?? [];
    final course = courses.where((c) => c.id == timerState.courseId).firstOrNull;

    final typeColor = _getTypeColor(timerState.sessionType, timerState.isBreak);
    final label = _getSessionLabel(context, timerState);
    final progress = timerState.targetDuration.inSeconds > 0
        ? timerState.elapsed.inSeconds / timerState.targetDuration.inSeconds
        : 0.0;
    
    final remaining = timerState.targetDuration - timerState.elapsed;
    final displayTime = _formatDuration(remaining);

    // Dynamic message based on state
    final message = _getMotivationalMessage(context, timerState);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
      child: Column(
        children: [
          const SizedBox(height: 0), // Moved as close to top as possible
          
          // 1. Header Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 18,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                const SizedBox(height: 6),
                if (course != null)
                  Text(
                    '${course.courseCode} • ${course.courseName}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ).animate().fadeIn(delay: 200.ms)
                else
                  Text(
                    l10n.noCourseSelected,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl), // 48px gap

          // 2. Large Glowing Timer
          _TimerDisplay(
            displayTime: displayTime,
            progress: progress,
            color: typeColor,
            isPaused: timerState.isPaused,
            label: timerState.isBreak ? l10n.breakLabel.toUpperCase() : l10n.remainingLabel.toUpperCase(),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(height: AppSpacing.xxl), // 48px gap

          // 3. Status Section (Rounds + Message)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                if (timerState.sessionType == StudyType.pomodoro) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isCurrent = (timerState.currentRound - 1) == index;
                      final isPast = (timerState.currentRound - 1) > index;
                      
                      return Container(
                        width: isCurrent ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isCurrent 
                            ? typeColor 
                            : isPast 
                              ? typeColor.withValues(alpha: 0.3)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: typeColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ] : null,
                        ),
                      ).animate(target: isCurrent ? 1 : 0).scale(duration: 300.ms);
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: typeColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                    fontSize: 14,
                  ),
                ).animate(key: ValueKey(message)).fadeIn().slideY(begin: 0.1),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl), // 48px gap

          // 4. Session Controls
          _SessionControls(
            isRunning: timerState.isRunning,
            isPaused: timerState.isPaused,
            onToggle: () {
              if (timerState.isRunning) {
                ref.read(studyTimerProvider.notifier).pause();
              } else {
                ref.read(studyTimerProvider.notifier).resume();
              }
            },
            onStop: () => StudySessionDialogs.showStopConfirm(context, ref),
            themeColor: typeColor,
          ),
          
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Color _getTypeColor(StudyType type, bool isBreak) {
    if (isBreak) return const Color(0xFF4ADE80);
    switch (type) {
      case StudyType.pomodoro: return const Color(0xFFFACC15);
      case StudyType.deepWork: return const Color(0xFF3B82F6);
      case StudyType.review: return const Color(0xFFA855F7);
    }
  }

  String _getSessionLabel(BuildContext context, StudyTimerState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isBreak) return l10n.breakLabel;
    
    switch (state.sessionType) {
      case StudyType.pomodoro:
        return "${l10n.focusLabel} ${state.currentRound}/${state.totalRounds}";
      case StudyType.deepWork:
        return l10n.focusLabel;
      case StudyType.review:
        return l10n.reviewLabel;
    }
  }

  String _getMotivationalMessage(BuildContext context, StudyTimerState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isPaused) return l10n.sessionPaused;
    if (state.isBreak) return l10n.refreshYourself;
    
    final messages = [
      l10n.stayFocused,
      l10n.deepWorkInProgress,
      l10n.dontStopNow,
      l10n.focusOnProcess,
      l10n.almostThere,
      l10n.futureSelf,
    ];
    
    final index = (state.elapsed.inSeconds ~/ 300) % messages.length;
    return messages[index];
  }
}

class _TimerDisplay extends StatelessWidget {
  final String displayTime;
  final double progress;
  final Color color;
  final bool isPaused;
  final String label;

  const _TimerDisplay({
    required this.displayTime,
    required this.progress,
    required this.color,
    required this.isPaused,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invertedProgress = 1.0 - progress;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(280, 280),
            painter: _TimerPainter(
              progress: 1.0,
              color: color.withValues(alpha: 0.08),
              strokeWidth: 8,
            ),
          ),
          CustomPaint(
            size: const Size(280, 280),
            painter: _TimerPainter(
              progress: invertedProgress,
              color: color,
              strokeWidth: 10,
              showGlow: !isPaused,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayTime,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 54,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(
      begin: const Offset(1, 1),
      end: isPaused ? const Offset(1, 1) : const Offset(1.03, 1.03),
      duration: 3.seconds,
      curve: Curves.easeInOutSine
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showGlow;

  _TimerPainter({
    required this.progress, 
    required this.color, 
    required this.strokeWidth,
    this.showGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - strokeWidth;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SessionControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final Color themeColor;

  const _SessionControls({
    required this.isRunning,
    required this.isPaused,
    required this.onToggle,
    required this.onStop,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: HeroIcons.stop,
          onPressed: onStop,
          color: const Color(0xFFEF4444),
          size: 64,
          iconSize: 28,
        ),
        const SizedBox(width: 48),
        _ControlButton(
          icon: isPaused ? HeroIcons.play : HeroIcons.pause,
          onPressed: onToggle,
          color: themeColor,
          size: 84,
          iconSize: 36,
          isPrimary: true,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final HeroIcons icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double iconSize;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.size,
    required this.iconSize,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? color : color.withValues(alpha: 0.15),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ] : null,
          border: !isPrimary ? Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ) : null,
        ),
        child: Center(
          child: HeroIcon(
            icon,
            style: HeroIconStyle.solid,
            color: isPrimary ? theme.colorScheme.onPrimary : color,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
