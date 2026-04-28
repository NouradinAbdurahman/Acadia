import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood_log.dart';
import '../models/mood_settings.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'semester_provider.dart';
import 'analytics_provider.dart';
import 'risk_provider.dart';
import 'study_sessions_provider.dart';

class MoodPromptRequest {
  final String source;

  const MoodPromptRequest({required this.source});
}

final moodPromptRequestProvider = StateProvider<MoodPromptRequest?>((ref) {
  return null;
});

final moodTrendDaysProvider = StateProvider<int>((ref) => 7);

final moodChartSourceProvider = StateProvider<String>((ref) => 'daily');

final moodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final semesterIdAsync = ref.watch(activeSemesterProvider);
  
  // Use .when or await to handle the async semester
  final semesterId = await ref.watch(activeSemesterProvider.future);
  if (semesterId == null) return <MoodLog>[];

  final logs = await ref.read(moodRepositoryProvider).getMoodLogs(semesterId: semesterId);
  debugPrint('[MoodProvider] Loading for Semester: $semesterId | Data Count: ${logs.length}');
  return logs;
});

bool _isSessionMoodSource(String source) => source.trim().toLowerCase() == 'session';

final dailyMoodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final logs = await ref.watch(moodLogsProvider.future);
  return logs.where((log) => !_isSessionMoodSource(log.source)).toList();
});

final sessionMoodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final logs = await ref.watch(moodLogsProvider.future);
  return logs.where((log) => _isSessionMoodSource(log.source)).toList();
});

final todayMoodProvider = FutureProvider<bool>((ref) async {
  final logs = await ref.watch(dailyMoodLogsProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return logs.any((log) {
    final logDate = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
    return logDate == today;
  });
});

// ─── MOOD SETTINGS NOTIFIER ───

final moodSettingsProvider = StateNotifierProvider<MoodSettingsNotifier, MoodSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  return MoodSettingsNotifier(ref, user?.id);
});

class MoodSettingsNotifier extends StateNotifier<MoodSettings> {
  MoodSettingsNotifier(this.ref, this.userId)
      : super(MoodSettings(userId: userId ?? '')) {
    _loadSettings();
  }

  final Ref ref;
  final String? userId;

  Future<void> _loadSettings() async {
    if (userId == null) return;
    try {
      final settings = await ref.read(moodRepositoryProvider).getMoodSettings(userId: userId!);
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      // Fallback to defaults
    }
  }

  Future<void> toggleTracking(bool enabled) async {
    final next = state.copyWith(trackingEnabled: enabled);
    state = next;
    await _persist(next);
  }

  Future<void> toggleReminders(bool enabled) async {
    final next = state.copyWith(reminderEnabled: enabled);
    state = next;
    await _persist(next);
  }

  Future<void> updateReminderType(String type) async {
    final next = state.copyWith(reminderType: type);
    state = next;
    await _persist(next);
  }

  Future<void> updateReminderTime(String time) async {
    final next = state.copyWith(reminderTime: time);
    state = next;
    await _persist(next);
    
    // Update notification schedule if daily
    if (state.trackingEnabled && state.reminderEnabled && (state.reminderType == 'daily' || state.reminderType == 'both')) {
       // Scheduling is handled via the MoodActions or NotificationService in the UI for now
    }
  }

  Future<void> _persist(MoodSettings settings) async {
    if (userId == null) return;
    await ref.read(moodRepositoryProvider).upsertMoodSettings(settings);
  }

  bool get shouldShowAfterStudy => 
      state.trackingEnabled && (state.reminderType == 'session' || state.reminderType == 'both');

  bool get shouldShowDaily => 
      state.trackingEnabled && (state.reminderType == 'daily' || state.reminderType == 'both');
}

final moodActionsProvider = Provider<MoodActions>((ref) {
  return MoodActions(ref);
});

class MoodActions {
  MoodActions(this.ref);

  final Ref ref;

  Future<void> saveMoodLog({
    required int moodLevel,
    required int stressLevel,
    int? energyLevel,
    String? note,
    List<String>? factors,
    String source = 'manual',
  }) async {
    final user = ref.read(currentUserProvider);
    final semesterId = ref.read(activeSemesterProvider).value;

    if (user == null) {
      throw Exception('No active user. Cannot save mood log.');
    }
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot save mood log.');
    }

    final moodLog = MoodLog(
      id: '',
      userId: user.id,
      semesterId: semesterId,
      moodLevel: moodLevel,
      stressLevel: stressLevel,
      energyLevel: energyLevel,
      note: note,
      factors: factors ?? const <String>[],
      source: source,
      createdAt: DateTime.now(),
    );


    await ref.read(moodRepositoryProvider).insertMood(moodLog);

    // If source is session, link to last study session
    if (source == 'session') {
      await ref.read(studySessionsProvider.notifier).attachMoodToLastSession(
        moodLevel.toDouble(),
        stressLevel.toDouble(),
      );
    }

    // Invalidate providers to trigger UI updates using microtask
    Future.microtask(() {
      ref.invalidate(moodLogsProvider);
      ref.invalidate(dailyMoodLogsProvider);
      ref.invalidate(sessionMoodLogsProvider);
      ref.invalidate(todayMoodProvider);
      ref.invalidate(analyticsProvider);
      ref.invalidate(riskProvider);
    });
  }

  Future<void> saveMoodSettings(MoodSettings settings) async {
    await ref.read(moodRepositoryProvider).upsertMoodSettings(settings);
  }

  Future<void> scheduleDailyMoodReminder({
    required String time,
    required String title,
    required String body,
  }) async {
    final parsed = _parseHourMinute(time);
    if (parsed == null) return;

    await NotificationService.scheduleDailyMoodReminder(
      hour: parsed.$1,
      minute: parsed.$2,
      title: title,
      body: body,
    );
  }

  Future<void> cancelDailyMoodReminder() async {
    await NotificationService.cancelDailyMoodReminder();
  }

  (int, int)? _parseHourMinute(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return (hour, minute);
  }

  void queueSessionMoodPrompt() {
    ref.read(moodPromptRequestProvider.notifier).state =
        const MoodPromptRequest(source: 'session');
  }

  void clearMoodPrompt() {
    ref.read(moodPromptRequestProvider.notifier).state = null;
  }
}
