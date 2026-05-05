import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter/widgets.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import '../models/study_session.dart';
import 'app_providers.dart' as app;
import 'semester_provider.dart';
import 'analytics_provider.dart';
import 'mood_provider.dart';

enum StudyType {
  pomodoro,
  deepWork,
  review,
}

int getDefaultDuration(StudyType type) {
  switch (type) {
    case StudyType.pomodoro:
      return 25;
    case StudyType.deepWork:
      return 45;
    case StudyType.review:
      return 20;
  }
}

class StudyTimerState {
  final Duration elapsed;
  final bool isRunning;
  final bool isPaused;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final Duration pausedDuration;
  final StudyType sessionType;
  final String? courseId;
  final String? intent;
  final int currentRound;
  final int totalRounds;
  final bool isBreak;
  final Duration targetDuration;
  final bool isCompleted;
  final int completedCycles;
  final bool skippedBreak;

  // ── Pomodoro accumulation tracking ──
  final int totalFocusAccumulated; // minutes
  final int totalBreakAccumulated; // minutes

  const StudyTimerState({
    this.elapsed = Duration.zero,
    this.isRunning = false,
    this.isPaused = false,
    this.startTime,
    this.endTime,
    this.pausedAt,
    this.pausedDuration = Duration.zero,
    this.sessionType = StudyType.deepWork,
    this.courseId,
    this.intent,
    this.currentRound = 1,
    this.totalRounds = 4,
    this.isBreak = false,
    this.targetDuration = const Duration(minutes: 45),
    this.isCompleted = false,
    this.completedCycles = 0,
    this.skippedBreak = false,
    this.totalFocusAccumulated = 0,
    this.totalBreakAccumulated = 0,
  });

  StudyTimerState copyWith({
    Duration? elapsed,
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pausedAt,
    Duration? pausedDuration,
    StudyType? sessionType,
    String? courseId,
    String? intent,
    int? currentRound,
    int? totalRounds,
    bool? isBreak,
    Duration? targetDuration,
    bool? isCompleted,
    int? completedCycles,
    bool? skippedBreak,
    int? totalFocusAccumulated,
    int? totalBreakAccumulated,
  }) {
    return StudyTimerState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      sessionType: sessionType ?? this.sessionType,
      courseId: courseId ?? this.courseId,
      intent: intent ?? this.intent,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isBreak: isBreak ?? this.isBreak,
      targetDuration: targetDuration ?? this.targetDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      completedCycles: completedCycles ?? this.completedCycles,
      skippedBreak: skippedBreak ?? this.skippedBreak,
      totalFocusAccumulated: totalFocusAccumulated ?? this.totalFocusAccumulated,
      totalBreakAccumulated: totalBreakAccumulated ?? this.totalBreakAccumulated,
    );
  }
}

class StudyTimerNotifier extends StateNotifier<StudyTimerState> with WidgetsBindingObserver {
  StudyTimerNotifier(this.ref) : super(const StudyTimerState()) {
    WidgetsBinding.instance.addObserver(this);
    _initPersistence();
  }

