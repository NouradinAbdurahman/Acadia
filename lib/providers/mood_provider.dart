import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood_log.dart';
import '../models/mood_settings.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'semester_provider.dart';
import 'analytics_provider.dart';
import 'risk_provider.dart';

class MoodPromptRequest {
  final String source;

  const MoodPromptRequest({required this.source});
}

final moodPromptRequestProvider = StateProvider<MoodPromptRequest?>((ref) {
  return null;
});

final moodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final semesterId = ref.watch(activeSemesterProvider);
  if (semesterId == null) return <MoodLog>[];

  return ref.read(moodRepositoryProvider).getMoodLogs(semesterId: semesterId);
});

final todayMoodProvider = FutureProvider<bool>((ref) async {
  final logs = await ref.watch(moodLogsProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return logs.any((log) {
    final logDate = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
    return logDate == today;
  });
});

final moodSettingsProvider = FutureProvider<MoodSettings?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  return ref.read(moodRepositoryProvider).getMoodSettings(userId: userId);
});

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
    final semesterId = ref.read(activeSemesterProvider);

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

    // Invalidate providers to trigger UI updates using microtask
    Future.microtask(() {
      ref.invalidate(moodLogsProvider);
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
