import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasks_provider.dart';
import 'deadlines_provider.dart';
import 'course_provider.dart';
import 'semester_provider.dart';
import 'study_sessions_provider.dart';
import 'student_profile_provider.dart';
import 'analytics_provider.dart';
import 'app_providers.dart';
import '../models/course.dart';
import '../models/deadline.dart';

class DashboardData {
  final int pendingTasksToday;
  final int overdueTasksCount;
  final List<Deadline> upcomingDeadlines;
  final int studyMinutesToday;
  final int weeklyStudyGoalMinutes;
  final int weeklyStudyCompletedMinutes;
  final List<CourseStats> topCourses;
  final String? focusSuggestion;
  final String? recommendation;
  final String? recommendationTitle;
  final String? recommendationMessage;
  final String? recommendationType; // 'success', 'warning', 'error'
  final int streakCount;
  final String streakMessage;
  final String? productivityInsight;
  final int completedTodayCount;
  final int sessionsTodayCount;
  final int upcomingDeadlinesCount;
  final int workloadAddedTodayCount;

  DashboardData({
    required this.pendingTasksToday,
    required this.overdueTasksCount,
    required this.upcomingDeadlines,
    required this.studyMinutesToday,
    required this.weeklyStudyGoalMinutes,
    required this.weeklyStudyCompletedMinutes,
    required this.topCourses,
    this.focusSuggestion,
    this.recommendation,
    this.recommendationTitle,
    this.recommendationMessage,
    this.recommendationType,
    required this.streakCount,
    required this.streakMessage,
    this.productivityInsight,
    required this.completedTodayCount,
    required this.sessionsTodayCount,
    required this.upcomingDeadlinesCount,
    required this.workloadAddedTodayCount,
  });
}

class CourseStats {
  final Course course;
  final int tasksCount;
  final int deadlinesCount;
  final int studyMinutes;

  CourseStats({
    required this.course,
    required this.tasksCount,
    required this.deadlinesCount,
    required this.studyMinutes,
  });
}

/// Holds the last successfully computed dashboard so the UI never blanks during refresh.
final _lastDashboardData = StateProvider<DashboardData?>((ref) => null);