  Future<void> _initPersistence() async {
    final box = await Hive.openBox('timer_state');
    
    final startTimeStr = box.get('startTime') as String?;
    final lastUpdateStr = box.get('lastUpdate') as String?;
    final isRunning = box.get('isRunning', defaultValue: false) as bool;
    final isPaused = box.get('isPaused', defaultValue: false) as bool;
    final pausedAtStr = box.get('pausedAt') as String?;
    final pausedDurationMs = box.get('pausedDurationMs', defaultValue: 0) as int;
    final sessionTypeIndex = box.get('sessionTypeIndex', defaultValue: 0) as int;
    final courseId = box.get('courseId') as String?;
    final intent = box.get('intent') as String?;
    final currentRound = box.get('currentRound', defaultValue: 1) as int;
    final totalFocusAccumulated = box.get('totalFocusAccumulated', defaultValue: 0) as int;
    final totalBreakAccumulated = box.get('totalBreakAccumulated', defaultValue: 0) as int;
    final targetDurationSeconds = box.get('targetDurationSeconds') as int?;

    if (startTimeStr != null) {
      final startTime = DateTime.parse(startTimeStr);
      final sessionType = StudyType.values[sessionTypeIndex];
      final targetDuration = targetDurationSeconds != null 
          ? Duration(seconds: targetDurationSeconds) 
          : (sessionType == StudyType.pomodoro ? const Duration(minutes: 25) : const Duration(minutes: 45));

      state = state.copyWith(
        startTime: startTime,
        isRunning: isRunning,
        isPaused: isPaused,
        pausedDuration: Duration(milliseconds: pausedDurationMs),
        pausedAt: pausedAtStr != null ? DateTime.parse(pausedAtStr) : null,
        sessionType: sessionType,
        courseId: courseId,
        intent: intent,
        currentRound: currentRound,
        totalFocusAccumulated: totalFocusAccumulated,
        totalBreakAccumulated: totalBreakAccumulated,
        targetDuration: targetDuration,
      );

      final now = DateTime.now();
      if (isRunning && lastUpdateStr != null) {
        
        // Time-jump: Add the time passed while app was closed to elapsed
        final elapsed = _elapsedAt(now);
        
        if (elapsed >= targetDuration) {
          state = state.copyWith(elapsed: targetDuration);
          _onPhaseComplete();
        } else {
          state = state.copyWith(elapsed: elapsed);
          NotificationService.scheduleCompletion(targetDuration - elapsed);
          _startTimerTargetCheck();
        }
      } else {
        state = state.copyWith(elapsed: _elapsedAt(now));
      }
    }
  }

  Future<void> _persist() async {
    final box = await Hive.openBox('timer_state');
    if (state.startTime == null && !state.isRunning && !state.isPaused) {
      await box.clear();
      return;
    }
    
    await box.put('startTime', state.startTime?.toIso8601String());
    await box.put('lastUpdate', DateTime.now().toIso8601String());
    await box.put('isRunning', state.isRunning);
    await box.put('isPaused', state.isPaused);
    await box.put('pausedAt', state.pausedAt?.toIso8601String());
    await box.put('pausedDurationMs', state.pausedDuration.inMilliseconds);
    await box.put('sessionTypeIndex', state.sessionType.index);
    await box.put('courseId', state.courseId);
    await box.put('intent', state.intent);
    await box.put('currentRound', state.currentRound);
    await box.put('totalFocusAccumulated', state.totalFocusAccumulated);
    await box.put('totalBreakAccumulated', state.totalBreakAccumulated);
    await box.put('targetDurationSeconds', state.targetDuration.inSeconds);
  }


