import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_session.dart';
import 'app_providers.dart' as app;

class StudyTimerState {
  final Duration elapsed;
  final bool isRunning;
  final bool isPaused;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final Duration pausedDuration;
  final String sessionType;
  final String? courseId;
  final Duration targetDuration;
  final bool hasCompleted;

  const StudyTimerState({
    this.elapsed = Duration.zero,
    this.isRunning = false,
    this.isPaused = false,
    this.startTime,
    this.endTime,
    this.pausedAt,
    this.pausedDuration = Duration.zero,
    this.sessionType = 'deep_work',
    this.courseId,
    this.targetDuration = const Duration(minutes: 25),
    this.hasCompleted = false,
  });

  StudyTimerState copyWith({
    Duration? elapsed,
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pausedAt,
    Duration? pausedDuration,
    String? sessionType,
    String? courseId,
    Duration? targetDuration,
    bool? hasCompleted,
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
      targetDuration: targetDuration ?? this.targetDuration,
      hasCompleted: hasCompleted ?? this.hasCompleted,
    );
  }
}

class StudyTimerNotifier extends StateNotifier<StudyTimerState> {
  StudyTimerNotifier() : super(const StudyTimerState());

  Timer? _timer;

  Duration _elapsedAt(DateTime now) {
    if (state.startTime == null) return Duration.zero;
    final pausedOffset = state.isPaused && state.pausedAt != null
        ? now.difference(state.pausedAt!)
        : Duration.zero;
    final raw = now.difference(state.startTime!);
    final computed = raw - state.pausedDuration - pausedOffset;
    return computed.isNegative ? Duration.zero : computed;
  }

  void setSessionType(String type) {
    state = state.copyWith(sessionType: type);
  }

  void setCourseId(String? courseId) {
    state = state.copyWith(courseId: courseId);
  }

  void setDuration(Duration duration) {
    state = state.copyWith(targetDuration: duration);
  }

  void start() {
    if (state.isRunning) return;
    final now = DateTime.now();
    state = state.copyWith(
      elapsed: Duration.zero,
      isRunning: true,
      isPaused: false,
      startTime: now,
      endTime: null,
      pausedAt: null,
      pausedDuration: Duration.zero,
      hasCompleted: false,
    );
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _elapsedAt(DateTime.now());
      if (elapsed >= state.targetDuration) {
        stop();
      } else {
        state = state.copyWith(elapsed: elapsed);
      }
    });
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _elapsedAt(DateTime.now());
      if (elapsed >= state.targetDuration) {
        stop();
      } else {
        state = state.copyWith(elapsed: elapsed);
      }
    });
  }

  void stop() {
    if (!state.isRunning && !state.isPaused) return;
    _timer?.cancel();
    final end = DateTime.now();
    final finalElapsed = _elapsedAt(end);
    state = state.copyWith(
      elapsed: finalElapsed,
      isRunning: false,
      isPaused: false,
      endTime: end,
      pausedAt: null,
      hasCompleted: true,
    );
  }

  void reset() {
    _timer?.cancel();
    state = const StudyTimerState();
  }
}

final studyTimerProvider =
    StateNotifierProvider<StudyTimerNotifier, StudyTimerState>(
  (ref) => StudyTimerNotifier(),
);

class StudySessionsNotifier
    extends StateNotifier<AsyncValue<List<StudySession>>> {
  StudySessionsNotifier({
    required this.studyRepository,
    required this.supabaseClient,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _loadSessions();
  }

  final dynamic studyRepository;
  final SupabaseClient supabaseClient;
  final Ref ref;

  Future<void> _loadSessions() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final sessions = await studyRepository.getSessions(userId)
          as List<StudySession>;
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadSessions();
  }

  Future<void> saveFromTimer(
    StudyTimerState timerState, {
    String? sessionTypeOverride,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;
    final minutes = ((timerState.elapsed.inSeconds) / 60).ceil().clamp(1, 24 * 60);
    final newSession = StudySession(
      id: '',
      userId: userId,
      courseId: timerState.courseId!,
      sessionType: sessionTypeOverride ?? timerState.sessionType,
      durationMinutes: minutes,
      createdAt: DateTime.now(),
    );

    try {
      final created = await studyRepository.createSession(newSession)
          as StudySession;
      
      // Update local state for immediate feedback
      state = state.whenData(
        (sessions) => [created, ...sessions],
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSessionAndPersist(
    StudyTimerState timerState,
  ) async {
    await saveFromTimer(
      timerState,
    );
  }
}

final studySessionsProvider = StateNotifierProvider<StudySessionsNotifier,
    AsyncValue<List<StudySession>>>(
  (ref) {
    final repo = ref.watch(app.studyRepositoryProvider);
    final supabase = Supabase.instance.client;
    return StudySessionsNotifier(
      studyRepository: repo,
      supabaseClient: supabase,
      ref: ref,
    );
  },
);