final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final profileAsync = ref.watch(studentProfileProvider);
  final coursesAsync = ref.watch(courseProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final deadlinesAsync = ref.watch(deadlinesProvider);
  final sessionsAsync = ref.watch(studySessionsProvider);
  final semestersAsync = ref.watch(semesterProvider);

  final isAnyLoading = profileAsync.isLoading ||
      coursesAsync.isLoading ||
      tasksAsync.isLoading ||
      deadlinesAsync.isLoading ||
      sessionsAsync.isLoading ||
      semestersAsync.isLoading;

  if (isAnyLoading) {
    // If we have previous data, show it while refreshing (no blank flash).
    final cached = ref.read(_lastDashboardData);
    if (cached != null) return AsyncValue.data(cached);
    return const AsyncValue.loading();
  }

  if (profileAsync.hasError ||
      coursesAsync.hasError ||
      tasksAsync.hasError ||
      deadlinesAsync.hasError ||
      sessionsAsync.hasError ||
      semestersAsync.hasError) {
    return AsyncValue.error(
      profileAsync.error ??
          coursesAsync.error ??
          tasksAsync.error ??
          deadlinesAsync.error ??
          sessionsAsync.error ??
          semestersAsync.error ??
          'Unknown error',
      StackTrace.current,
    );
  }

  final profile = profileAsync.value;
  final courses = coursesAsync.value ?? [];
  final tasks = tasksAsync.value ?? [];
  final deadlines = deadlinesAsync.value ?? [];
  final pendingDeadlines = deadlines.where((d) => !d.isCompleted).toList();
  final sessions = sessionsAsync.value ?? [];

  if (profile == null) return const AsyncValue.loading();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = startOfToday.add(const Duration(days: 1));

  // 1. Pending Tasks Today
  final pendingTasksToday = tasks
      .where(
        (t) =>
            t.status == 'pending' &&
            t.deadline != null &&
            t.deadline!.isAfter(startOfToday) &&
            t.deadline!.isBefore(endOfToday),
      )
      .length;

  // 2. Upcoming Deadlines
  final upcomingDeadlinesList =
      pendingDeadlines.where((d) => d.deadlineDate.isAfter(now)).toList()
        ..sort((a, b) => a.deadlineDate.compareTo(b.deadlineDate));

  // 2.b Overdue Tasks
  final overdueTasksCount = tasks.where((t) {
    final hasPastDeadline =
        t.deadline != null && t.deadline!.isBefore(startOfToday);
    return t.status == 'overdue' ||
        (t.status != 'completed' && hasPastDeadline);
  }).length;

  // 3. Study Time Today
  final todaySessions = sessions
      .where(
        (s) =>
            s.createdAt.isAfter(startOfToday) &&
            s.createdAt.isBefore(endOfToday),
      )
      .toList();
  final studyMinutesToday = todaySessions.fold(0, (sum, s) => sum + s.durationMinutes);
  final sessionsTodayCount = todaySessions.length;

  // 3.b Tasks Completed Today
  final completedTodayCount = tasks.where((t) {
    if (t.status != 'completed') return false;
    final lastAction = t.updatedAt ?? t.createdAt;
    return lastAction.isAfter(startOfToday) && lastAction.isBefore(endOfToday);
  }).length;

  // 3.c Workload Added Today (tasks + deadlines created today)
  final tasksAddedTodayCount = tasks.where((t) {
    return t.createdAt.isAfter(startOfToday) &&
        t.createdAt.isBefore(endOfToday);
  }).length;
  final deadlinesAddedTodayCount = pendingDeadlines.where((d) {
    return d.createdAt.isAfter(startOfToday) &&
        d.createdAt.isBefore(endOfToday);
  }).length;
  final workloadAddedTodayCount =
      tasksAddedTodayCount + deadlinesAddedTodayCount;

  // 4. Weekly Goal (Source of Truth: Centralized Provider)
  final weeklyStudyGoalHours = ref.watch(weeklyStudyGoalHoursProvider);
  final weeklyStudyGoalMinutes = weeklyStudyGoalHours * 60;

  // Weekly Completed (Approx 7 days back)
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final weeklyStudyCompletedMinutes = sessions
      .where((s) => s.createdAt.isAfter(startOfWeek))
      .fold(0, (sum, s) => sum + s.durationMinutes);

  final activeSemesterId = ref.watch(activeSemesterProvider);

  // 5. Course Stats (filtered by active semester)
  final activeCoursesStats = courses
      .where((c) {
        if (!c.isActive) return false;
        if (activeSemesterId == null) return true;
        return c.semesterId == activeSemesterId;
      })
      .map((c) {
        return CourseStats(
          course: c,
          tasksCount: tasks.where((t) => t.courseId == c.id).length,
          deadlinesCount: pendingDeadlines
              .where((d) => d.courseId == c.id)
              .length,
          studyMinutes: sessions
              .where((s) => s.courseId == c.id)
              .fold(0, (sum, s) => sum + s.durationMinutes),
        );
      })
      .toList();

  // 6. Streak Calculation
  final uniqueDays =
      sessions
          .map(
            (s) =>
                DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day),
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  int streakCount = 0;
  if (uniqueDays.isNotEmpty) {
    final yesterday = startOfToday.subtract(const Duration(days: 1));
    if (!uniqueDays.first.isBefore(yesterday)) {
      streakCount = 1;
      DateTime currentCheck = uniqueDays.first;
      for (int i = 1; i < uniqueDays.length; i++) {
        if (uniqueDays[i] == currentCheck.subtract(const Duration(days: 1))) {
          streakCount++;
          currentCheck = uniqueDays[i];
        } else {
          break;
        }
      }
    }
  }

  String streakMessage = streakCount > 0
      ? '$streakCount day study streak'
      : 'No current streak';

  // 7. Rule-based recommendation engine
  String? recommendation;
  String? recommendationTitle;
  String? recommendationMessage;
  String? recommendationType;
  String? focusSuggestion;

  final deadlinesSoonCount = upcomingDeadlinesList.where((d) {
    final diff = d.deadlineDate.difference(now).inDays;
    return diff >= 0 && diff <= 3;
  }).length;

  if (overdueTasksCount > 0) {
    recommendation = 'overdue_tasks';
    recommendationTitle = 'Overview';
    recommendationMessage = 'There are $overdueTasksCount overdue tasks.';
    recommendationType = 'error';
    focusSuggestion = 'Tasks Status';
  } else if (deadlinesSoonCount > 0) {
    recommendation = 'deadline_soon';
    recommendationTitle = 'Overview';
    recommendationMessage =
        'There are $deadlinesSoonCount deadlines within the next 3 days.';
    recommendationType = 'warning';
    focusSuggestion = 'Deadline Status';
  } else {
    recommendation = 'on_track';
    recommendationTitle = 'Overview';
    recommendationMessage = 'All current tasks are up-to-date.';
    recommendationType = 'success';
    focusSuggestion = 'System Status';
  }

  final dashboardResult = DashboardData(
      pendingTasksToday: pendingTasksToday,
      overdueTasksCount: overdueTasksCount,
      upcomingDeadlines: upcomingDeadlinesList,
      studyMinutesToday: studyMinutesToday,
      weeklyStudyGoalMinutes: weeklyStudyGoalMinutes,
      weeklyStudyCompletedMinutes: weeklyStudyCompletedMinutes,
      topCourses: activeCoursesStats.take(3).toList(),
      focusSuggestion: focusSuggestion,
      recommendation: recommendation,
      recommendationTitle: recommendationTitle,
      recommendationMessage: recommendationMessage,
      recommendationType: recommendationType,
      streakCount: streakCount,
      streakMessage: streakMessage,
      productivityInsight: deadlinesSoonCount > 0
          ? '$deadlinesSoonCount deadlines due soon'
          : profile.preferredStudyTime,
      completedTodayCount: completedTodayCount,
      sessionsTodayCount: sessionsTodayCount,
      upcomingDeadlinesCount: deadlinesSoonCount,
      workloadAddedTodayCount: workloadAddedTodayCount,
    );

  // Cache for next refresh cycle — avoids blank flash on pull-to-refresh.
  Future.microtask(() => ref.read(_lastDashboardData.notifier).state = dashboardResult);

  return AsyncValue.data(dashboardResult);
});
