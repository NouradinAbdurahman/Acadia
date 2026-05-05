import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../models/ai_intent.dart';
import '../../models/ai_message.dart';
import '../../models/analytics_data.dart';
import '../../domain/adaptive/adaptive_profile.dart';
import '../../domain/risk/risk_state.dart';
import '../../domain/decision/decision_rules.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/deadline_repository.dart';
import 'academic_insight_layer.dart';

class AiDataResolver {
  final TaskRepository _taskRepository;
  final DeadlineRepository _deadlineRepository;

  AiDataResolver(this._taskRepository, this._deadlineRepository);

  /// Single insight brain for chat: full [AcademicInsightInput] whenever analytics exists.
  AcademicInsightInput? _unifiedInsightInput(
    AnalyticsData? analytics,
    RiskState? risk,
  ) {
    if (analytics == null || !analytics.hasData) return null;
    final effectiveRisk = risk != null && risk.hasData
        ? risk.result.totalScore
        : analytics.riskScore;
    return AcademicInsightInput.fromAnalytics(
      data: analytics,
      // Single source of truth across Home/Analytics/Chat: riskProvider snapshot.
      riskScoreOverride: effectiveRisk,
      riskTrendDelta: risk != null && risk.hasData ? risk.trendDelta : null,
    );
  }

  /// Chat appendix: unified layer whenever [analytics.hasData], else task-list fallbacks.
  String _appendixForTasksIntent({
    required AnalyticsData? analytics,
    required RiskState? risk,
    required bool? completedTasksView,
    required int urgentCount,
    required int pendingCount,
  }) {
    final unified = _unifiedInsightInput(analytics, risk);
    if (analytics != null && analytics.hasData && unified != null) {
      return unified.buildAppendix();
    }
    if (completedTasksView == true) {
      return '\n\nInsight:\nShowing completed items only.\n\nRecommendation:\nUse this list to review what you have already shipped this semester.\n';
    }
    return buildTaskListInsightAppendix(
      urgentCount: urgentCount,
      pendingCount: pendingCount,
    );
  }

