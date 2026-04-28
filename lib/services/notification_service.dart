import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:go_router/go_router.dart';
import '../main.dart'; // import rootNavigatorKey
import 'notification_config.dart';
import 'notification_behavior_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _pluginInitialized = false;
      
  // In-memory cache mirrored to SharedPreferences so cooldown survives restarts.
  static final Map<String, DateTime> _lastSent = {};
  static SharedPreferences? _prefs;

  static const String _lastSentPrefix = 'notif_last_sent_';
  static const String _dailyCountPrefix = 'notif_daily_count_';
  static const int _dailyLimit = 5;

  static Future<void> init({
    bool requestPermissions = true,
    bool attachForegroundListeners = true,
  }) async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedCooldowns();

    await _ensurePluginInitialized(requestPermissions: requestPermissions);

    // 1. Initialize timezones
    tz.initializeTimeZones();

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
        final androidMessage = message.notification?.android;

        if (notification != null && androidMessage != null) {
          _plugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            _notificationDetails,
            payload: message.data['type'] != null 
                ? "${message.data['type']}|${message.data['id'] ?? ''}" 
                : null,
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

  static Future<void> enqueueSmartNotification({
    required String title,
    required String body,
    required String type,
    String? referenceId,
  }) async {
    final config = NotificationTypeConfig.resolve(type);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    if (!await NotificationBehaviorService.canSendDaily()) return;

    final shouldOnlyInbox = config.isSilent || (!config.allowNightDelivery && isNightTime());
    try {
      await supabase.from('notifications').insert({
        'user_id': user.id,
        'title': title,
        'message': body,
        'type': type,
        if (referenceId != null) 'reference_id': referenceId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // If inbox write fails, do not block other channels.
    }

    await NotificationBehaviorService.recordSent(
      type,
      highPriority: isCriticalType(type),
    );

    if (shouldOnlyInbox) return;

    await sendSmartNotification(
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    );
  }

  static Future<void> _saveToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN: $token"); // Debugging: Check if token is generated
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
    if (context == null) return;
    
    final parts = payload.split("|");
    if (parts.isEmpty) return;
    
    final type = parts[0];
    final id = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    unawaited(NotificationBehaviorService.recordOpened(type));
    
    if (type == "task" && id != null) {
      context.push('/task-detail?id=${Uri.encodeComponent(id)}');
    } else if (type == "deadline" && id != null) {
      context.push('/deadline-detail?id=${Uri.encodeComponent(id)}');
    } else if (type == "risk") {
      context.go('/home'); // Go to Home where Risk/Analytics are visible
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

  static Future<void> sendSmartNotification({
    required String title,
    required String body,
    required String type,
    String? referenceId,
  }) async {
    await _ensurePluginInitialized(requestPermissions: false);

    // 1. Anti-spam check (persistent cooldown + global rate limit)
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
    final details = _notificationDetailsForType(type, priorityOverride: effectivePriority);
    if (user != null) {
      // 2. Save to DB (Inbox)
      try {
        await supabase.from('notifications').insert({
          'user_id': user.id,
          'title': title,
          'message': body,
          'type': type,
          if (referenceId != null) 'reference_id': referenceId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        // Ignore DB save errors
      }

      // 3. Remote push (Firebase Edge Function)
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

    // 4. Show local push (Instant UI sync if app is open)
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: "$type|${referenceId ?? ""}",
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
}