  final Ref ref;
  Timer? _timer;
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.isRunning) {
      final now = DateTime.now();
      final elapsed = _elapsedAt(now);
      if (elapsed >= this.state.targetDuration) {
        this.state = this.state.copyWith(elapsed: this.state.targetDuration);
        _onPhaseComplete();
      } else {
        this.state = this.state.copyWith(elapsed: elapsed);
      }
      _persist();
    }
  }

  Duration _elapsedAt(DateTime now) {
    if (state.startTime == null) return Duration.zero;
    
    // Total time since start
    final totalSinceStart = now.difference(state.startTime!);
    
    // Subtract total paused duration
    var activeElapsed = totalSinceStart - state.pausedDuration;
    
    // If currently paused, also subtract time since pause started
    if (state.isPaused && state.pausedAt != null) {
      activeElapsed -= now.difference(state.pausedAt!);
    }
    
    return activeElapsed.isNegative ? Duration.zero : activeElapsed;
  }

  void setStudyType(StudyType type) {
    state = state.copyWith(sessionType: type);
    _persist();
  }

  void setIntent(String? intent) {
    state = state.copyWith(intent: intent);
    _persist();
  }

  void setCourseId(String? courseId) {
    state = state.copyWith(courseId: courseId);
    _persist();
  }

  void setDuration(Duration duration) {
    state = state.copyWith(targetDuration: duration);
    _persist();
  }

  void start() {
    if (state.isRunning) return;
    _timer?.cancel(); 

    if (state.isCompleted || state.startTime == null) {
      state = state.copyWith(
        currentRound: 1,
        isBreak: false,
        totalFocusAccumulated: 0,
        totalBreakAccumulated: 0,
      );
      ref.read(studySessionsProvider.notifier).resetPomodoroSaveFlag();
    }

    _handleStart();
  }

  void _handleStart() {
    final now = DateTime.now();
    final isPomodoro = state.sessionType == StudyType.pomodoro;
    final rounds = isPomodoro ? 4 : 1;
    final duration = isPomodoro ? const Duration(minutes: 25) : state.targetDuration;

    state = state.copyWith(
      elapsed: Duration.zero,
      isRunning: true,
      isPaused: false,
      startTime: now,
      endTime: null,
      pausedAt: null,
      pausedDuration: Duration.zero,
      isCompleted: false,
      totalRounds: rounds,
      targetDuration: state.isBreak ? state.targetDuration : duration,
    );

    _timer?.cancel();
    NotificationService.scheduleCompletion(state.targetDuration);
    _startTimerTargetCheck();
    _persist();
  }

  void _startTimerTargetCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _elapsedAt(DateTime.now());
      if (elapsed >= state.targetDuration) {
        _timer?.cancel();
        state = state.copyWith(elapsed: state.targetDuration);
        _onPhaseComplete();
      } else {
        state = state.copyWith(elapsed: elapsed);
      }
      _persist();
    });
  }

  Future<void> _onPhaseComplete() async {
    _timer?.cancel();
    NotificationService.showCompletionNotification();

    await _player.stop(); 
    await _player.play(AssetSource('sounds/finish.mp3'));
    Haptics.vibrate(HapticsType.success);

    final isPomodoro = state.sessionType == StudyType.pomodoro;

    if (!state.isBreak) {
      final actualFocusMinutes = state.elapsed.inSeconds ~/ 60;
      state = state.copyWith(
        totalFocusAccumulated: state.totalFocusAccumulated + actualFocusMinutes,
      );
    } else {
      final actualBreakMinutes = state.elapsed.inSeconds ~/ 60;
      state = state.copyWith(
        totalBreakAccumulated: state.totalBreakAccumulated + actualBreakMinutes,
      );
    }

    if (!isPomodoro) {
      state = state.copyWith(isCompleted: true, isRunning: false);
      if (state.courseId != null) {
        ref.read(studySessionsProvider.notifier).saveFromTimer(state);
      }
      _persist(); // This will clear the box if startTime is reset
      return;
    }

    if (!state.isBreak) {
      final isLastRound = state.currentRound == state.totalRounds;

      if (isLastRound) {
        final isFullyCompleted = state.currentRound == state.totalRounds && !state.isBreak;
        final finalState = state.copyWith(
          isCompleted: true,
          isRunning: false,
          completedCycles: state.completedCycles + 1,
        );
        state = finalState;
        if (finalState.courseId != null) {
          ref.read(studySessionsProvider.notifier).savePomodoroSession(finalState, isFullyCompleted: isFullyCompleted);
        }
      } else {
        final breakMinutes = 5;
        state = state.copyWith(
          isBreak: true,
          isCompleted: false,
          targetDuration: Duration(minutes: breakMinutes),
          elapsed: Duration.zero,
          completedCycles: state.completedCycles + 1,
        );
        Future.delayed(const Duration(milliseconds: 50), _handleStart);
      }
      _persist();
    } else {
      if (state.currentRound < state.totalRounds) {
        state = state.copyWith(
          isBreak: false,
          isCompleted: false,
          currentRound: state.currentRound + 1,
          targetDuration: const Duration(minutes: 25),
          elapsed: Duration.zero,
        );
        Future.delayed(const Duration(milliseconds: 50), _handleStart);
      }
      _persist();
    }
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    final now = DateTime.now();
    state = state.copyWith(
      elapsed: _elapsedAt(now),
      isRunning: false,
      isPaused: true,
      pausedAt: now,
    );
    NotificationService.cancelAll();
    _persist();
  }

  void resume() {
    if (!state.isPaused || state.startTime == null) return;
    final now = DateTime.now();
    final extraPause =
        state.pausedAt == null ? Duration.zero : now.difference(state.pausedAt!);
    state = state.copyWith(
      elapsed: _elapsedAt(now),
      isRunning: true,
      isPaused: false,
      pausedAt: null,
      pausedDuration: state.pausedDuration + extraPause,
    );
    _timer?.cancel();
    NotificationService.scheduleCompletion(state.targetDuration - state.elapsed);
    _startTimerTargetCheck();
    _persist();
  }

  void stop() {
    if (!state.isRunning && !state.isPaused) return;
    _timer?.cancel();
    NotificationService.cancelAll();
    final end = DateTime.now();
    final finalElapsed = _elapsedAt(end);
    final safeElapsed = finalElapsed > state.targetDuration ? state.targetDuration : finalElapsed;

    final extraFocus = !state.isBreak ? (safeElapsed.inSeconds ~/ 60) : 0;
    final extraBreak = state.isBreak ? (safeElapsed.inSeconds ~/ 60) : 0;

    final stoppedState = state.copyWith(
      elapsed: safeElapsed,
      isRunning: false,
      isPaused: false,
      endTime: end,
      isCompleted: false, 
      totalFocusAccumulated: state.totalFocusAccumulated + extraFocus,
      totalBreakAccumulated: state.totalBreakAccumulated + extraBreak,
    );
    state = stoppedState;

    if (state.sessionType == StudyType.pomodoro &&
        state.courseId != null &&
        stoppedState.totalFocusAccumulated > 0) {
      ref.read(studySessionsProvider.notifier).savePomodoroSession(stoppedState);
    } 
    else if (state.sessionType != StudyType.pomodoro &&
             state.courseId != null &&
             stoppedState.totalFocusAccumulated >= 10) {
      ref.read(studySessionsProvider.notifier).saveFromTimer(stoppedState.copyWith(isCompleted: true));
    }
    
    // Clear the active session metadata so it doesn't recover ghost sessions
    state = const StudyTimerState();
    _persist();
  }

  void reset() {
    _timer?.cancel();
    NotificationService.cancelAll();
    state = const StudyTimerState();
    _persist();
  }
}

