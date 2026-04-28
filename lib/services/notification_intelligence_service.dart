import 'package:acadia/models/analytics_data.dart';
import 'package:acadia/models/task.dart';

import 'notification_config.dart';
import 'notification_service.dart';
import 'smart_notification_engine.dart';

class NotificationIntelligenceService {
  static Future<void> evaluateForeground({
    required AnalyticsData analytics,
    List<Task>? tasks,
    TaskFetcher? fetchTasks,
  }) {
    return SmartNotificationEngine.evaluate(
      analytics: analytics,
      tasks: tasks,
      fetchTasks: fetchTasks,
    );
  }

  static Future<void> evaluateBackground({
    required AnalyticsData analytics,
    List<Task>? tasks,
    TaskFetcher? fetchTasks,
  }) {
    // Same decision logic can be executed from a background worker / fetch.
    // Platform-specific scheduling still needs to call this entry point.
    return SmartNotificationEngine.evaluate(
      analytics: analytics,
      tasks: tasks,
      fetchTasks: fetchTasks,
    );
  }

  static NotificationConfig configFor(String type) {
    return NotificationTypeConfig.resolve(type);
  }

  static bool shouldDeferDelivery() {
    return NotificationService.isNightTime();
  }

  static bool isCritical(String type) => NotificationService.isCriticalType(type);

  static bool isSilent(String type) => NotificationService.isSilentType(type);
}
