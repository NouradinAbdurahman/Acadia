import 'package:intl/intl.dart';
import '../../models/ai_intent.dart';
import '../../models/ai_message.dart';
import '../../models/analytics_data.dart';
import '../../domain/risk/risk_state.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/deadline_repository.dart';

class AiDataResolver {
  final TaskRepository _taskRepository;
  final DeadlineRepository _deadlineRepository;

  AiDataResolver(this._taskRepository, this._deadlineRepository);

  Future<AiMessage> resolve(
    AiIntent intent,
    String userId,
    String semesterId, {
    AnalyticsData? analyticsSnapshot,
    RiskState? riskSnapshot,
  }) async {
    switch (intent.type) {
      case AiIntentType.getTasksByTimeRange:
        return await _resolveTasks(intent, userId, semesterId, completed: false);
      case AiIntentType.getCompletedTasks:
        return await _resolveTasks(intent, userId, semesterId, completed: true);
      case AiIntentType.getUpcomingDeadlines:
        return await _resolveDeadlines(intent, userId, semesterId);
      case AiIntentType.getStudySummary:
        return _resolveStudySummary(semesterId, analyticsSnapshot, riskSnapshot);
      case AiIntentType.getProgress:
        return _resolveProgress(semesterId, analyticsSnapshot);
      case AiIntentType.getRiskStatus:
        return _resolveRiskStatus(semesterId, riskSnapshot);
      default:
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
    if (intent.filter.timeRange != null || intent.filter.startDate != null) {
      filtered = filtered.where((t) {
        if (t.deadline == null) return false;
        return _isDateInFilter(
          DateTime(t.deadline!.year, t.deadline!.month, t.deadline!.day),
          intent.filter,
        );
      }).toList();
    }

    if (filtered.isEmpty) {
      // Fallback: many users track work via academic_deadlines instead of tasks.
      final deadlines = await _deadlineRepository.getDeadlines(
        userId: userId,
        semesterId: semesterId,
      );
      var fallback = deadlines.where((d) => d.isCompleted == completed).toList();
      if (intent.filter.timeRange != null || intent.filter.startDate != null) {
        fallback = fallback.where((d) {
          final date = DateTime(
            d.deadlineDate.year,
            d.deadlineDate.month,
            d.deadlineDate.day,
          );
          return _isDateInFilter(date, intent.filter);
        }).toList();
      }

      if (fallback.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
          "I couldn't find ${completed ? 'completed ' : ''}items in your task list, "
          "but I found ${fallback.length} ${completed ? 'completed ' : ''}item${fallback.length > 1 ? 's' : ''} from your deadlines:",
        );
        for (final d in fallback) {
          buffer.writeln(
            "• ${d.title} (${DateFormat('MMM d').format(d.deadlineDate)})",
          );
        }

        final mapped = fallback
            .map((d) => {
                  'id': d.id,
                  'title': d.title,
                  'deadline': d.deadlineDate.toIso8601String(),
                  'priority': d.priority,
                  'status': d.isCompleted ? 'completed' : 'pending',
                  'course': d.course,
                  'notes': d.notes,
                  'source': 'deadline',
                })
            .toList();
        final urgent = mapped.where((d) => d['priority'] == 'high').toList();
        final pending = mapped.where((d) => d['priority'] != 'high').toList();
        final completedList =
            mapped.where((d) => d['status'] == 'completed').toList();

        return AiMessage(
          text: buffer.toString(),
          isUser: false,
          semesterId: semesterId,
          type: 'tasks',
          data: {
            'urgent': completed ? <Map<String, dynamic>>[] : urgent,
            'pending': completed ? <Map<String, dynamic>>[] : pending,
            'completed': completed ? completedList : <Map<String, dynamic>>[],
          },
        );
      }

      final rangeDetails = _formatRangeDetails(intent.filter);

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
    if (intent.filter.timeRange != null || intent.filter.startDate != null) {
      filtered = filtered
          .where((d) => _isDateInFilter(
                DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day),
                intent.filter,
              ))
          .toList();
    }
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

  AiMessage _resolveStudySummary(
    String semesterId,
    AnalyticsData? data,
    RiskState? risk,
  ) {
    if (data == null || !data.hasData) {
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
    buffer.writeln("• This Week: ${data.studyHours.toStringAsFixed(1)}h studied");
    buffer.writeln("• Weekly Average: ${data.weeklyAverageStudyHours.toStringAsFixed(1)}h / week");
    buffer.writeln("• Study Goal: ${data.studyGoal.toStringAsFixed(0)}h / week");
    buffer.writeln("• GPA: ${data.averageGPA.toStringAsFixed(2)}");
    buffer.writeln("• Total ECTS: ${data.totalECTS}");
    buffer.writeln("• Consistency: ${(data.consistency * 100).toStringAsFixed(0)}%");
    buffer.writeln("• Study Deficit: ${data.studyDeficit.toStringAsFixed(1)}h");
    buffer.writeln("• Due Soon: ${data.dueSoonTasks}");
    if (data.overdueTasks > 0) {
      buffer.writeln("• Overdue Tasks: ${data.overdueTasks}");
    }
    if (data.hasStressData) {
      buffer.writeln("• Session Stress: ${data.avgSessionStress.toStringAsFixed(1)}");
      buffer.writeln("• Daily Stress: ${data.avgDailyStress.toStringAsFixed(1)}");
    }

    if (risk != null && risk.hasData) {
      final riskScore = risk.result.totalScore;
      final riskLevel = riskScore < 30
          ? "LOW"
          : riskScore < 60
              ? "MODERATE"
              : "HIGH";
      buffer.writeln("• Academic Risk: ${riskScore.toStringAsFixed(1)}/100 ($riskLevel)");
    } else {
      buffer.writeln("• Academic Risk: ${data.riskScore.toStringAsFixed(1)}/100");
    }

    final effectiveRiskScore = risk != null && risk.hasData
        ? risk.result.totalScore
        : data.riskScore;

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary',
      data: {
        'total': data.totalTasks,
        'completed': data.completedTasks,
        'hours': data.studyHours.toStringAsFixed(1),
        'weeklyAvg': data.weeklyAverageStudyHours.toStringAsFixed(1),
        'gpa': data.averageGPA.toStringAsFixed(2),
        'ects': data.totalECTS,
        'consistency': data.consistency,
        'riskScore': effectiveRiskScore,
        'riskLevel': risk?.result.riskLevel,
        'riskOverdueContribution': risk?.result.overdueContribution,
        'riskUpcomingContribution': risk?.result.upcomingContribution,
        'riskDeficitContribution': risk?.result.studyContribution,
        'riskStressContribution': risk?.result.sessionStressContribution,
        'riskConsistencyContribution': risk?.result.consistencyContribution,
        'studyGoal': data.studyGoal,
        'studyDeficit': data.studyDeficit,
        'avgSessionStress': data.avgSessionStress,
        'avgDailyStress': data.avgDailyStress,
        'overdue': data.overdueTasks,
        'dueSoon': data.dueSoonTasks,
        'consistencyPct': (data.consistency * 100).toStringAsFixed(0),
        'weeklyCompletionPct': (data.taskCompletionRate * 100).toStringAsFixed(1),
      },
    );
  }

  AiMessage _resolveProgress(String semesterId, AnalyticsData? data) {
    if (data == null) {
      return AiMessage(
        text: "No analytics data available yet. Start studying and logging tasks to see progress.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    if (data.averageGPA > 0) {
      buffer.writeln("Current GPA: ${data.averageGPA.toStringAsFixed(2)}");
    } else {
      buffer.writeln("GPA: No grade data available yet.");
    }
    
    buffer.writeln("\nTask Progress:");
    buffer.writeln("• ${data.completedTasks} tasks completed out of ${data.totalTasks} total.");
    buffer.writeln("• Completion Rate: ${(data.taskCompletionRate * 100).toStringAsFixed(1)}%");
    buffer.writeln("\nStudy Progress:");
    buffer.writeln("• This Week: ${data.studyHours.toStringAsFixed(1)}h (Goal: ${data.studyGoal.toStringAsFixed(0)}h)");
    buffer.writeln("• Weekly Average: ${data.weeklyAverageStudyHours.toStringAsFixed(1)}h");
    if (data.studyDeficit > 0) {
      buffer.writeln("• Deficit: ${data.studyDeficit.toStringAsFixed(1)}h behind goal");
    }

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary',
      data: {
        'total': data.totalTasks,
        'completed': data.completedTasks,
        'hours': data.studyHours.toStringAsFixed(1),
        'weeklyAvg': data.weeklyAverageStudyHours.toStringAsFixed(1),
        'gpa': data.averageGPA.toStringAsFixed(2),
        'ects': data.totalECTS,
        'consistency': data.consistency,
        'riskScore': data.riskScore,
        'studyGoal': data.studyGoal,
      },
    );
  }

  AiMessage _resolveRiskStatus(String semesterId, RiskState? risk) {
    if (risk == null || !risk.hasData) {
      return AiMessage(
        text: "No data available to assess risk. Keep using the app to build your academic profile.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final score = risk.result.totalScore;
    final input = risk.input;

    String level;
    if (score < 30) {
      level = "LOW";
    } else if (score < 60) {
      level = "MODERATE";
    } else {
      level = "HIGH";
    }

    final buffer = StringBuffer();
    buffer.writeln("Academic Risk Assessment: $level");
    buffer.writeln("Calculated Score: ${score.toStringAsFixed(1)}/100");
    buffer.writeln("\nInputs used:");
    buffer.writeln("• Overdue Tasks: ${input.overdueTasks}");
    buffer.writeln("• Due Soon: ${input.upcomingTasks}");
    buffer.writeln("• Study Deficit: ${input.studyDeficit.toStringAsFixed(1)}h");
    buffer.writeln("• Session Stress: ${input.avgSessionStress.toStringAsFixed(1)}");
    buffer.writeln("• Task Completion: ${(input.consistency * 100).toStringAsFixed(0)}%");

    final reasons = <String>[];
    if (input.studyDeficit > 5) reasons.add("Study deficit of ${input.studyDeficit.toStringAsFixed(1)}h");
    if (input.overdueTasks > 0) reasons.add("${input.overdueTasks} overdue task${input.overdueTasks > 1 ? 's' : ''}");
    if (input.avgSessionStress >= 6) reasons.add("Elevated session stress (${input.avgSessionStress.toStringAsFixed(1)})");
    if (input.consistency < 0.5) reasons.add("Low task completion rate");

    if (reasons.isNotEmpty) {
      buffer.writeln("\nRisk Factors Identified:");
      for (final reason in reasons) {
        buffer.writeln("• $reason");
      }
    }

    if (risk.trendDelta != null) {
      final trendLabel = risk.trendDelta! > 0
          ? "+${risk.trendDelta} (worsening)"
          : risk.trendDelta! < 0
              ? "${risk.trendDelta} (improving)"
              : "No change";
      buffer.writeln("\nTrend: $trendLabel");
    }

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'recommendation',
      data: {
        'title': 'Academic Risk Analysis',
        'message': buffer.toString(),
        'score': score,
        'level': level,
        'breakdown': {
          'overdue': risk.result.overdueContribution,
          'dueSoon': risk.result.upcomingContribution,
          'deficit': risk.result.studyContribution,
          'stress': risk.result.sessionStressContribution,
          'consistency': risk.result.consistencyContribution,
        },
      },
    );
  }

  bool _isDateInFilter(DateTime date, AiFilter filter) {
    if (filter.startDate != null && filter.endDate != null) {
      final start = DateTime(
        filter.startDate!.year,
        filter.startDate!.month,
        filter.startDate!.day,
      );
      final end = DateTime(
        filter.endDate!.year,
        filter.endDate!.month,
        filter.endDate!.day,
      );
      return !date.isBefore(start) && !date.isAfter(end);
    }

    if (filter.timeRange == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (filter.timeRange!) {
      case TimeRange.today:
        return date.isAtSameMomentAs(today);
      case TimeRange.thisWeek:
        final endOfWeek = today.add(const Duration(days: 7));
        return date.isAfter(today.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek);
      case TimeRange.lastWeek:
        final startOfLastWeek = today.subtract(const Duration(days: 7));
        return date.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(today);
      case TimeRange.lastTwoWeeks:
        final startOfTwoWeeks = today.subtract(const Duration(days: 14));
        return date.isAfter(startOfTwoWeeks.subtract(const Duration(days: 1))) &&
            date.isBefore(today);
      case TimeRange.custom:
        return true;
    }
  }

  String _formatRangeDetails(AiFilter filter) {
    if (filter.startDate != null && filter.endDate != null) {
      final start = DateFormat('MMM d, y').format(filter.startDate!);
      final end = DateFormat('MMM d, y').format(filter.endDate!);
      return " for $start - $end";
    }
    if (filter.timeRange == null) return "";

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    switch (filter.timeRange!) {
      case TimeRange.today:
        return " (today, ${DateFormat('MMM d').format(start)})";
      case TimeRange.thisWeek:
        final end = start.add(const Duration(days: 7));
        return " for this week (${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)})";
      case TimeRange.lastWeek:
        final s = start.subtract(const Duration(days: 7));
        return " for last week (${DateFormat('MMM d').format(s)} - ${DateFormat('MMM d').format(start)})";
      case TimeRange.lastTwoWeeks:
        return " for the last two weeks";
      case TimeRange.custom:
        return " for the selected period";
    }
  }
}