final studyTimerProvider =
    StateNotifierProvider<StudyTimerNotifier, StudyTimerState>(
  (ref) => StudyTimerNotifier(ref),
);

class StudySessionsNotifier
    extends StateNotifier<AsyncValue<List<StudySession>>> {
  StudySessionsNotifier({
    required this.studyRepository,
    required this.supabaseClient,
    required this.ref,
  }) : super(const AsyncValue.loading());

  final dynamic studyRepository;
  final SupabaseClient supabaseClient;
  final Ref ref;
  String? _lastLoadedSemesterId;

  void setEmptyState() {
    _lastLoadedSemesterId = null;
    state = const AsyncValue.data(<StudySession>[]);
  }

  Future<void> loadSessions({required String userId, String? semesterId}) async {
    if (semesterId != null &&
        _lastLoadedSemesterId == semesterId &&
        state.hasValue) {
      return;
    }
    try {
      state = const AsyncValue.loading();
      final list = await studyRepository.getSessions(userId: userId, semesterId: semesterId) as List<StudySession>;
      
      debugPrint('[StudySessionsProvider] Loading for Semester: $semesterId | Data Count: ${list.length}');
      if (!mounted) return;
      _lastLoadedSemesterId = semesterId;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = ref.read(activeSemesterProvider).value;
    if (userId != null) {
      await loadSessions(userId: userId, semesterId: semesterId);
    }
  }

  bool _isSaving = false;
  bool _pomodoroSaved = false; // Prevents duplicate saves from _onPhaseComplete + stop()

  void resetPomodoroSaveFlag() {
    _pomodoroSaved = false;
  }

  // ── Standard session save (non-Pomodoro) ──
  Future<void> saveFromTimer(
    StudyTimerState timerState, {
    String? sessionTypeOverride,
  }) async {
    final minutes = timerState.elapsed.inMinutes;
    if (minutes > 240) {
      return;
    }

    debugPrint("📥 saveFromTimer CALLED");
    debugPrint("minutes = $minutes | isBreak = ${timerState.isBreak} | courseId = ${timerState.courseId}");

    // Business rule: completion = technical event, valid session = business rule
    final isValidSession = timerState.isCompleted && minutes >= 10;
    if (!isValidSession) {
      debugPrint("❌ Not saved: completed=${timerState.isCompleted}, minutes=$minutes");
      return;
    }

    if (_isSaving) return;

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    if (timerState.courseId == null) {
      debugPrint("❌ No course selected");
      return;
    }

    final semesterId = ref.read(activeSemesterProvider).value;
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot save session.');
    }

    // Never save break phases
    if (timerState.isBreak) return;

    _isSaving = true;
    debugPrint("[StudySession] Attempting to save: $minutes min");

    try {
      String mapSessionType(StudyType type) {
        switch (type) {
          case StudyType.pomodoro:
            return 'pomodoro';
          case StudyType.deepWork:
            return 'deep_work';
          case StudyType.review:
            return 'review';
        }
      }

      final newSession = StudySession(
        id: '',
        userId: userId,
        courseId: timerState.courseId!,
        semesterId: semesterId,
        sessionType: sessionTypeOverride ?? mapSessionType(timerState.sessionType),
        durationMinutes: minutes,
        createdAt: DateTime.now(),
        plannedMinutes: timerState.targetDuration.inMinutes,
        actualMinutes: minutes,
        startedAt: timerState.startTime,
        endedAt: DateTime.now(),
        intent: timerState.intent,
        completed: timerState.isCompleted,
        completedCycles: timerState.completedCycles,
        skippedBreaks: timerState.skippedBreak ? 1 : 0,
      );


      final previous = state;
      try {
        final created = await studyRepository.createSession(newSession)
            as StudySession;

        if (!mounted) return;

        state = state.whenData((sessions) => [created, ...sessions]);
        debugPrint("✅ Saved: $minutes min");
        ref.read(analyticsProvider.notifier).refresh();
        if (ref.read(moodSettingsProvider.notifier).shouldShowAfterStudy) {
          ref.read(moodActionsProvider).queueSessionMoodPrompt();
        }
      } catch (e, st) {
        if (!mounted) return;
        state = previous;
        Error.throwWithStackTrace(e, st);
      }
    } finally {
      _isSaving = false;
    }
  }

  // ── Pomodoro structured session save ──
  Future<void> savePomodoroSession(
    StudyTimerState timerState, {
    bool isFullyCompleted = false,
  }) async {
    final totalFocus = timerState.totalFocusAccumulated;
    if (totalFocus > 240) {
      return;
    }

    debugPrint("🍅 savePomodoroSession CALLED");
    debugPrint("totalFocus = $totalFocus | cycles = ${timerState.completedCycles}/${timerState.totalRounds} | full=$isFullyCompleted");

    // ── Validity gate ──
    final isValidPomodoro = totalFocus >= 10;
    if (!isValidPomodoro) {
      debugPrint("❌ Pomodoro not saved: only ${totalFocus}m total focus");
      return;
    }

    // ── Duplicate save guard ──
    if (_pomodoroSaved) {
      debugPrint("⚠️ Pomodoro already saved this session — skipping duplicate");
      return;
    }
    _pomodoroSaved = true;

    if (_isSaving) return;

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    if (timerState.courseId == null) {
      debugPrint("❌ No course selected");
      return;
    }

    final semesterId = ref.read(activeSemesterProvider).value;
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot save session.');
    }

    _isSaving = true;

    try {
      final session = StudySession(
        id: '',
        userId: userId,
        courseId: timerState.courseId!,
        semesterId: semesterId,
        sessionType: 'pomodoro',
        durationMinutes: totalFocus, // mirrors totalFocusMinutes for analytics
        createdAt: DateTime.now(),
        plannedMinutes: timerState.targetDuration.inMinutes,
        actualMinutes: totalFocus,
        startedAt: timerState.startTime,
        endedAt: DateTime.now(),
        intent: timerState.intent,
        completed: isFullyCompleted,
        isPomodoro: true,
        totalFocusMinutes: totalFocus,
        totalBreakMinutes: timerState.totalBreakAccumulated,
        cyclesCompleted: timerState.completedCycles,
        totalCycles: timerState.totalRounds,
        skippedBreaks: timerState.skippedBreak ? 1 : 0,
      );


      final previous = state;
      try {
        final created = await studyRepository.createSession(session)
            as StudySession;

        if (!mounted) return;

        state = state.whenData((sessions) => [created, ...sessions]);
        debugPrint("✅ Pomodoro saved: ${totalFocus}m focus, ${timerState.completedCycles} cycles");
        ref.read(analyticsProvider.notifier).refresh();
        if (ref.read(moodSettingsProvider.notifier).shouldShowAfterStudy) {
          ref.read(moodActionsProvider).queueSessionMoodPrompt();
        }
      } catch (e, st) {
        if (!mounted) return;
        state = previous;
        Error.throwWithStackTrace(e, st);
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<void> endSessionAndPersist(StudyTimerState timerState) async {
    if (timerState.sessionType == StudyType.pomodoro) {
      await savePomodoroSession(timerState);
    } else {
      await saveFromTimer(timerState);
    }
  }

  Future<void> attachMoodToLastSession(double mood, double stress) async {
    final currentList = state.value ?? [];
    if (currentList.isEmpty) return;

    // We attach to the most recent session (first in the list after sort)
    final lastSession = currentList.first;
    
    // Safety: Don't override if already has mood (Requirement 6)
    if (lastSession.mood != null) return;

    final updated = lastSession.copyWith(mood: mood, stress: stress);
    
    // Update local state first
    state = AsyncValue.data([
      updated,
      ...currentList.sublist(1),
    ]);

    try {
      await studyRepository.updateSession(updated);
    } catch (e) {
      // Revert if DB update fails
      state = AsyncValue.data(currentList);
    }
  }
}

final studySessionsProvider = StateNotifierProvider<StudySessionsNotifier, AsyncValue<List<StudySession>>>((ref) {
  final repo = ref.watch(app.studyRepositoryProvider);
  final userId = ref.watch(app.currentUserProvider)?.id;
  final semesterIdAsync = ref.watch(activeSemesterProvider);
  final supabase = Supabase.instance.client;
  
  final notifier = StudySessionsNotifier(
    studyRepository: repo,
    supabaseClient: supabase,
    ref: ref,
  );
  
  semesterIdAsync.when(
    data: (id) {
      if (userId != null && id != null) {
        notifier.loadSessions(userId: userId, semesterId: id);
        return;
      }
      notifier.setEmptyState();
    },
    loading: () => notifier.setEmptyState(),
    error: (_, __) => notifier.setEmptyState(),
  );
  
  return notifier;
});
