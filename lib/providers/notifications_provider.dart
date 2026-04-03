import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';
import 'app_providers.dart';

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
    required this.notificationRepository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  final dynamic notificationRepository;
  final SupabaseClient supabaseClient;

  RealtimeChannel? _realtimeChannel;
  String? _subscribedUserId;
  Timer? _reloadDebounce;
  bool _isLoading = false;

  bool _payloadBelongsToUser(dynamic payload, String userId) {
    final newUserId = payload.newRecord['user_id']?.toString();
    final oldUserId = payload.oldRecord['user_id']?.toString();
    return newUserId == userId || oldUserId == userId;
  }

  void _scheduleReload({required bool withSync}) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (withSync) {
        loadNotifications();
      } else {
        _fetchNotificationsOnly();
      }
    });
  }

  Future<void> _fetchNotificationsOnly() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final notifications =
          await notificationRepository.getNotifications(userId)
              as List<NotificationModel>;
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
    required String referenceId,
    required String type,
    required String title,
    required String message,
  }) async {
    final existing = await supabaseClient
        .from('notifications')
        .select('id,title,message')
        .eq('user_id', userId)
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

    final seen = <String>{};
    final toDelete = <String>[];

    for (final row in rows) {
      final refId = row['reference_id']?.toString();
      final key = refId != null && refId.isNotEmpty
          ? '$refId|${row['type']}'
          : '${(row['title'] ?? '').toString().trim().toLowerCase()}|${(row['message'] ?? '').toString().trim().toLowerCase()}|${row['type']}';

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

  String _formatMonthDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}';
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

  String _contextForType(String type, DateTime dueDate) {
    switch (type) {
      case 'overdue':
        return 'is overdue';
      case 'due_today':
        return 'is due today';
      case 'due_tomorrow':
        return 'is due tomorrow';
      default:
        return 'is due soon';
    }
  }

  Future<List<_NotificationSeed>> _buildTaskAndDeadlineSeeds(
    String userId,
  ) async {
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
        .neq('status', 'completed');

    final deadlineRows = await supabaseClient
        .from('academic_deadlines')
        .select(
          'id,title,course,course_id,deadline_date,courses:course_id(course_name)',
        )
        .eq('user_id', userId)
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
          title: '$taskTitle ${_contextForType(type, dueDate)}',
          message: '$courseName • ${_formatMonthDay(dueDate)}',
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
          title: '$deadlineTitle ${_contextForType(type, dueDate)}',
          message: '$courseName • ${_formatMonthDay(dueDate)}',
        ),
      );
    }

    return seeds;
  }

  Future<void> _syncTriggeredNotifications(String userId) async {
    await _removeLegacyStaticNotifications(userId);
    await _cleanupExistingDuplicates(userId);

    final seeds = await _buildTaskAndDeadlineSeeds(userId);
    for (final seed in seeds) {
      await _ensureDailyNotification(
        userId: userId,
        referenceId: seed.referenceId,
        type: seed.type,
        title: seed.title,
        message: seed.message,
      );
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (now.weekday == DateTime.sunday) {
      final profile = await supabaseClient
          .from('student_profiles')
          .select('study_hours_per_week')
          .eq('user_id', userId)
          .maybeSingle();

      final weeklyGoalMinutes =
          (((profile?['study_hours_per_week'] as num?)?.toInt() ?? 20) * 60);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );

      final weekSessions = await supabaseClient
          .from('study_sessions')
          .select('duration_minutes')
          .eq('user_id', userId)
          .gte('start_time', startOfWeek.toIso8601String());

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
          referenceId: 'study_goal:$weekKey',
          type: 'study_goal',
          title: 'Weekly study goal missed',
          message:
              'You studied ${(weekMinutes / 60).toStringAsFixed(1)}h of ${(weeklyGoalMinutes / 60).toStringAsFixed(1)}h this week.',
        );
      }
    }
  }

  Future<void> loadNotifications() async {
    if (_isLoading) return;

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      _subscribedUserId = null;
      if (_realtimeChannel != null) {
        await supabaseClient.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
      state = const AsyncValue.data([]);
      return;
    }

    try {
      _isLoading = true;
      await _ensureRealtimeSubscription(userId);
      await _syncTriggeredNotifications(userId);
      final notifications =
          await notificationRepository.getNotifications(userId)
              as List<NotificationModel>;
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final updated =
          await notificationRepository.markAsRead(id) as NotificationModel;
      state = state.whenData(
        (items) => items.map((n) => n.id == updated.id ? updated : n).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
      final repo = ref.watch(notificationRepositoryProvider);
      final supabase = Supabase.instance.client;
      return NotificationsNotifier(
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