  Future<AiMessage> resolve(
    AiIntent intent,
    String userId,
    String semesterId, {
    AnalyticsData? analyticsSnapshot,
    RiskState? riskSnapshot,
    AdaptiveProfile? adaptiveProfileSnapshot,
    double? burnoutRiskSnapshot,
  }) async {
    switch (intent.type) {
      case AiIntentType.planWeek:
        return await _resolveWeeklyPlan(
          userId,
          semesterId,
          analyticsSnapshot,
        );
      case AiIntentType.planToday:
        return await _resolvePlanToday(
          userId,
          semesterId,
          analyticsSnapshot,
          adaptiveProfileSnapshot ?? const AdaptiveProfile.defaults(),
          burnoutRiskSnapshot ?? 0,
        );
      case AiIntentType.rankTasks:
        return await _resolveTaskRanking(userId, semesterId);
      case AiIntentType.focusNow:
        return await _resolveFocusNow(
          userId,
          semesterId,
          analyticsSnapshot,
          riskSnapshot,
          adaptiveProfileSnapshot ?? const AdaptiveProfile.defaults(),
          burnoutRiskSnapshot ?? 0,
        );
      case AiIntentType.getTasksByTimeRange:
        return await _resolveTasks(
          intent,
          userId,
          semesterId,
          completed: intent.filter.isCompleted,
          analyticsSnapshot: analyticsSnapshot,
          riskSnapshot: riskSnapshot,
        );
      case AiIntentType.getCompletedTasks:
        return await _resolveTasks(
          intent,
          userId,
          semesterId,
          completed: true,
          analyticsSnapshot: analyticsSnapshot,
          riskSnapshot: riskSnapshot,
        );
      case AiIntentType.getUpcomingDeadlines:
        return await _resolveDeadlines(
          intent,
          userId,
          semesterId,
          analyticsSnapshot: analyticsSnapshot,
          riskSnapshot: riskSnapshot,
        );
      case AiIntentType.getStudySummary:
        return _resolveStudySummary(
          semesterId,
          analyticsSnapshot,
          riskSnapshot,
          adaptiveProfileSnapshot ?? const AdaptiveProfile.defaults(),
          burnoutRiskSnapshot ?? 0,
        );
      case AiIntentType.getProgress:
        return _resolveProgress(
          semesterId,
          analyticsSnapshot,
          riskSnapshot,
          adaptiveProfileSnapshot ?? const AdaptiveProfile.defaults(),
          burnoutRiskSnapshot ?? 0,
        );
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

  Future<AiMessage> _resolveTaskRanking(String userId, String semesterId) async {
    final candidates = await _buildRankingCandidates(
      userId: userId,
      semesterId: semesterId,
    );

    if (candidates.isEmpty) {
      return AiMessage(
        text: "You have no pending tasks. You're fully on track.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final now = DateTime.now();
    final scored = candidates.map((candidate) {
      final score = _taskPriorityScore(candidate, now);
      return {'task': candidate, 'score': score};
    }).toList();

    scored.sort((a, b) {
      final byScore = (b['score'] as double).compareTo(a['score'] as double);
      if (byScore != 0) return byScore;
      final taskA = a['task'] as Map<String, dynamic>;
      final taskB = b['task'] as Map<String, dynamic>;
      final aDeadline = taskA['deadline'] as DateTime?;
      final bDeadline = taskB['deadline'] as DateTime?;
      if (aDeadline != null && bDeadline != null) {
        final byDeadline = aDeadline.compareTo(bDeadline);
        if (byDeadline != 0) return byDeadline;
      }
      if (aDeadline != null && bDeadline == null) return -1;
      if (aDeadline == null && bDeadline != null) return 1;
      return (taskA['title'] as String).toLowerCase().compareTo(
            (taskB['title'] as String).toLowerCase(),
          );
    });

    final topTasks = scored.take(3).toList();
    final buffer = StringBuffer();
    buffer.writeln("Here are your top priorities:");
    for (int i = 0; i < topTasks.length; i++) {
      final task = topTasks[i]['task'] as Map<String, dynamic>;
      final score = topTasks[i]['score'] as double;
      final deadline = task['deadline'] as DateTime?;
      final dueSegment = deadline != null
          ? " - due ${DateFormat('MMM d').format(deadline)}"
          : "";
      buffer.writeln(
        "${i + 1}. ${task['title']}$dueSegment (Score: ${score.round()})",
      );
    }
    final firstTask = topTasks.first['task'] as Map<String, dynamic>;
    buffer.writeln(
      "Start with ${firstTask['title']}. One 45 min session.",
    );

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'task_ranking',
      data: {
        'type': 'task_ranking',
        'topTasks': topTasks
            .map((entry) => {
                  'task': entry['task'],
                  'score': (entry['score'] as double).round(),
                })
            .toList(),
      },
    );
  }

  Future<AiMessage> _resolveFocusNow(
    String userId,
    String semesterId,
    AnalyticsData? analytics,
    RiskState? risk,
    AdaptiveProfile adaptiveProfile,
    double burnoutRisk,
  ) async {
    final candidates = await _buildRankingCandidates(
      userId: userId,
      semesterId: semesterId,
    );
    final now = DateTime.now();
    final scored = candidates.map((candidate) {
      final score = _taskPriorityScore(candidate, now);
      return {'task': candidate, 'score': score};
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final avgSessionStress = analytics?.avgSessionStress ?? 0.0;
    final consistency = analytics?.consistency ?? 1.0;
    final duration = DecisionRules.getFinalRecommendedMinutes(
      consistency: consistency,
      stress: avgSessionStress,
      profile: adaptiveProfile,
      burnoutRisk: burnoutRisk,
    );
    final riskScore =
        risk != null && risk.hasData ? risk.result.totalScore : (analytics?.riskScore ?? 0.0);

    if (scored.isEmpty) {
      final durationReasons = _buildDurationReasons(
        consistency: consistency,
        avgSessionStress: avgSessionStress,
        adaptiveProfile: adaptiveProfile,
      );
      final buffer = StringBuffer();
      buffer.writeln("Focus session ready:");
      buffer.writeln("Task: General study session");
      buffer.writeln("Duration: $duration minutes");
      buffer.writeln("No tasks available. Start a general study session.");
      buffer.writeln("Goal:");
      buffer.writeln("- Complete key review or main section");
      if (riskScore > 30) {
        buffer.writeln("You are falling behind. This session matters.");
      }
      buffer.writeln("Start now and stay focused. No distractions.");
      return AiMessage(
        text: buffer.toString(),
        isUser: false,
        semesterId: semesterId,
        type: 'focus_session',
        data: {
          'type': 'focus_session',
          'taskId': null,
          'taskTitle': 'General study session',
          'duration': duration,
          'reasons': {
            'task': ['No pending tasks available'],
            'duration': durationReasons,
          },
        },
      );
    }

    final topTask = scored.first['task'] as Map<String, dynamic>;
    final taskTitle = topTask['title'] as String? ?? 'General study session';
    final taskReasons = _buildTaskReasons(topTask, now);
    final durationReasons = _buildDurationReasons(
      consistency: consistency,
      avgSessionStress: avgSessionStress,
      adaptiveProfile: adaptiveProfile,
    );

    final buffer = StringBuffer();
    buffer.writeln("Focus session ready:");
    buffer.writeln("Task: $taskTitle");
    buffer.writeln("Duration: $duration minutes");
    buffer.writeln("Goal:");
    buffer.writeln("- Complete key review or main section");
    if (riskScore > 30) {
      buffer.writeln("You are falling behind. This session matters.");
    }
    buffer.writeln("Start now and stay focused. No distractions.");

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'focus_session',
      data: {
        'type': 'focus_session',
        'taskId': topTask['id'],
        'taskTitle': taskTitle,
        'duration': duration,
        'courseId': topTask['courseId'],
        'source': topTask['source'],
        'reasons': {
          'task': taskReasons,
          'duration': durationReasons,
        },
      },
    );
  }

  List<String> _buildTaskReasons(
    Map<String, dynamic> task,
    DateTime now,
  ) {
    final reasons = <String>[];
    final deadline = task['deadline'] as DateTime?;
    if (deadline != null) {
      final daysLeft = deadline.difference(now).inDays;
      if (deadline.isBefore(now)) {
        reasons.add('Overdue task');
      } else if (daysLeft <= 0) {
        reasons.add('Due today');
      } else if (daysLeft == 1) {
        reasons.add('Due tomorrow');
      } else {
        reasons.add('Due in $daysLeft days');
      }
    }
    reasons.add('Highest priority among your tasks');
    return reasons;
  }

  List<String> _buildDurationReasons({
    required double consistency,
    required double avgSessionStress,
    required AdaptiveProfile adaptiveProfile,
  }) {
    final adaptive = <String>[];
    if (adaptiveProfile.avgCompletionRatio < 0.7) {
      adaptive.add('You often stop before the planned duration');
    } else if (adaptiveProfile.avgCompletionRatio < 0.9) {
      adaptive.add('You usually finish most of the planned duration');
    }
    if (adaptiveProfile.completionRate < 0.6) {
      adaptive.add('Your session completion rate is low');
    }
    if (adaptiveProfile.completionRate > 0.85 &&
        adaptiveProfile.avgCompletionRatio > 0.9) {
      adaptive.add('You usually finish sessions');
    }
    if (adaptive.isNotEmpty) return adaptive;

    if (consistency < 0.5) {
      return [
        'Your consistency is low this week (${(consistency * 100).round()}%)',
      ];
    }
    if (avgSessionStress >= 6) {
      return ['Your stress is high, shorter session recommended'];
    }
    return ['You are stable, longer session is effective'];
  }

  Future<AiMessage> _resolvePlanToday(
    String userId,
    String semesterId,
    AnalyticsData? analytics,
    AdaptiveProfile adaptiveProfile,
    double burnoutRisk,
  ) async {
    final candidates = await _buildRankingCandidates(
      userId: userId,
      semesterId: semesterId,
    );
    final now = DateTime.now();
    final scored = candidates.map((candidate) {
      final score = _taskPriorityScore(candidate, now);
      return {'task': candidate, 'score': score};
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final consistency = analytics?.consistency ?? 1.0;
    final avgStress = analytics?.avgSessionStress ?? 0.0;
    final baseMinutes = DecisionRules.getFinalRecommendedMinutes(
      consistency: consistency,
      stress: avgStress,
      profile: adaptiveProfile,
      burnoutRisk: burnoutRisk,
    );

    final hasDueSoon = scored.any((entry) {
      final d = (entry['task'] as Map<String, dynamic>)['deadline'] as DateTime?;
      if (d == null) return false;
      final days = d.difference(now).inDays;
      return days <= 2;
    });

    final filtered = scored.where((entry) => (entry['score'] as double) >= 20).toList();
    final pool = filtered.isNotEmpty ? filtered : scored;
    final selected = pool.take(4).toList();

    if (hasDueSoon && selected.isNotEmpty) {
      final containsDueSoon = selected.any((entry) {
        final d = (entry['task'] as Map<String, dynamic>)['deadline'] as DateTime?;
        if (d == null) return false;
        return d.difference(now).inDays <= 2;
      });
      if (!containsDueSoon) {
        final urgent = scored.firstWhere(
          (entry) {
            final d = (entry['task'] as Map<String, dynamic>)['deadline'] as DateTime?;
            if (d == null) return false;
            return d.difference(now).inDays <= 2;
          },
          orElse: () => selected.first,
        );
        selected[0] = urgent;
      }
    }

    if (selected.isEmpty) {
      return AiMessage(
        text:
            "You have no tasks for today.\nStart a 30-minute general study session.",
        isUser: false,
        semesterId: semesterId,
        type: 'daily_plan_empty',
        data: {
          'type': 'daily_plan_empty',
          'duration': 30,
        },
      );
    }

    const slots = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final sessions = <Map<String, dynamic>>[];
    var totalMinutes = 0;
    for (int i = 0; i < selected.length; i++) {
      final task = selected[i]['task'] as Map<String, dynamic>;
      final baseDuration = i == 0 || i == 1
          ? baseMinutes
          : i == 2
              ? math.min(baseMinutes, 25)
              : 25;
      final duration = _applyTaskDurationModifiers(
        baseDuration: baseDuration,
        task: task,
        now: now,
      );
      if (totalMinutes + duration > 150) break;
      totalMinutes += duration;
      sessions.add({
        'taskId': task['id'],
        'title': task['title'],
        'duration': duration,
        'slot': slots[i],
        'courseId': task['courseId'],
        'source': task['source'],
        'reasons': _buildTaskReasons(task, now),
      });
    }

    if ((analytics?.studyDeficit ?? 0) > 10 && sessions.length < 2) {
      final remainingSlot = sessions.length < slots.length ? slots[sessions.length] : 'Later';
      final duration = sessions.length == 0 ? baseMinutes : math.min(baseMinutes, 25);
      if (totalMinutes + duration <= 150) {
        sessions.add({
          'taskId': null,
          'title': 'Deficit recovery block',
          'duration': duration,
          'slot': remainingSlot,
          'courseId': null,
          'source': 'deficit',
          'reasons': ['High study deficit requires extra recovery today'],
        });
      }
    }

    if (sessions.isEmpty) {
      sessions.add({
        'taskId': null,
        'title': 'General study session',
        'duration': 30,
        'slot': 'Morning',
        'courseId': null,
        'source': 'general',
        'reasons': ['No high-priority tasks found for today'],
      });
    }

    final buffer = StringBuffer();
    buffer.writeln("Your plan for today:");
    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      buffer.writeln(
        "${i + 1}. ${s['title']} — ${s['duration']} min (${s['slot']})",
      );
    }
    buffer.writeln("Start with the first session now.");

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'daily_plan',
      data: {
        'type': 'daily_plan',
        'sessions': sessions,
      },
    );
  }

  int _applyTaskDurationModifiers({
    required int baseDuration,
    required Map<String, dynamic> task,
    required DateTime now,
  }) {
    var duration = baseDuration;
    final deadline = task['deadline'] as DateTime?;
    final priority = (task['priority'] as String?)?.toLowerCase() ?? '';
    if (deadline != null) {
      final daysLeft = deadline.difference(now).inDays;
      if (daysLeft <= 0) duration += 2;
      if (daysLeft > 3) duration -= 3;
    } else {
      duration -= 3;
    }
    if (priority == 'high') duration += 2;
    return duration.clamp(20, 60);
  }

  Future<List<Map<String, dynamic>>> _buildRankingCandidates({
    required String userId,
    required String semesterId,
  }) async {
    final tasks = await _taskRepository.getTasks(
      userId: userId,
      semesterId: semesterId,
    );
    final deadlines = await _deadlineRepository.getDeadlines(
      userId: userId,
      semesterId: semesterId,
    );
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final linkedDeadlineIds =
        pendingTasks.map((t) => t.deadlineId).whereType<String>().toSet();

    final pendingTaskCandidates = pendingTasks
        .map((task) => <String, dynamic>{
              'id': task.id,
              'title': task.title,
              'deadline': task.deadline,
              'priority': task.priority,
              'estimatedTime': task.estimatedTime,
              'courseId': task.courseId,
              'source': 'task',
            })
        .toList();
    final deadlineCandidates = deadlines
        .where((d) => !d.isCompleted && !linkedDeadlineIds.contains(d.id))
        .map((d) => <String, dynamic>{
              'id': d.id,
              'title': d.title,
              'deadline': d.dueDate,
              'priority': 'high',
              'estimatedTime': null,
              'courseId': d.courseId,
              'source': 'deadline',
            })
        .toList();
    return [...pendingTaskCandidates, ...deadlineCandidates];
  }

  double _taskPriorityScore(Map<String, dynamic> task, DateTime now) {
    double score = 0;
    final deadline = task['deadline'] as DateTime?;
    final priority = task['priority'] as String?;
    final estimatedTime = task['estimatedTime'] as int?;

    if (deadline != null) {
      final daysLeft = deadline.difference(now).inDays;
      final urgencyScore = math.max(0.0, 40 - (daysLeft * 3.0));
      score += urgencyScore;
    }

    if (deadline != null && deadline.isBefore(now)) {
      score += 30;
    }

    switch (priority?.toLowerCase()) {
      case 'high':
        score += 20;
        break;
      case 'medium':
        score += 10;
        break;
      default:
        score += 5;
    }

    if (estimatedTime != null) {
      final estimatedHours = estimatedTime / 60.0;
      if (estimatedHours > 3) score += 10;
    }

    return score.clamp(0, 100).toDouble();
  }

  Future<AiMessage> _resolveWeeklyPlan(
    String userId,
    String semesterId,
    AnalyticsData? analytics,
  ) async {
    if (analytics == null || !analytics.hasData) {
      return AiMessage(
        text:
            "I need more study data for this semester before I can build your weekly plan.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final deficit = analytics.studyDeficit; // hours
    final goal = analytics.studyGoal; // hours
    final completed = analytics.studyHours; // this week hours
    final overdueTasks = analytics.overdueTasks;
    final dueSoonTasks = analytics.dueSoonTasks;

    final allDeadlines = await _deadlineRepository.getDeadlines(
      userId: userId,
      semesterId: semesterId,
    );
    final allTasks = await _taskRepository.getTasks(
      userId: userId,
      semesterId: semesterId,
    );
    final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 7));
    final upcoming = allDeadlines
        .where((d) =>
            !d.isCompleted &&
            !d.deadlineDate.isBefore(today) &&
            d.deadlineDate.isBefore(end))
        .toList()
      ..sort((a, b) => a.deadlineDate.compareTo(b.deadlineDate));

    const sessionMinutes = 45;
    final sessionsNeeded = (deficit / 0.75).ceil();
    var sessions = sessionsNeeded.clamp(1, 14);
    final taskCount = pendingTasks.length;
    if (taskCount <= 2) {
      sessions = math.min(sessions, 6);
    }

    final days = [
      'Today',
      'Tomorrow',
      'Day 3',
      'Day 4',
      'Day 5',
      'Day 6',
      'Day 7',
    ];
    final sessionsPerDay = _distributeSessions(sessions);
    final urgencyBoostCount = (dueSoonTasks > 0 ? 1 : 0) + (overdueTasks > 0 ? 1 : 0);
    final hasUrgencyBoost = urgencyBoostCount > 0;
    if (hasUrgencyBoost) {
      _applyUrgencyBoostToToday(sessionsPerDay, urgencyBoostCount);
    }

    final buffer = StringBuffer();
    buffer.writeln("Here is your weekly plan:\n");
    for (int i = 0; i < days.length; i++) {
      if (sessionsPerDay[i] == 0) continue;
      buffer.writeln("${days[i]}:");
      for (int j = 0; j < sessionsPerDay[i]; j++) {
        buffer.writeln("- $sessionMinutes min focused session");
      }
      if (i == 0 && hasUrgencyBoost) {
        buffer.writeln("- Extra focus today due to urgent workload");
      }
      final priority = _getPriorityForDay(i, upcoming);
      if (priority != null) {
        buffer.writeln("- Priority: $priority");
      }
      buffer.writeln("");
    }
    buffer.writeln("Total sessions needed: $sessions");
    buffer.writeln("Current deficit: ${deficit.toStringAsFixed(1)}h");

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'weekly_plan',
      data: {
        'type': 'weekly_plan',
        'sessions': sessions,
        'deficit': deficit,
        'goal': goal,
        'completed': completed,
        'sessionsPerDay': sessionsPerDay,
        'upcomingCount': upcoming.length,
        'pendingTasks': taskCount,
        'overdueTasks': overdueTasks,
        'dueSoonTasks': dueSoonTasks,
      },
    );
  }

  List<int> _distributeSessions(int total) {
    final days = List<int>.filled(7, 0);
    var remaining = total;
    var i = 0;
    while (remaining > 0) {
      days[i % 7]++;
      remaining--;
      i++;
    }
    return days;
  }

  void _applyUrgencyBoostToToday(List<int> sessionsPerDay, int boostCount) {
    if (sessionsPerDay.isEmpty) return;
    final totalSessions = sessionsPerDay.fold<int>(0, (sum, n) => sum + n);
    final transferable = totalSessions - sessionsPerDay[0];
    final appliedBoost = math.min(boostCount, transferable);
    if (appliedBoost <= 0) return;

    sessionsPerDay[0] += appliedBoost;
    var remainingToShift = appliedBoost;
    for (int i = sessionsPerDay.length - 1; i >= 1 && remainingToShift > 0; i--) {
      if (sessionsPerDay[i] > 0) {
        sessionsPerDay[i] -= 1;
        remainingToShift--;
      }
    }
  }

  String? _getPriorityForDay(int dayIndex, List<dynamic> deadlines) {
    if (deadlines.isEmpty) return null;
    if (dayIndex > 2) return null;
    final index = dayIndex % deadlines.length;
    final d = deadlines[index];
    final due = DateFormat('MMM d').format(d.deadlineDate as DateTime);
    return "${d.title} (due $due)";
  }

  Future<AiMessage> _resolveTasks(
    AiIntent intent,
    String userId,
    String semesterId, {
    required bool? completed,
    AnalyticsData? analyticsSnapshot,
    RiskState? riskSnapshot,
  }) async {
    final tasks = await _taskRepository.getTasks(userId: userId, semesterId: semesterId);
    
    // 1) Filter by completion (tri-state):
    //    true => completed only, false => incomplete only, null => all tasks.
    var filtered = completed == null
        ? tasks
        : tasks.where((t) => t.isCompleted == completed).toList();

    // 2) Apply date filter with completion-aware date fields.
    //    - completed queries: completedAt/updatedAt first, then deadline fallback
    //    - incomplete queries: deadline first, then createdAt fallback
    if (intent.filter.timeRange != null || intent.filter.startDate != null) {
      filtered = filtered.where((t) {
        return _taskMatchesDateFilter(t, intent.filter, completedView: completed);
      }).toList();
    }

    if (filtered.isEmpty) {
      // Fallback: many users track work via academic_deadlines instead of tasks.
      final deadlines = await _deadlineRepository.getDeadlines(
        userId: userId,
        semesterId: semesterId,
      );
      var fallback = completed == null
          ? deadlines
          : deadlines.where((d) => d.isCompleted == completed).toList();
      if (intent.filter.timeRange != null || intent.filter.startDate != null) {
        fallback = fallback.where((d) {
          return _deadlineMatchesDateFilter(
            d.deadlineDate,
            d.completedAt,
            intent.filter,
            completedView: completed,
          );
        }).toList();
      }

      if (fallback.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
          completed == true
              ? "You have no completed tasks in your task list for this semester.\n"
                  "Here are ${fallback.length} completed item${fallback.length > 1 ? 's' : ''} from your academic deadlines:"
              : "You have no active tasks in your task list for this semester.\n"
                  "However, you have ${fallback.length} upcoming deadline${fallback.length > 1 ? 's' : ''}:",
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

        final unified = _unifiedInsightInput(analyticsSnapshot, riskSnapshot);
        final appendix = _appendixForTasksIntent(
          analytics: analyticsSnapshot,
          risk: riskSnapshot,
          completedTasksView: completed,
          urgentCount: urgent.length,
          pendingCount: pending.length,
        );
        buffer.write(appendix);

        final parts = unified?.parts;
        return AiMessage(
          text: buffer.toString(),
          isUser: false,
          semesterId: semesterId,
          type: 'tasks',
          data: {
            'urgent': completed == true ? <Map<String, dynamic>>[] : urgent,
            'pending': completed == true ? <Map<String, dynamic>>[] : pending,
            'completed': completed == true ? completedList : <Map<String, dynamic>>[],
            if (parts != null) 'insight': parts.insight,
            if (parts != null) 'recommendation': parts.recommendation,
          },
        );
      }

      final rangeDetails = _formatRangeDetails(intent.filter);

      return AiMessage(
        text:
            "For this semester, I couldn't find any ${completed == true ? 'completed ' : ''}tasks$rangeDetails.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(
      "This semester, I found ${filtered.length} ${completed == true ? 'completed ' : ''}task${filtered.length > 1 ? 's' : ''}${intent.filter.timeRange != null || intent.filter.startDate != null ? ' matching your filters' : ''}:",
    );
    for (var task in filtered) {
      final dateStr = _taskDisplayDate(task, completedView: completed);
      buffer.writeln("• ${task.title}$dateStr");
    }

    final urgent = filtered.where((t) => t.priority == 'high' && !t.isCompleted).toList();
    final pending = filtered.where((t) => t.priority != 'high' && !t.isCompleted).toList();
    final completedList = filtered.where((t) => t.isCompleted).toList();

    final unified = _unifiedInsightInput(analyticsSnapshot, riskSnapshot);
    final appendix = _appendixForTasksIntent(
      analytics: analyticsSnapshot,
      risk: riskSnapshot,
      completedTasksView: completed,
      urgentCount: urgent.length,
      pendingCount: pending.length,
    );
    buffer.write(appendix);

    final parts = unified?.parts;
    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'tasks',
      data: {
        'urgent': urgent.map((t) => t.toJson()).toList(),
        'pending': pending.map((t) => t.toJson()).toList(),
        'completed': completedList.map((t) => t.toJson()).toList(),
        if (parts != null) 'insight': parts.insight,
        if (parts != null) 'recommendation': parts.recommendation,
      },
    );
  }

  bool _deadlineMatchesDateFilter(
    DateTime deadlineDate,
    DateTime? completedAt,
    AiFilter filter, {
    required bool? completedView,
  }) {
    // Strict context-aware matching:
    // - completed query => completion timestamp only
    // - incomplete query => due date only
    final candidateDates = completedView == true
        ? <DateTime?>[completedAt]
        : completedView == false
            ? <DateTime?>[deadlineDate]
            : <DateTime?>[deadlineDate, completedAt];
    for (final d in candidateDates) {
      if (d == null) continue;
      final normalized = DateTime(d.year, d.month, d.day);
      if (_isDateInFilter(normalized, filter)) return true;
    }
    return false;
  }

  bool _taskMatchesDateFilter(
    dynamic task,
    AiFilter filter, {
    required bool? completedView,
  }) {
    // Strict context-aware matching:
    // - completed query => completedAt only
    // - incomplete query => deadline, else createdAt
    final candidateDates = completedView == true
        ? <DateTime?>[
            task.completedAt as DateTime?,
          ]
        : completedView == false
            ? <DateTime?>[
                task.deadline as DateTime?,
                task.createdAt as DateTime?,
              ]
            : <DateTime?>[
                task.deadline as DateTime?,
                task.createdAt as DateTime?,
                task.completedAt as DateTime?,
                task.updatedAt as DateTime?,
              ];

    for (final d in candidateDates) {
      if (d == null) continue;
      final normalized = DateTime(d.year, d.month, d.day);
      if (_isDateInFilter(normalized, filter)) return true;
    }
    return false;
  }

  String _taskDisplayDate(dynamic task, {required bool? completedView}) {
    DateTime? d;
    if (completedView == true) {
      d = (task.completedAt as DateTime?) ??
          (task.updatedAt as DateTime?) ??
          (task.deadline as DateTime?);
    } else if (completedView == false) {
      d = (task.deadline as DateTime?) ?? (task.createdAt as DateTime?);
    } else {
      d = (task.deadline as DateTime?) ??
          (task.createdAt as DateTime?) ??
          (task.completedAt as DateTime?) ??
          (task.updatedAt as DateTime?);
    }
    return d != null ? " (${DateFormat('MMM d').format(d)})" : "";
  }

  Future<AiMessage> _resolveDeadlines(
    AiIntent intent,
    String userId,
    String semesterId, {
    AnalyticsData? analyticsSnapshot,
    RiskState? riskSnapshot,
  }) async {
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
        text: "No upcoming deadlines found for this semester.",
        isUser: false,
        semesterId: semesterId,
        type: 'text',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(
      "For this semester, you have ${filtered.length} upcoming deadline${filtered.length > 1 ? 's' : ''}:",
    );
    for (var deadline in filtered) {
      final dateStr = DateFormat('MMM d').format(deadline.dueDate);
      buffer.writeln("• ${deadline.title} (Due: $dateStr)");
    }

    final unified = _unifiedInsightInput(analyticsSnapshot, riskSnapshot);
    final dlInsight = unified != null
        ? unified.buildAppendix()
        : filtered.length >= 6
            ? '\n\nInsight:\nYou have many parallel deadlines in this semester. Competing dates raise context-switch cost.\n\nRecommendation:\nWork backward from each date in calendar order; protect deep-focus blocks for the two hardest items.\n'
            : filtered.length >= 3
                ? '\n\nInsight:\nSeveral deadlines are lined up. Small slips compound.\n\nRecommendation:\nConfirm dates on your calendar and add reminder alerts a few days before each.\n'
                : '\n\nInsight:\nYour upcoming deadlines look manageable in count.\n\nRecommendation:\nStay one session ahead on prep so reviews are not last-minute.\n';
    buffer.write(dlInsight);

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
    AdaptiveProfile adaptiveProfile,
    double burnoutRisk,
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
    buffer.writeln(
      "Here is your current academic summary:",
    );
    buffer.writeln(
      "• This week (by deadline) — task completion rate: ${(data.taskCompletionRate * 100).toStringAsFixed(1)}%",
    );
    buffer.writeln(
      "• This week (study sessions) — hours logged: ${data.studyHours.toStringAsFixed(1)}h",
    );
    buffer.writeln(
      "• This semester (average) — study: ${data.weeklyAverageStudyHours.toStringAsFixed(1)}h / week",
    );
    buffer.writeln(
      "• Weekly study goal: ${data.studyGoal.toStringAsFixed(0)}h / week",
    );
    buffer.writeln(
      "• This semester — GPA: ${data.averageGPA.toStringAsFixed(2)}",
    );
    buffer.writeln("• This semester — total ECTS: ${data.totalECTS}");
    buffer.writeln(
      "• Rolling consistency (last 7 days): ${(data.consistency * 100).toStringAsFixed(0)}%",
    );
    buffer.writeln(
      "• Study deficit (this week vs goal): ${data.studyDeficit.toStringAsFixed(1)}h",
    );
    buffer.writeln(
      "• Due soon (this semester): ${data.dueSoonTasks}",
    );
    if (data.overdueTasks > 0) {
      buffer.writeln("• Overdue (this semester): ${data.overdueTasks}");
    }
    if (data.hasStressData) {
      buffer.writeln(
        "• Session stress (recent logs): ${data.avgSessionStress.toStringAsFixed(1)}",
      );
      buffer.writeln(
        "• Daily stress (recent logs): ${data.avgDailyStress.toStringAsFixed(1)}",
      );
    }

    final effectiveRiskScore = risk != null && risk.hasData
        ? risk.result.totalScore
        : data.riskScore;
    final riskLevel = effectiveRiskScore < 30
        ? "LOW"
        : effectiveRiskScore < 60
            ? "MODERATE"
            : "HIGH";
    buffer.writeln(
      "• Academic risk (snapshot): ${effectiveRiskScore.round()}/100 ($riskLevel)",
    );

    final insightInput = AcademicInsightInput.fromAnalytics(
      data: data,
      riskScoreOverride: effectiveRiskScore,
      riskTrendDelta: (risk != null && risk.hasData) ? risk.trendDelta : null,
      adaptiveProfile: adaptiveProfile,
      burnoutRisk: burnoutRisk,
    );
    final insightParts = insightInput.parts;
    buffer.write(insightInput.buildAppendix());

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary',
      data: {
        'tasks': {
          'calendarWeek': {
            'total': data.totalTasks,
            'completed': data.completedTasks,
          },
        },
        // Legacy keys — same values as tasks.calendarWeek.* (calendar-week deadline scope)
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
        'insight': insightParts.insight,
        'recommendation': insightParts.recommendation,
      },
    );
  }

  AiMessage _resolveProgress(
    String semesterId,
    AnalyticsData? data,
    RiskState? risk,
    AdaptiveProfile adaptiveProfile,
    double burnoutRisk,
  ) {
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
      buffer.writeln(
        "This semester — GPA: ${data.averageGPA.toStringAsFixed(2)}",
      );
    } else {
      buffer.writeln("This semester — GPA: no grade data yet.");
    }

    buffer.writeln("\nTasks — this week (by deadline):");
    buffer.writeln(
      "• ${data.completedTasks} completed out of ${data.totalTasks} tasks that have a deadline in the current calendar week.",
    );
    buffer.writeln(
      "• ${(data.taskCompletionRate * 100).toStringAsFixed(1)}% of those due this week.",
    );
    buffer.writeln("\nStudy — this week (sessions):");
    buffer.writeln(
      "• Hours: ${data.studyHours.toStringAsFixed(1)}h (goal: ${data.studyGoal.toStringAsFixed(0)}h / week)",
    );
    buffer.writeln(
      "• Semester average: ${data.weeklyAverageStudyHours.toStringAsFixed(1)}h / week",
    );
    if (data.studyDeficit > 0) {
      buffer.writeln(
        "• Study deficit (this week vs goal): ${data.studyDeficit.toStringAsFixed(1)}h",
      );
    }

    final effectiveRisk = risk != null && risk.hasData
        ? risk.result.totalScore
        : data.riskScore;
    final progressInsight = AcademicInsightInput.fromAnalytics(
      data: data,
      riskScoreOverride: effectiveRisk,
      riskTrendDelta: risk != null && risk.hasData ? risk.trendDelta : null,
      adaptiveProfile: adaptiveProfile,
      burnoutRisk: burnoutRisk,
    );
    final progressParts = progressInsight.parts;
    buffer.write(progressInsight.buildAppendix());

    return AiMessage(
      text: buffer.toString(),
      isUser: false,
      semesterId: semesterId,
      type: 'summary',
      data: {
        'tasks': {
          'calendarWeek': {
            'total': data.totalTasks,
            'completed': data.completedTasks,
          },
        },
        'total': data.totalTasks,
        'completed': data.completedTasks,
        'hours': data.studyHours.toStringAsFixed(1),
        'weeklyAvg': data.weeklyAverageStudyHours.toStringAsFixed(1),
        'gpa': data.averageGPA.toStringAsFixed(2),
        'ects': data.totalECTS,
        'consistency': data.consistency,
        'riskScore': effectiveRisk,
        'studyGoal': data.studyGoal,
        'insight': progressParts.insight,
        'recommendation': progressParts.recommendation,
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
    buffer.writeln("\nInputs used (risk model):");
    buffer.writeln("• Overdue (this semester): ${input.overdueTasks}");
    buffer.writeln("• Due soon (this semester): ${input.upcomingTasks}");
    buffer.writeln(
      "• Study deficit (this week vs goal): ${input.studyDeficit.toStringAsFixed(1)}h",
    );
    buffer.writeln(
      "• Session stress (recent): ${input.avgSessionStress.toStringAsFixed(1)}",
    );
    buffer.writeln(
      "• Consistency (risk input): ${(input.consistency * 100).toStringAsFixed(0)}%",
    );

    final reasons = <String>[];
    if (input.studyDeficit > 5) {
      reasons.add(
        "Study deficit (this week vs goal) of ${input.studyDeficit.toStringAsFixed(1)}h",
      );
    }
    if (input.overdueTasks > 0) {
      reasons.add(
        "${input.overdueTasks} overdue task${input.overdueTasks > 1 ? 's' : ''} (this semester)",
      );
    }
    if (input.avgSessionStress >= 6) {
      reasons.add(
        "Elevated session stress (${input.avgSessionStress.toStringAsFixed(1)})",
      );
    }
    if (input.consistency < 0.5) {
      reasons.add("Low consistency score used in risk");
    }

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

    final riskInsight = AcademicInsightInput.fromRiskOnly(
      risk: input,
      riskScore0to100: score,
      riskTrendDelta: risk.trendDelta,
    );
    final riskParts = riskInsight.parts;
    buffer.write(riskInsight.buildAppendix());

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
        'insight': riskParts.insight,
        'recommendation': riskParts.recommendation,
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
