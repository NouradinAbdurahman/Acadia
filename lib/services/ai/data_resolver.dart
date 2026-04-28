import 'package:intl/intl.dart';
import '../../models/ai_intent.dart';
import '../../models/ai_message.dart';
import '../../models/task.dart';
import '../../models/deadline.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/deadline_repository.dart';
import '../../repositories/analytics_repository.dart';
import '../../core/services/risk_engine.dart';

class AiDataResolver {
  final TaskRepository _taskRepository;
  final DeadlineRepository _deadlineRepository;
  final AnalyticsRepository _analyticsRepository;

  AiDataResolver(this._taskRepository, this._deadlineRepository, this._analyticsRepository);

  Future<AiMessage> resolve(AiIntent intent, String userId, String semesterId) async {
    switch (intent.type) {
      case AiIntentType.getTasksByTimeRange:
        return await _resolveTasks(intent, userId, semesterId, completed: false);
      case AiIntentType.getCompletedTasks:
        return await _resolveTasks(intent, userId, semesterId, completed: true);
      case AiIntentType.getUpcomingDeadlines:
        return await _resolveDeadlines(intent, userId, semesterId);
      case AiIntentType.getStudySummary:
        return await _resolveStudySummary(userId, semesterId);
      case AiIntentType.getProgress:
        return await _resolveProgress(userId, semesterId);
      case AiIntentType.getRiskStatus:
        return await _resolveRiskStatus(userId, semesterId);
      default:
        // Fallback to text message for unhandled intents (to be handled by Edge Function)
        return AiMessage(
          text: "I understand you want to ${intent.type.name}, but I'm still learning how to fetch that specific data.",
          isUser: false,
          semesterId: semesterId,
        );
    }
  }

  Future<AiMessage> _resolveTasks(AiIntent intent, String userId, String semesterId, {required bool completed}) async {
    final tasks = await _taskRepository.getTasks(userId: userId, semesterId: semesterId);
    
    // Filter by completion
    var filtered = tasks.where((t) => t.isCompleted == completed).toList();
    
    // Filter by time range
    if (intent.filter.timeRange != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      filtered = filtered.where((t) {
        if (t.deadline == null) return false;
        final date = DateTime(t.deadline!.year, t.deadline!.month, t.deadline!.day);
        
        switch (intent.filter.timeRange!) {
          case TimeRange.today:
            return date.isAtSameMomentAs(today);
          case TimeRange.thisWeek:
            final endOfWeek = today.add(const Duration(days: 7));
            return date.isAfter(today.subtract(const Duration(days: 1))) && date.isBefore(endOfWeek);
          case TimeRange.lastWeek:
            final startOfLastWeek = today.subtract(const Duration(days: 7));
            return date.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) && date.isBefore(today);
          case TimeRange.lastTwoWeeks:
            final startOfTwoWeeks = today.subtract(const Duration(days: 14));
            return date.isAfter(startOfTwoWeeks.subtract(const Duration(days: 1))) && date.isBefore(today);
          case TimeRange.custom:
            return true;
        }
      }).toList();
    }

    if (filtered.isEmpty) {
      final now = DateTime.now();
      String rangeDetails = "";
      if (intent.filter.timeRange != null) {
        final start = DateTime(now.year, now.month, now.day);
        switch (intent.filter.timeRange!) {
          case TimeRange.today:
            rangeDetails = " (today, ${DateFormat('MMM d').format(start)})";
            break;
          case TimeRange.thisWeek:
            final end = start.add(const Duration(days: 7));
            rangeDetails = " for this week (${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)})";
            break;
          case TimeRange.lastWeek:
            final s = start.subtract(const Duration(days: 7));
            rangeDetails = " for last week (${DateFormat('MMM d').format(s)} - ${DateFormat('MMM d').format(start)})";
            break;
          default:
            rangeDetails = " for the selected period";
        }
      }

      return AiMessage(
        text: "I couldn't find any ${completed ? 'completed ' : ''}tasks$rangeDetails.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln("I found ${filtered.length} ${completed ? 'completed ' : ''}task${filtered.length > 1 ? 's' : ''}:");
    for (var task in filtered) {
      final dateStr = task.deadline != null ? " (${DateFormat('MMM d').format(task.deadline!)})" : "";
      buffer.writeln("• ${task.title}$dateStr");
    }

    final urgent = filtered.where((t) => t.priority == 'high' && !t.isCompleted).toList();
    final pending = filtered.where((t) => t.priority != 'high' && !t.isCompleted).toList();
    final completedList = filtered.where((t) => t.isCompleted).toList();

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'tasks',
      data: {
        'urgent': urgent.map((t) => t.toJson()).toList(),
        'pending': pending.map((t) => t.toJson()).toList(),
        'completed': completedList.map((t) => t.toJson()).toList(),
      },
    );
  }

