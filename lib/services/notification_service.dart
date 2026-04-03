import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize timezones
    tz.initializeTimeZones();
    
    // 2. Configure Android settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 3. Configure iOS settings
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    // 4. Initialize plugin
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
    
    // 5. Request permissions for Android 13+
    await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'study_timer_channel',
    'Study Timer Notifications',
    channelDescription: 'Notifications for study session completion',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableLights: true,
    enableVibration: true,
    fullScreenIntent: true,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  static Future<void> showCompletionNotification() async {
    await _plugin.show(
      0,
      'Session Complete',
      'Your study session has finished. Great job!',
      _notificationDetails,
    );
  }

  static Future<void> scheduleCompletion(Duration remaining) async {
    if (remaining.isNegative || remaining == Duration.zero) return;

    // Always cancel existing with ID 0 before scheduling a new one
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
      payload: 'study_complete',
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
