import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/risk/risk_calculator.dart';
import '../domain/risk/risk_input.dart';
import '../domain/risk/risk_state.dart';
import '../domain/risk/risk_result.dart';

import '../models/course.dart';
import '../models/course_result.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/deadline.dart';

import 'app_providers.dart';
import 'deadlines_provider.dart';
import 'study_sessions_provider.dart';
import 'tasks_provider.dart';

final riskProvider = FutureProvider<RiskState>((ref) async {
  // 1. Get user from currentAppUserProvider (ensuring it's fully synchronized with profile)
  final user = await ref.watch(currentAppUserProvider.future);

  if (user == null) {
    // Return empty state if user is somehow logged out
    return RiskState(
      input: const RiskInput(
        overdueTasks: 0,
        upcomingTasks: 0,
        totalECTS: 0,
        studyHours: 0,
        studyGoal: 10.0,
      ),
      result: const RiskResult(
        totalScore: 0,
        riskLevel: 'low',
        overdueContribution: 0,
        upcomingContribution: 0,
        ectsContribution: 0,
        studyContribution: 0,
      ),
      trendDelta: 0,
    );
  }

  // Recompute when local lists change (mutations, pull-to-refresh, debounced realtime).
  ref.watch(tasksProvider);
  ref.watch(deadlinesProvider);
  ref.watch(studySessionsProvider);

  // Connect study goal to Database exactly as requested
  final studyGoal = (user.weeklyStudyGoal ?? 10).toDouble();

  // 2. Load dependencies via repos (sole source of truth reading DB)
  final courseRepo = ref.watch(courseRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final studyRepo = ref.watch(studyRepositoryProvider);
  final semesterRepo = ref.watch(semesterRepositoryProvider);
  final courseResultRepo = ref.watch(courseResultRepositoryProvider);
  final deadlineRepo = ref.watch(deadlineRepositoryProvider);

  // Fetch from Database
  final coursesFut = courseRepo.getCourses(); // ECTS
  final tasksFut = taskRepo.getTasks(user.id); // Upcoming + Overdue Tasks
  final sessionsFut = studyRepo.getSessions(user.id); // Study Hours
  final deadlinesFut = deadlineRepo.getDeadlines(
    user.id,
  ); // Deadline completion signal

  final results = await Future.wait([
    coursesFut,
    tasksFut,
    sessionsFut,
    deadlinesFut,
  ]);

  final courses = results[0] as List<Course>;
  final tasks = results[1] as List<Task>;
  final sessions = results[2] as List<StudySession>;
  final deadlines = results[3] as List<Deadline>;

  final semesters = await semesterRepo.getSemesters();
  String? currentSemesterId;
  for (final semester in semesters) {
    if (semester.isCurrent) {
      currentSemesterId = semester.id;
      break;
    }
  }
  if (currentSemesterId == null && semesters.isNotEmpty) {
    currentSemesterId = semesters.first.id;
  }

  final courseResults = currentSemesterId == null
      ? const <CourseResult>[]
      : await courseResultRepo.getResultsBySemester(
          userId: user.id,
          semesterId: currentSemesterId,
        );

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final in3Days = startOfToday.add(const Duration(days: 3));

  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final fourteenDaysAgo = sevenDaysAgo.subtract(const Duration(days: 7));

  // 3. ECTS Source Calculation
  final totalEcts = courses.fold<int>(0, (sum, c) => sum + c.ects);

  // 4. Overdue & Upcoming tasks mapping
  int currentOverdue = 0;
  int currentUpcoming = 0;

  for (final t in tasks) {
    if (t.status == 'completed') continue;

    // overdue = due_date < now && not completed
    final pastDeadline =
        t.deadline != null && t.deadline!.isBefore(startOfToday);
    if (t.status == 'overdue' || pastDeadline) {
      currentOverdue++;
    }
    // upcoming = due_date within next 3 days
    else if (t.deadline != null &&
        t.deadline!.isAfter(now) &&
        t.deadline!.isBefore(in3Days)) {
      currentUpcoming++;
    }
  }

  // 5. Study Hours Calculation via Study Sessions Table (SQL logic implementation)
  int currentDbMinutes = 0;
  int previousDbMinutes = 0;

  for (final s in sessions) {
    if (s.createdAt.isAfter(sevenDaysAgo)) {
      currentDbMinutes += s.durationMinutes;
    } else if (s.createdAt.isAfter(fourteenDaysAgo) &&
        s.createdAt.isBefore(sevenDaysAgo)) {
      previousDbMinutes += s.durationMinutes;
    }
  }

  final currentStudyHours = currentDbMinutes / 60.0;
  final previousStudyHours = previousDbMinutes / 60.0;
  final gradeRiskAdjustment =
      _gradeAdjustment(courseResults) +
      _completedDeadlineAdjustment(deadlines) +
      _overdueDeadlinesPenalty(deadlines, startOfToday) +
      _linkedTaskCompletionRelief(tasks, deadlines);

  // 6. Provide Data to Core Engine
  final currentInput = RiskInput(
    overdueTasks: currentOverdue,
    upcomingTasks: currentUpcoming,
    totalECTS: totalEcts,
    studyHours: currentStudyHours,
    studyGoal: studyGoal, // Sourced precisely from DB
    gradeRiskAdjustment: gradeRiskAdjustment,
  );

  final previousInput = RiskInput(
    overdueTasks: currentOverdue, // Fallback for pure trend tracking
    upcomingTasks: currentUpcoming, // Fallback for pure trend tracking
    totalECTS: totalEcts,
    studyHours: previousStudyHours,
    studyGoal: studyGoal,
    gradeRiskAdjustment: gradeRiskAdjustment,
  );

  final currentResult = RiskCalculator.calculate(currentInput);
  final previousResult = RiskCalculator.calculate(previousInput);

  final trendDelta = user.createdAt.isAfter(sevenDaysAgo)
      ? null
      : (currentResult.totalScore - previousResult.totalScore).toInt();

  return RiskState(
    input: currentInput,
    result: currentResult,
    trendDelta: trendDelta,
  );
});

double _gradeAdjustment(List<CourseResult> results) {
  double score = 0;

  for (final result in results) {
    final code = result.letterGrade.trim().toUpperCase().split(' ').first;
    if (code == 'FF' || code == 'DD' || code == 'DC') {
      score += 10;
      continue;
    }
    if (code == 'CC' || code == 'CB' || code == 'BB') {
      score += 5;
      continue;
    }
    if (code == 'BA' || code == 'AA') {
      score -= 5;
      continue;
    }
    // Ignored codes: EX, S, P, W, I, NA and others.
  }

  return score;
}

double _completedDeadlineAdjustment(List<Deadline> deadlines) {
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final completedRecently = deadlines.where((deadline) {
    if (!deadline.isCompleted) return false;
    final at = deadline.completedAt;
    return at != null && at.isAfter(sevenDaysAgo);
  }).length;

  // Reward handled deadlines without overpowering task/study risk signals.
  return -(completedRecently.clamp(0, 3) * 2).toDouble();
}

/// Academic targets past due and not marked handled increase pressure.
double _overdueDeadlinesPenalty(
  List<Deadline> deadlines,
  DateTime startOfToday,
) {
  var overdue = 0;
  for (final d in deadlines) {
    if (d.isCompleted) continue;
    final due = DateTime(
      d.deadlineDate.year,
      d.deadlineDate.month,
      d.deadlineDate.day,
    );
    if (due.isBefore(startOfToday)) overdue++;
  }
  return (overdue.clamp(0, 4) * 12.0);
}

/// Completing work linked to open deadlines slightly offsets risk.
double _linkedTaskCompletionRelief(List<Task> tasks, List<Deadline> deadlines) {
  final openIds = deadlines
      .where((d) => !d.isCompleted)
      .map((d) => d.id)
      .toSet();
  if (openIds.isEmpty) return 0.0;

  var linked = 0;
  var done = 0;
  for (final t in tasks) {
    final id = t.deadlineId;
    if (id == null || !openIds.contains(id)) continue;
    linked++;
    if (t.status == 'completed') done++;
  }
  if (linked == 0) return 0.0;
  final rate = done / linked;
  if (rate >= 0.6) return -5.0;
  return 0.0;
}