  Future<AiMessage> _resolveDeadlines(AiIntent intent, String userId, String semesterId) async {
    final deadlines = await _deadlineRepository.getDeadlines(userId: userId, semesterId: semesterId);
    
    // Filter only upcoming
    var filtered = deadlines.where((d) => !d.isCompleted).toList();
    filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (filtered.isEmpty) {
      return AiMessage(
        text: "No upcoming deadlines found in the system.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln("You have ${filtered.length} upcoming deadline${filtered.length > 1 ? 's' : ''}:");
    for (var deadline in filtered) {
      final dateStr = DateFormat('MMM d').format(deadline.dueDate);
      buffer.writeln("• ${deadline.title} (Due: $dateStr)");
    }

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'deadlines',
      data: filtered.map((d) => d.toJson()).toList(),
    );
  }

  Future<AiMessage> _resolveStudySummary(String userId, String semesterId) async {
    final data = await _analyticsRepository.getAnalyticsData(userId, semesterId: semesterId);
    
    if (!data.hasData) {
      return AiMessage(
        text: "Insufficient study data available for the current semester to generate a summary.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln("Here is your study summary for this semester:");
    buffer.writeln("• Completion Rate: ${(data.taskCompletionRate * 100).toStringAsFixed(1)}%");
    buffer.writeln("• Weekly Average: ${data.weeklyAverageStudyHours.toStringAsFixed(1)}h / week");
    buffer.writeln("• GPA: ${data.averageGPA.toStringAsFixed(2)}");
    buffer.writeln("• Total ECTS: ${data.totalECTS}");

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary',
      data: {
        'total': data.totalTasks,
        'completed': data.completedTasks,
        'hours': data.weeklyAverageStudyHours.toStringAsFixed(1),
        'gpa': data.averageGPA.toStringAsFixed(2),
        'ects': data.totalECTS,
      },
    );
  }

  Future<AiMessage> _resolveProgress(String userId, String semesterId) async {
    final data = await _analyticsRepository.getAnalyticsData(userId, semesterId: semesterId);
    
    final buffer = StringBuffer();
    if (data.averageGPA > 0) {
      buffer.writeln("Current GPA: ${data.averageGPA.toStringAsFixed(2)}");
    } else {
      buffer.writeln("GPA: No grade data available yet.");
    }
    
    buffer.writeln("\nTask Progress:");
    buffer.writeln("• ${data.completedTasks} tasks completed out of ${data.totalTasks} total.");

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary', // Reusing summary view for progress stats
      data: {
        'total': data.totalTasks,
        'completed': data.completedTasks,
        'hours': data.weeklyAverageStudyHours.toStringAsFixed(1),
        'gpa': data.averageGPA.toStringAsFixed(2),
        'ects': data.totalECTS,
      },
    );
  }

  Future<AiMessage> _resolveRiskStatus(String userId, String semesterId) async {
    final data = await _analyticsRepository.getAnalyticsData(userId, semesterId: semesterId);
    
    // Explicitly re-calculate to ensure AI output matches the core engine exactly
    final riskResult = RiskEngine.calculate(
      overdueTasks: data.overdueTasks,
      dueSoonTasks: data.dueSoonTasks,
      studyDeficitHours: data.studyDeficit,
      stressLevel: data.avgStress,
      consistency: data.consistency,
      hasStressData: data.hasStressData,
    );

    String level;
    if (riskResult.score < 30) {
      level = "LOW";
    } else if (riskResult.score < 60) {
      level = "MODERATE";
    } else {
      level = "HIGH";
    }

    final buffer = StringBuffer();
    buffer.writeln("Academic Risk Assessment: $level");
    buffer.writeln("Calculated Score: ${riskResult.score.toStringAsFixed(1)}/100");
    if (riskResult.reasons.isNotEmpty) {
      buffer.writeln("\nRisk Factors Identified:");
      for (final reason in riskResult.reasons) {
        buffer.writeln("• $reason");
      }
    }

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'recommendation',
      data: {
        'title': 'Academic Risk Analysis',
        'message': buffer.toString(),
        'score': riskResult.score,
        'level': level,
        'breakdown': riskResult.breakdown,
      },
    );
  }
}
