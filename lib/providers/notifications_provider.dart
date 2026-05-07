import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';
import 'app_providers.dart';
import 'analytics_provider.dart';
import 'semester_provider.dart';
import 'locale_provider.dart';
import 'mood_provider.dart';
import '../l10n/app_localizations.dart';

class _NotificationSeed {
  const _NotificationSeed({
    required this.referenceId,
    required this.type,
    required this.title,
    required this.message,
  });

  final String referenceId;
  final String type;
  final String title;
  final String message;
}

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationsNotifier({
    required this.ref,
    required this.notificationRepository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading()) {
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous == next) return;
      if (_isLoading) {
        // Initial load is in flight — mark for retry so the locale change
        // isn't silently dropped when _isLoading resets.
        _pendingLocaleReload = true;
      } else {
        loadNotifications();
      }
    });
    loadNotifications();
  }

  final Ref ref;
  final dynamic notificationRepository;
  final SupabaseClient supabaseClient;

  RealtimeChannel? _realtimeChannel;
  String? _subscribedUserId;
  Timer? _reloadDebounce;
  bool _isLoading = false;
  bool _pendingLocaleReload = false;
  int _fetchGeneration = 0;
  int _loadGeneration = 0;

  bool _payloadBelongsToUser(dynamic payload, String userId) {
    final newUserId = payload.newRecord['user_id']?.toString();
    final oldUserId = payload.oldRecord['user_id']?.toString();
    return newUserId == userId || oldUserId == userId;
  }

  void _scheduleReload({required bool withSync}) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final semesterId = ref.read(activeSemesterProvider).value;
      if (semesterId == null) {
        if (!mounted) return;
        state = const AsyncValue.data([]);
        return;
      }

      if (withSync) {
        loadNotifications();
      } else {
        _fetchNotificationsOnly(semesterId: semesterId);
      }
    });
  }

  Future<void> _fetchNotificationsOnly({required String semesterId}) async {
    final currentGeneration = ++_fetchGeneration;
    if (!mounted) return;
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted || currentGeneration != _fetchGeneration) return;
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final notifications =
          await notificationRepository.getNotifications(
                userId: userId,
                semesterId: semesterId,
              )
              as List<NotificationModel>;
      if (!mounted || currentGeneration != _fetchGeneration) return;
      state = AsyncValue.data(notifications);
    } catch (_) {
      if (!mounted || currentGeneration != _fetchGeneration) return;
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _ensureRealtimeSubscription(String userId) async {
    if (_subscribedUserId == userId && _realtimeChannel != null) {
      return;
    }

    if (_realtimeChannel != null) {
      await supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }

    _subscribedUserId = userId;

    _realtimeChannel = supabaseClient
        .channel('notifications-live-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            if (_payloadBelongsToUser(payload, userId)) {
              _scheduleReload(withSync: false);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            if (_payloadBelongsToUser(payload, userId)) {
              _scheduleReload(withSync: true);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'academic_deadlines',
          callback: (payload) {
            if (_payloadBelongsToUser(payload, userId)) {
              _scheduleReload(withSync: true);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'study_sessions',
          callback: (payload) {
            if (_payloadBelongsToUser(payload, userId)) {
              _scheduleReload(withSync: true);
            }
          },
        )
        .subscribe();
  }

  Future<void> _ensureDailyNotification({
    required String userId,
    required String semesterId,
    required String referenceId,
    required String type,
    required String title,
    required String message,
  }) async {
    final existing = await supabaseClient
        .from('notifications')
        .select('id,title,message')
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .eq('reference_id', referenceId)
        .eq('type', type)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      if (existing['title'] != title || existing['message'] != message) {
        await supabaseClient
            .from('notifications')
            .update({'title': title, 'message': message})
            .eq('id', existing['id']);
      }
      return;
    }

    await notificationRepository.createNotification(
      NotificationModel(
        id: '',
        userId: userId,
        semesterId: semesterId,
        referenceId: referenceId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _removeLegacyStaticNotifications(String userId) async {
    await supabaseClient
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .or('title.eq.Deadline tomorrow,title.eq.Overdue tasks');
  }

  Future<void> _cleanupExistingDuplicates(String userId) async {
    await supabaseClient
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .inFilter('type', ['due_today', 'due_tomorrow', 'overdue'])
        .isFilter('reference_id', null);

    final rows = await supabaseClient
        .from('notifications')
        .select('id,type,title,message,reference_id,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final dedupableTypes = <String>{
      'due_today',
      'due_tomorrow',
      'overdue',
      'task_overdue',
      'deadline',
      'deadline_batch',
      'overdue_batch',
      'mood_check',
    };
    final seen = <String>{};
    final toDelete = <String>[];

    for (final row in rows) {
      final type = (row['type'] ?? '').toString();
      if (!dedupableTypes.contains(type)) continue;

      final refId = row['reference_id']?.toString();
      final key = refId != null && refId.isNotEmpty
          ? '$refId|$type'
          : '${(row['title'] ?? '').toString().trim().toLowerCase()}|${(row['message'] ?? '').toString().trim().toLowerCase()}|$type';

      if (seen.contains(key)) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) toDelete.add(id);
      } else {
        seen.add(key);
      }
    }

    if (toDelete.isNotEmpty) {
      await supabaseClient
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', toDelete);
    }
  }

  String _formatMonthDay(DateTime date, Locale locale) {
    return DateFormat.MMMd(locale.toString()).format(date);
  }

  String _normalizeKeyPart(String? value) {
    if (value == null) return '';
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _itemIdentityKey({
    required String title,
    required String courseName,
    required DateTime dueDate,
  }) {
    final normalizedTitle = _normalizeKeyPart(title);
    final normalizedCourse = _normalizeKeyPart(courseName);
    final dateKey = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).toIso8601String();
    return '$normalizedTitle|$normalizedCourse|$dateKey';
  }

  String? _dueTypeForDate({
    required DateTime dueDate,
    required DateTime startOfToday,
    required DateTime startOfTomorrow,
    required DateTime startOfDayAfterTomorrow,
  }) {
    if (dueDate.isBefore(startOfToday)) return 'overdue';
    if (dueDate.isBefore(startOfTomorrow)) return 'due_today';
    if (dueDate.isBefore(startOfDayAfterTomorrow)) return 'due_tomorrow';
    return null;
  }

  String _contextForType(String type, DateTime dueDate, AppLocalizations l10n) {
    switch (type) {
      case 'overdue':
        return l10n.notificationOverdue;
      case 'due_today':
        return l10n.notificationDueToday;
      case 'due_tomorrow':
        return l10n.notificationDueTomorrow;
      default:
        return l10n.notificationDueSoon;
    }
  }

  Future<List<_NotificationSeed>> _buildTaskAndDeadlineSeeds({
    required String userId,
    required String semesterId,
    required AppLocalizations l10n,
    required Locale locale,
  }) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final startOfDayAfterTomorrow = startOfToday.add(const Duration(days: 2));

    final taskRows = await supabaseClient
        .from('tasks')
        .select(
          'id,title,course,course_id,deadline,status,courses:course_id(course_name)',
        )
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .neq('status', 'completed');

    final deadlineRows = await supabaseClient
        .from('academic_deadlines')
        .select(
          'id,title,course,course_id,deadline_date,courses:course_id(course_name)',
        )
        .eq('user_id', userId)
        .eq('semester_id', semesterId)
        .eq('is_completed', false);

    final seeds = <_NotificationSeed>[];
    final taskIdentityKeys = <String>{};

    for (final row in taskRows) {
      final rawDeadline = row['deadline'];
      if (rawDeadline == null) continue;

      final dueDate = DateTime.tryParse(rawDeadline.toString());
      if (dueDate == null) continue;

      final type = _dueTypeForDate(
        dueDate: dueDate,
        startOfToday: startOfToday,
        startOfTomorrow: startOfTomorrow,
        startOfDayAfterTomorrow: startOfDayAfterTomorrow,
      );
      if (type == null) continue;

      final courseFromJoin =
          (row['courses'] as Map<String, dynamic>?)?['course_name']?.toString();
      final courseName =
          courseFromJoin ?? row['course']?.toString() ?? 'Course';
      final taskTitle = row['title']?.toString() ?? '';
      if (taskTitle.isEmpty) continue;

      final taskId = row['id']?.toString();
      if (taskId == null || taskId.isEmpty) continue;

      taskIdentityKeys.add(
        _itemIdentityKey(
          title: taskTitle,
          courseName: courseName,
          dueDate: dueDate,
        ),
      );

      seeds.add(
        _NotificationSeed(
          referenceId: 'task:$taskId',
          type: type,
          title: '$taskTitle ${_contextForType(type, dueDate, l10n)}',
          message: '$courseName • ${_formatMonthDay(dueDate, locale)}',
        ),
      );
    }

    for (final row in deadlineRows) {
      final rawDeadline = row['deadline_date'];
      if (rawDeadline == null) continue;

      final dueDate = DateTime.tryParse(rawDeadline.toString());
      if (dueDate == null) continue;

      final type = _dueTypeForDate(
        dueDate: dueDate,
        startOfToday: startOfToday,
        startOfTomorrow: startOfTomorrow,
        startOfDayAfterTomorrow: startOfDayAfterTomorrow,
      );
      if (type == null) continue;

      final courseFromJoin =
          (row['courses'] as Map<String, dynamic>?)?['course_name']?.toString();
      final courseName =
          courseFromJoin ?? row['course']?.toString() ?? 'Course';
      final deadlineTitle = row['title']?.toString() ?? '';
      if (deadlineTitle.isEmpty) continue;

      final dedupKey = _itemIdentityKey(
        title: deadlineTitle,
        courseName: courseName,
        dueDate: dueDate,
      );
      if (taskIdentityKeys.contains(dedupKey)) {
        // Task notifications are the source of truth when the same item exists.
        continue;
      }

      final deadlineId = row['id']?.toString();
      if (deadlineId == null || deadlineId.isEmpty) continue;

      seeds.add(
        _NotificationSeed(
          referenceId: 'deadline:$deadlineId',
          type: type,
          title: '$deadlineTitle ${_contextForType(type, dueDate, l10n)}',
          message: '$courseName • ${_formatMonthDay(dueDate, locale)}',
        ),
      );
    }

    return seeds;
  }

  Future<void> _syncTriggeredNotifications({
    required String userId,
    required String semesterId,
    required AppLocalizations l10n,
    required Locale locale,
  }) async {
    await _removeLegacyStaticNotifications(userId);
    await _cleanupExistingDuplicates(userId);

    final seeds = await _buildTaskAndDeadlineSeeds(
      userId: userId,
      semesterId: semesterId,
      l10n: l10n,
      locale: locale,
    );
    for (final seed in seeds) {
      await _ensureDailyNotification(
        userId: userId,
        semesterId: semesterId,
        referenceId: seed.referenceId,
        type: seed.type,
        title: seed.title,
        message: seed.message,
      );
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final moodSettings = ref.read(moodSettingsProvider);
    final shouldCreateMoodCheck =
        moodSettings.trackingEnabled &&
        moodSettings.reminderEnabled &&
        (moodSettings.reminderType == 'daily' ||
            moodSettings.reminderType == 'both');

    if (shouldCreateMoodCheck) {
      final startOfTomorrow = startOfToday.add(const Duration(days: 1));
      final todayMoodLog = await supabaseClient
          .from('mood_logs')
          .select('id')
          .eq('user_id', userId)
          .eq('semester_id', semesterId)
          .gte('created_at', startOfToday.toIso8601String())
          .lt('created_at', startOfTomorrow.toIso8601String())
          .limit(1)
          .maybeSingle();

      if (todayMoodLog == null) {
        final todayKey = DateTime(
          startOfToday.year,
          startOfToday.month,
          startOfToday.day,
        ).toIso8601String();
        await _ensureDailyNotification(
          userId: userId,
          semesterId: semesterId,
          referenceId: 'mood_check:$todayKey',
          type: 'mood_check',
          title: l10n.moodCheckNotificationTitle,
          message: l10n.moodCheckNotificationMessage,
        );
      }
    }

    if (now.weekday == DateTime.sunday) {
      final weeklyGoalMinutes = (ref.read(weeklyStudyGoalHoursProvider) * 60);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );

      final weekSessions = await supabaseClient
          .from('study_sessions')
          .select('duration_minutes')
          .eq('user_id', userId)
          .eq('semester_id', semesterId)
          .gte('created_at', startOfWeek.toIso8601String());

      final weekMinutes = weekSessions.fold<int>(
        0,
        (sum, row) => sum + ((row['duration_minutes'] as num?)?.toInt() ?? 0),
      );

      if (weekMinutes < weeklyGoalMinutes) {
        final weekKey = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ).toIso8601String();
        await _ensureDailyNotification(
          userId: userId,
          semesterId: semesterId,
          referenceId: 'study_goal:$weekKey',
          type: 'study_goal',
          title: l10n.weeklyStudyGoalMissed,
          message: l10n.weeklyStudyGoalMissedMessage(
            (weekMinutes / 60).toStringAsFixed(1),
            (weeklyGoalMinutes / 60).toStringAsFixed(1),
          ),
        );
      }
    }
  }

  Future<void> loadNotifications() async {
    if (_isLoading) return;
    final currentGeneration = ++_loadGeneration;
    if (!mounted) return;

    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = ref.read(activeSemesterProvider).value;
    if (userId == null) {
      _subscribedUserId = null;
      if (_realtimeChannel != null) {
        await supabaseClient.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
      if (!mounted || currentGeneration != _loadGeneration) return;
      state = const AsyncValue.data([]);
      return;
    }

    if (semesterId == null) {
      if (!mounted || currentGeneration != _loadGeneration) return;
      state = const AsyncValue.data([]);
      return;
    }

    try {
      _isLoading = true;
      final l10n = ref.read(appLocalizationsProvider);
      final locale = ref.read(localeProvider);
      
      await _ensureRealtimeSubscription(userId);
      try {
        await _syncTriggeredNotifications(
          userId: userId,
          semesterId: semesterId,
          l10n: l10n,
          locale: locale,
        );
      } catch (_) {
        // Non-critical: fetch existing notifications even if sync step fails.
      }

      final notifications =
          await notificationRepository.getNotifications(
                userId: userId,
                semesterId: semesterId,
              )
              as List<NotificationModel>;
      if (!mounted || currentGeneration != _loadGeneration) return;
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      if (!mounted || currentGeneration != _loadGeneration) return;
      state = AsyncValue.error(e, st);
    } finally {
      if (!mounted || currentGeneration != _loadGeneration) return;
      _isLoading = false;
      if (_pendingLocaleReload) {
        _pendingLocaleReload = false;
        loadNotifications();
      }
    }
  }

  Future<void> markAsRead(String id) async {
    if (!mounted) return;
    final currentNotifications = state.valueOrNull;
    if (currentNotifications != null) {
      // Optimistic UI update so NEW badge clears immediately.
      state = AsyncValue.data(
        currentNotifications
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
      );
    }
    try {
      final updated =
          await notificationRepository.markAsRead(id) as NotificationModel;
      if (!mounted) return;
      state = state.whenData(
        (items) => items.map((n) => n.id == updated.id ? updated : n).toList(),
      );
    } catch (_) {
      // Roll back from server if mark-as-read fails.
      if (!mounted) return;
      loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    if (!mounted) return;
    final currentNotifications = state.valueOrNull;
    if (currentNotifications == null || currentNotifications.isEmpty) return;

    final unreadIds = currentNotifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (unreadIds.isEmpty) return;

    try {
      // Optimistic update
      if (!mounted) return;
      state = AsyncValue.data(
        currentNotifications.map((NotificationModel n) => n.copyWith(isRead: true)).toList(),
      );

      await notificationRepository.markAllAsRead(unreadIds);
    } catch (_) {
      // Rollback or reload on error
      if (!mounted) return;
      loadNotifications();
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    if (_realtimeChannel != null) {
      supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      ref.watch(activeSemesterProvider);
      final repo = ref.watch(notificationRepositoryProvider);
      final supabase = Supabase.instance.client;
      return NotificationsNotifier(
        ref: ref,
        notificationRepository: repo,
        supabaseClient: supabase,
      );
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (items) => items.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
