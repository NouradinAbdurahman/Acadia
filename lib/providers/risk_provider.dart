import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/risk/risk_calculator.dart';
import '../domain/risk/risk_input.dart';
import '../domain/risk/risk_state.dart';
import '../domain/risk/risk_result.dart';

import '../models/course.dart';
import '../models/task.dart';
import '../models/study_session.dart';

import 'app_providers.dart';

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

  // Connect study goal to Database exactly as requested
  final studyGoal = (user.weeklyStudyGoal ?? 10).toDouble();

  // 2. Load dependencies via repos (sole source of truth reading DB)
  final courseRepo = ref.watch(courseRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final studyRepo = ref.watch(studyRepositoryProvider);

  // Fetch from Database
  final coursesFut = courseRepo.getCourses(); // ECTS
  final tasksFut = taskRepo.getTasks(user.id); // Upcoming + Overdue Tasks
  final sessionsFut = studyRepo.getSessions(user.id); // Study Hours

  final results = await Future.wait([coursesFut, tasksFut, sessionsFut]);
  
  final courses = results[0] as List<Course>;
  final tasks = results[1] as List<Task>;
  final sessions = results[2] as List<StudySession>;

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
    final pastDeadline = t.deadline != null && t.deadline!.isBefore(startOfToday);
    if (t.status == 'overdue' || pastDeadline) {
      currentOverdue++;
    } 
    // upcoming = due_date within next 3 days
    else if (t.deadline != null && t.deadline!.isAfter(now) && t.deadline!.isBefore(in3Days)) {
      currentUpcoming++;
    }
  }

  // 5. Study Hours Calculation via Study Sessions Table (SQL logic implementation)
  int currentDbMinutes = 0;
  int previousDbMinutes = 0;

  for (final s in sessions) {
    if (s.createdAt.isAfter(sevenDaysAgo)) {
      currentDbMinutes += s.durationMinutes;
    } else if (s.createdAt.isAfter(fourteenDaysAgo) && s.createdAt.isBefore(sevenDaysAgo)) {
      previousDbMinutes += s.durationMinutes;
    }
  }

  final currentStudyHours = currentDbMinutes / 60.0;
  final previousStudyHours = previousDbMinutes / 60.0;

  // 6. Provide Data to Core Engine
  final currentInput = RiskInput(
    overdueTasks: currentOverdue,
    upcomingTasks: currentUpcoming,
    totalECTS: totalEcts,
    studyHours: currentStudyHours,
    studyGoal: studyGoal, // Sourced precisely from DB
  );

  final previousInput = RiskInput(
    overdueTasks: currentOverdue, // Fallback for pure trend tracking
    upcomingTasks: currentUpcoming, // Fallback for pure trend tracking
    totalECTS: totalEcts,
    studyHours: previousStudyHours,
    studyGoal: studyGoal, 
  );

  final currentResult = RiskCalculator.calculate(currentInput);
  final previousResult = RiskCalculator.calculate(previousInput);

  final trendDelta = (currentResult.totalScore - previousResult.totalScore).toInt();

  return RiskState(
    input: currentInput,
    result: currentResult,
    trendDelta: trendDelta,
  );
});
