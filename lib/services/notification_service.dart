import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:go_router/go_router.dart';
import '../core/navigation/navigation_keys.dart';
import '../models/exam.dart';
import 'notification_config.dart';
import 'notification_behavior_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _pluginInitialized = false;
  static bool _isLocalPermissionGranted = false;
      
  // In-memory cache mirrored to SharedPreferences so cooldown survives restarts.
  static final Map<String, DateTime> _lastSent = {};
  static SharedPreferences? _prefs;

  static const String _lastSentPrefix = 'notif_last_sent_';
  static const String _dailyCountPrefix = 'notif_daily_count_';
  static const int _dailyLimit = 5;
  static String? _pendingTapPayload;

  static Future<void> init({
    bool requestPermissions = true,
    bool attachForegroundListeners = true,
  }) async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedCooldowns();

    await _ensurePluginInitialized(requestPermissions: requestPermissions);

    // Explicit iOS local notification permissions (required for reliable delivery).
    if (requestPermissions) {
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (iosImplementation != null) {
        _isLocalPermissionGranted = granted ?? false;
        debugPrint('[Notification] iOS local permission granted: $_isLocalPermissionGranted');
      } else {
        // Non-iOS platforms rely on their own runtime permission flow.
        _isLocalPermissionGranted = true;
      }

    }

    // 1. Initialize timezones
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
      debugPrint('[Notification] Local timezone set: ${tz.local.name}');
    } catch (e) {
      debugPrint('[Notification] Failed to set device timezone: $e');
    }

    // 4. Request permissions
    if (requestPermissions) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // 6. Setup Firebase Messaging
    if (attachForegroundListeners) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Persist new tokens when FCM rotates
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null && newToken.isNotEmpty) {
            await Supabase.instance.client.from('users').update({
              'fcm_token': newToken,
            }).eq('id', user.id);
          }
        } catch (e) {
          debugPrint('Failed to persist refreshed FCM token: $e');
        }
      });
    }

    if (attachForegroundListeners) {
      // 7. Get token and listen for auth state to save token
      final supabase = Supabase.instance.client;
      
      // Save token if user is already logged in
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        _saveToken(currentUser.id);
      }
      
      supabase.auth.onAuthStateChange.listen((data) {
        if (data.session?.user != null) {
          _saveToken(data.session!.user.id);
        }
      });

      // 8. Handle push in app (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          final type = message.data['type'] ?? 'system';
          final id = message.data['id'] ?? '';
          _plugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            _notificationDetailsForType(type),
            payload: '$type|$id',
          );
        }
      });

      // 9. Handle background/terminated tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final type = message.data['type'];
        final id = message.data['id'];
        if (type != null) {
          _onNotificationTap("$type|${id ?? ''}");
        }
      });

      // 10. Handle cold-start (app was terminated, user tapped push)
      await _handleInitialMessage();
      // 11. Handle cold-start from local notification tap.
      await _handleInitialLocalNotificationLaunch();
    }
  }

  static Future<void> _ensurePluginInitialized({
    required bool requestPermissions,
  }) async {
    if (_pluginInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _onNotificationTap(details.payload!);
        }
      },
    );

    if (requestPermissions) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _pluginInitialized = true;
  }

  static Future<void> _loadPersistedCooldowns() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_lastSentPrefix)) continue;
      final rawValue = prefs.getString(key);
      if (rawValue == null || rawValue.isEmpty) continue;
      final parsed = DateTime.tryParse(rawValue);
      if (parsed == null) continue;
      _lastSent[key.substring(_lastSentPrefix.length)] = parsed.toUtc();
    }
  }

  static String _dailyBucketKey(DateTime now) {
    final d = now.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _storageKey(String prefix, String value) => '$prefix$value';

  static Future<int> _readCounter(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> _writeCounter(String key, int value) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<bool> _canSend(String key, {Duration? cooldown}) async {
    await _loadPersistedCooldowns();

    final now = DateTime.now().toUtc();
    final last = _lastSent[key];
    final type = key.contains('_') ? key.split('_').first : key;
    final resolvedCooldown = cooldown ?? NotificationTypeConfig.resolve(type).cooldown;
    if (last != null && now.difference(last) <= resolvedCooldown) {
      return false;
    }

    final dailyKey = _storageKey(_dailyCountPrefix, _dailyBucketKey(now));
    final dailyCount = await _readCounter(dailyKey);
    if (dailyCount >= _dailyLimit) {
      return false;
    }

    _lastSent[key] = now;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(_lastSentPrefix, key), now.toIso8601String());
    await _writeCounter(dailyKey, dailyCount + 1);
    return true;
  }

  static Importance _importanceForType(String type, {Priority? priorityOverride}) {
    final config = NotificationTypeConfig.resolve(type);
    final effectivePriority = priorityOverride ?? _priorityForType(type);
    if (config.isCritical || effectivePriority == Priority.high) return Importance.max;
    if (type == 'deadline' || type == 'deadline_batch' || type == 'academic_summary') {
      return Importance.high;
    }
    return Importance.defaultImportance;
  }

  static Priority _priorityForType(String type) {
    final config = NotificationTypeConfig.resolve(type);
    if (config.isCritical || type == 'deadline' || type == 'deadline_batch') {
      return Priority.high;
    }
    return Priority.defaultPriority;
  }

  static NotificationDetails _notificationDetailsForType(
    String type, {
    Priority? priorityOverride,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'acad_notifications',
        'Academic Alerts',
        channelDescription: 'Notifications for tasks, deadlines, and academic risk',
        importance: _importanceForType(type, priorityOverride: priorityOverride),
        priority: priorityOverride ?? _priorityForType(type),
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        fullScreenIntent: type == 'risk' || type == 'overdue' || type == 'overdue_batch',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static String _edgePriorityForType(Priority priority) {
    if (priority == Priority.high) {
      return 'HIGH';
    }
    return 'NORMAL';
  }

  static bool isNightTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.hour < 7 || current.hour >= 22;
  }

  static bool isCriticalType(String type) => NotificationTypeConfig.resolve(type).isCritical;

  static bool isSilentType(String type) => NotificationTypeConfig.resolve(type).isSilent;

  static Future<String?> _getActiveSemesterId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      final row = await Supabase.instance.client
          .from('student_profiles')
          .select('active_semester_id')
          .eq('user_id', user.id)
          .maybeSingle();
      return row?['active_semester_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> enqueueSmartNotification({
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? semesterId,
  }) async {
    final config = NotificationTypeConfig.resolve(type);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    if (!await NotificationBehaviorService.canSendDaily()) return;

    final effectiveSemesterId = semesterId ?? await _getActiveSemesterId();

    final shouldOnlyInbox = config.isSilent || (!config.allowNightDelivery && isNightTime());

    final isNew = await _writeInbox(
      userId: user.id,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      semesterId: effectiveSemesterId,
    );

    // Duplicate — inbox already has this notification. Skip push entirely so
    // the user doesn't receive repeat device alerts for the same event.
    if (!isNew) return;

    await NotificationBehaviorService.recordSent(
      type,
      highPriority: isCriticalType(type),
    );

    if (shouldOnlyInbox) return;

    await _deliverPushAndLocal(
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    );
  }

  static Future<void> _saveToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM TOKEN: $token");
      if (token != null) {
        await Supabase.instance.client.from('users').update({
          'fcm_token': token,
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint("Failed to save FCM token: $e");
    }
  }

  static void _onNotificationTap(String payload) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _pendingTapPayload = payload;
      Future<void>.delayed(const Duration(milliseconds: 800), _flushPendingTapIfAny);
      return;
    }

    final parts = payload.split("|");
    if (parts.isEmpty) return;

    final type = parts[0];
    final rawId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    unawaited(NotificationBehaviorService.recordOpened(type));

    // Normalize reference: rawId may be prefixed (task:xxx, deadline:xxx) or bare.
    String? taskId;
    String? deadlineId;
    String? examId;
    if (rawId != null) {
      if (rawId.startsWith('task:')) {
        taskId = rawId.substring(5);
      } else if (rawId.startsWith('deadline:')) {
        deadlineId = rawId.substring(9);
      } else if (rawId.startsWith('exam:')) {
        examId = rawId.substring(5);
      }
    }

    switch (type) {
      case 'due_today':
      case 'due_tomorrow':
      case 'overdue':
        if (taskId != null) {
          context.push('/task-detail?id=${Uri.encodeComponent(taskId)}');
        } else if (deadlineId != null) {
          context.push('/deadline-detail?id=${Uri.encodeComponent(deadlineId)}');
        } else {
          context.push('/tasks');
        }
        break;
      case 'task':
      case 'task_overdue':
        final id = taskId ?? rawId;
        if (id != null) {
          context.push('/task-detail?id=${Uri.encodeComponent(id)}');
        } else {
          context.push('/tasks');
        }
        break;
      case 'deadline':
      case 'deadline_batch':
        final id = deadlineId ?? rawId;
        if (id != null) {
          context.push('/deadline-detail?id=${Uri.encodeComponent(id)}');
        } else {
          context.push('/tasks');
        }
        break;
      case 'risk':
      case 'academic_summary':
      case 'stress':
        context.go('/home');
        break;
      case 'study_goal':
        context.go('/home');
        break;
      case 'mood':
      case 'mood_check':
        context.go('/home');
        break;
      case 'exam':
        if (examId != null) {
          context.push('/exam-detail?id=${Uri.encodeComponent(examId)}');
        } else {
          context.push('/exams');
        }
        break;
      default:
        context.go('/home');
    }
  }

  static void _flushPendingTapIfAny() {
    final payload = _pendingTapPayload;
    if (payload == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    _pendingTapPayload = null;
    _onNotificationTap(payload);
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final type = initialMessage.data['type'];
      final id = initialMessage.data['id'];
      if (type != null) {
        _onNotificationTap("$type|${id ?? ''}");
      }
    }
  }

  static Future<void> _handleInitialLocalNotificationLaunch() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _onNotificationTap(payload);
      }
    }
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'acad_notifications',
    'Academic Alerts',
    channelDescription: 'Notifications for tasks, deadlines, and academic risk',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableLights: true,
    enableVibration: true,
    fullScreenIntent: true,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  // Returns true if a new row was inserted, false if it was a duplicate or error.
  static Future<bool> _writeInbox({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? semesterId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': body,
        'type': type,
        'reference_id': referenceId,
        'semester_id': semesterId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Inbox write failed (duplicate or error): $e');
      return false;
    }
  }

  static Future<void> _deliverPushAndLocal({
    required String title,
    required String body,
    required String type,
    String? referenceId,
  }) async {
    await _ensurePluginInitialized(requestPermissions: false);

    final basePriority = _priorityForType(type);
    final boostPriority = await NotificationBehaviorService.userEngages(type);
    final effectivePriority = boostPriority ? Priority.high : basePriority;
    final details = _notificationDetailsForType(type, priorityOverride: effectivePriority);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final userData = await supabase
            .from('users')
            .select('fcm_token')
            .eq('id', user.id)
            .maybeSingle();

        final token = userData?['fcm_token'];

        if (token != null) {
          final pushBody = {
            'token': token,
            'title': title,
            'body': body,
            'type': type,
            'referenceId': referenceId ?? '',
            'priority': _edgePriorityForType(effectivePriority),
          };
          debugPrint('PUSH BODY JSON: ${jsonEncode(pushBody)}');
          await supabase.functions.invoke(
            'send-push',
            body: pushBody,
          );
        }
      } catch (e) {
        debugPrint("Failed to send remote push: $e");
      }
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: "$type|${referenceId ?? ""}",
    );
  }

  static Future<void> sendSmartNotification({
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? semesterId,
  }) async {
    await _ensurePluginInitialized(requestPermissions: false);

    final key = "${type}_${referenceId ?? 'general'}";
    final basePriority = _priorityForType(type);
    final boostPriority = await NotificationBehaviorService.userEngages(type);
    final effectivePriority = boostPriority ? Priority.high : basePriority;
    final reduceFrequency = await NotificationBehaviorService.ignoredTooMuch(type);
    final cooldownMultiplier = reduceFrequency ? 2 : 1;
    final config = NotificationTypeConfig.resolve(type);
    final adaptiveCooldown = config.cooldown * cooldownMultiplier;

    if (!await NotificationBehaviorService.canSendDaily()) return;

    if (effectivePriority == Priority.high && !await NotificationBehaviorService.canSendHighPriority()) {
      return;
    }

    if (!await _canSend(key, cooldown: adaptiveCooldown)) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final effectiveSemesterId = semesterId ?? await _getActiveSemesterId();

    if (user != null) {
      await _writeInbox(
        userId: user.id,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        semesterId: effectiveSemesterId,
      );
    }

    await _deliverPushAndLocal(
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    );

    await NotificationBehaviorService.recordSent(
      type,
      highPriority: effectivePriority == Priority.high,
    );
  }

  static Future<void> showCompletionNotification() async {
    await sendSmartNotification(
      title: 'Session Complete',
      body: 'Your study session has finished. Great job!',
      type: 'study_goal',
    );
  }

  static Future<void> scheduleCompletion(Duration remaining) async {
    if (remaining.isNegative || remaining == Duration.zero) return;

    await _plugin.cancel(0);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(remaining);

    await _plugin.zonedSchedule(
      0,
      'Session Complete',
      'Your study session has finished. Great job!',
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'study_goal|',
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> scheduleDailyMoodReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(1001);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1001,
      title,
      body,
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'mood|',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyMoodReminder() async {
    await _plugin.cancel(1001);
  }

  static int _examReminderId(String examId, int slot) {
    final base = examId.hashCode.abs() & 0x7fffffff;
    final offset = switch (slot) {
      24 => 1,
      2 => 2,
      0 => 3, // exact exam-time reminder
      -1 => 4, // near-time fallback reminder
      _ => 5,
    };
    return (base + offset) & 0x7fffffff;
  }

  static Future<void> _recordExamNotification({
    required String examId,
    required String title,
    required DateTime examAt,
    required bool isTurkish,
    required String locationText,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final semesterId = await _getActiveSemesterId();
    final formattedTime = '${examAt.hour.toString().padLeft(2, '0')}:${examAt.minute.toString().padLeft(2, '0')}';

    // Keep one up-to-date exam notification row per exam reminder source.
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .eq('type', 'exam')
          .eq('reference_id', 'exam:$examId');
    } catch (_) {
      // Best-effort cleanup; continue with insert.
    }

    await _writeInbox(
      userId: user.id,
      title: title,
      body: isTurkish
          ? '$formattedTime • $locationText'
          : 'Starts at $formattedTime • $locationText',
      type: 'exam',
      referenceId: 'exam:$examId',
      semesterId: semesterId,
    );
  }

  static Future<void> scheduleExamReminders({
    required String examId,
    required String title,
    required String examType,
    required DateTime examDateTime,
    required bool isOnline,
    String? classroom,
  }) async {
    await _ensurePluginInitialized(requestPermissions: false);
    debugPrint('[Notification] scheduleExamReminders called for examId=$examId');
    if (!_isLocalPermissionGranted) {
      debugPrint('[Notification] Skipped scheduling exam reminders - local permission not granted');
      return;
    }

    // iOS can briefly reject scheduling right after permission grant (Error 4097).
    await Future.delayed(const Duration(milliseconds: 500));

    final now = tz.TZDateTime.now(tz.local);
    final examAt = tz.TZDateTime.from(examDateTime.toLocal(), tz.local);
    debugPrint(
      '[Notification] Timezone=${tz.local.name} now=$now examAt=$examAt source=${examDateTime.toIso8601String()} isUtc=${examDateTime.isUtc} offset=${examDateTime.timeZoneOffset}',
    );
    if (examAt.isBefore(now)) {
      debugPrint('[Notification] Skipped - exam time is in the past');
      return;
    }
    final isTurkish = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase().startsWith('tr');
    final time = '${examAt.hour.toString().padLeft(2, '0')}:${examAt.minute.toString().padLeft(2, '0')}';
    final parsedType = ExamType.fromDb(examType);
    final examTypeLabel = isTurkish
        ? switch (parsedType) {
            ExamType.midterm => 'Vize',
            ExamType.finalExam => 'Final',
            ExamType.quiz => 'Quiz',
          }
        : switch (parsedType) {
            ExamType.midterm => 'Midterm',
            ExamType.finalExam => 'Final',
            ExamType.quiz => 'Quiz',
          };
    final locationText = isOnline
        ? (isTurkish ? 'Online Sinav' : 'Online')
        : ((classroom == null || classroom.trim().isEmpty)
              ? (isTurkish ? 'Sinif' : 'Classroom')
              : (isTurkish ? 'Oda ${classroom.trim()}' : 'Room ${classroom.trim()}'));

    await _recordExamNotification(
      examId: examId,
      title: title,
      examAt: examAt.toLocal(),
      isTurkish: isTurkish,
      locationText: locationText,
    );

    final oneDayBefore = examAt.subtract(const Duration(hours: 24));
    debugPrint('[Notification] oneDayBefore=$oneDayBefore');
    if (oneDayBefore.isAfter(now)) {
      debugPrint('[Notification] Scheduling 24h reminder at: $oneDayBefore');
      await _plugin.zonedSchedule(
        _examReminderId(examId, 24),
        isTurkish ? 'Sinav YarIn' : 'Exam Tomorrow',
        isTurkish
            ? 'Yarin: $title $examTypeLabel\n$time • $locationText'
            : 'Tomorrow: $title $examTypeLabel\n$time • $locationText',
        oneDayBefore,
        _notificationDetailsForType('deadline'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exam|exam:$examId',
      );
    } else {
      debugPrint('[Notification] Skipped 24h reminder - time is in the past');
    }

    final twoHoursBefore = examAt.subtract(const Duration(hours: 2));
    debugPrint('[Notification] twoHoursBefore=$twoHoursBefore');
    if (twoHoursBefore.isAfter(now)) {
      debugPrint('[Notification] Scheduling 2h reminder at: $twoHoursBefore');
      await _plugin.zonedSchedule(
        _examReminderId(examId, 2),
        isTurkish ? 'Sinav Yakinda' : 'Exam Soon',
        isTurkish
            ? '2 saat sonra: $title $examTypeLabel\nOdagini koru'
            : 'In 2 hours: $title $examTypeLabel\nStay focused',
        twoHoursBefore,
        _notificationDetailsForType('deadline'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exam|exam:$examId',
      );
    } else {
      debugPrint('[Notification] Skipped 2h reminder - time is in the past');
    }

    // Always schedule exact exam-time reminder when exam is still upcoming.
    if (examAt.isAfter(now)) {
      debugPrint('[Notification] Scheduling exam-time reminder at: $examAt');
      await _plugin.zonedSchedule(
        _examReminderId(examId, 0),
        isTurkish ? 'Sinav Simdi' : 'Exam Now',
        isTurkish
            ? '$title $examTypeLabel simdi basliyor\n$time • $locationText'
            : '$title $examTypeLabel is starting now\n$time • $locationText',
        examAt,
        _notificationDetailsForType('deadline'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exam|exam:$examId',
      );
    } else {
      // Safety: if exam is very near and TZ jitter made it slightly in the past.
      final immediate = now.add(const Duration(seconds: 10));
      debugPrint('[Notification] Scheduling immediate fallback reminder at: $immediate');
      await _plugin.zonedSchedule(
        _examReminderId(examId, -1),
        isTurkish ? 'Sinav Yakinda' : 'Exam Soon',
        isTurkish
            ? '$title $examTypeLabel cok yakinda\n$time • $locationText'
            : '$title $examTypeLabel is coming up\n$time • $locationText',
        immediate,
        _notificationDetailsForType('deadline'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exam|exam:$examId',
      );
    }
  }

  static Future<void> cancelExamReminders(String examId) async {
    await _plugin.cancel(_examReminderId(examId, 24));
    await _plugin.cancel(_examReminderId(examId, 2));
    await _plugin.cancel(_examReminderId(examId, 0));
    await _plugin.cancel(_examReminderId(examId, -1));
  }
}
