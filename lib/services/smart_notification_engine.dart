import 'package:acadia/models/analytics_data.dart';
import 'package:acadia/models/task.dart';
import 'package:acadia/services/notification_service.dart';

/// Optional fetcher type used to obtain fresh task lists from repositories
typedef TaskFetcher = Future<List<Task>> Function();

class SmartNotificationEngine {
  static Future<void> evaluateTaskChanges(List<Task> tasks) async {
    await _handleAcademicContext(tasks);
  }

  static Future<void> evaluate({
    required AnalyticsData analytics,
    List<Task>? tasks,
    TaskFetcher? fetchTasks,
  }) async {
    // Ensure we use fresh task data when possible. Prefer explicit tasks, then
    // fall back to the provided fetcher to avoid relying on UI state.
    final effectiveTasks = (tasks != null && tasks.isNotEmpty)
        ? tasks
        : (fetchTasks != null ? await fetchTasks() : <Task>[]);

    await _handleAcademicContext(effectiveTasks);
    await _handleRisk(analytics);
    await _handleStress(analytics);
  }

  static Future<void> _handleAcademicContext(List<Task> tasks) async {
    final now = DateTime.now();
    final upcoming = tasks
        .where((task) => !task.isCompleted)
        .where((task) {
          final dueDate = task.deadline;
          if (dueDate == null) return false;
          final diff = dueDate.difference(now).inHours;
          return diff <= 24 && diff > 0;
        })
        .toList();

    final overdueTasks = tasks.where((task) {
      if (task.isCompleted) return false;
      final dueDate = task.deadline;
      if (dueDate == null) return false;
      return dueDate.isBefore(now);
    }).toList();

    final totalCriticalItems = overdueTasks.length + upcoming.length;
    if (totalCriticalItems == 0) return;

    if (totalCriticalItems > 1) {
      final parts = <String>[];
      if (overdueTasks.isNotEmpty) {
        parts.add('${overdueTasks.length} overdue');
      }
      if (upcoming.isNotEmpty) {
        parts.add('${upcoming.length} due in 24h');
      }

      await NotificationService.enqueueSmartNotification(
        title: 'Academic Summary',
        body: 'You have ${parts.join(' and ')}.',
        type: 'academic_summary',
        referenceId: 'academic_summary:${nowStamp()}',
      );
      return;
    }

    if (upcoming.isNotEmpty) {
      final task = upcoming.first;
      await NotificationService.enqueueSmartNotification(
        title: 'Deadline Tomorrow',
        body: '${task.title} is due soon.',
        type: 'due_tomorrow',
        referenceId: 'task:${task.id}',
      );
      return;
    }

    if (overdueTasks.length == 1) {
      final task = overdueTasks.first;
      await NotificationService.enqueueSmartNotification(
        title: 'Task Overdue',
        body: '${task.title} is overdue.',
        type: 'overdue',
        referenceId: 'task:${task.id}',
      );
    }
  }

  static Future<void> _handleRisk(AnalyticsData analytics) async {
    final risk = analytics.riskScore;
    if (risk >= 70) {
      await NotificationService.enqueueSmartNotification(
        title: "High Academic Risk",
        body: "Your risk is ${risk.toStringAsFixed(1)}. Take action now.",
        type: "risk",
        referenceId: 'risk:${nowStamp()}',
      );
    } else if (risk >= 50) {
      await NotificationService.enqueueSmartNotification(
        title: "Moderate Risk",
        body: "Stay consistent to avoid falling behind.",
        type: "risk",
        referenceId: 'risk:${nowStamp()}',
      );
    }
  }

  static Future<void> _handleStress(AnalyticsData analytics) async {
    if (!analytics.hasStressData) return;
    if (analytics.avgStress >= 7) {
      await NotificationService.enqueueSmartNotification(
        title: "High Stress Detected",
        body: "Consider taking a break or adjusting your workload.",
        type: "stress",
        referenceId: 'stress:${nowStamp()}',
      );
    }
  }

  static String nowStamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
