import '../models/analytics_data.dart';
import '../services/supabase/analytics_service.dart';

class AnalyticsRepository {
  final AnalyticsService _analyticsService;

  AnalyticsRepository(this._analyticsService);

  Future<AnalyticsData> getAnalyticsData(
    String userId, {
    String? semesterId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      final startOfRollingWeek = startOfToday.subtract(const Duration(days: 6));

      final sessions = await _analyticsService.getStudySessions(
        userId,
        startOfRollingWeek,
      );
      final tasks = await _analyticsService.getTasks(userId);
      final results = semesterId == null
          ? const <Map<String, dynamic>>[]
          : await _analyticsService.getCourseResults(
              userId: userId,
              semesterId: semesterId,
            );

      // Study Hours Aggregation
      Map<String, double> hoursPerCourse = {};
      for (final s in sessions) {
        final courseId = s['course_id'];
        if (courseId == null) continue;

        final minutes = s['duration_minutes'] ?? 0;
        final double hoursValue = (minutes / 60.0).clamp(0.05, 100.0);

        hoursPerCourse[courseId] = (hoursPerCourse[courseId] ?? 0) + hoursValue;
      }

      // Task Calculation Logic (Standardized)
      // Master set: tasks that are DUES this week
      final weeklyTasks = tasks.where((t) {
        final deadlineStr = t['deadline'];
        if (deadlineStr == null) return false;

        final dueDate = DateTime.tryParse(deadlineStr);
        if (dueDate == null) return false;

        final taskDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return !taskDay.isBefore(startOfWeek) && taskDay.isBefore(endOfWeek);
      }).toList();

      final total = weeklyTasks.length;
      final completed = weeklyTasks.where((t) {
        final status =
            t['status'] ??
            (t['is_completed'] == true ? 'completed' : 'pending');
        return status == 'completed';
      }).length;

      final rate = total == 0 ? 0.0 : completed / total.toDouble();

      final gradeDistribution = <String, int>{};
      for (final result in results) {
        final rawGrade = (result['letter_grade'] as String? ?? '')
            .trim()
            .toUpperCase();
        if (rawGrade.isEmpty) continue;
        final code = rawGrade.split(' ').first;
        gradeDistribution.update(code, (value) => value + 1, ifAbsent: () => 1);
      }

      return AnalyticsData(
        studyHoursPerCourse: hoursPerCourse,
        gradeDistribution: gradeDistribution,
        taskCompletionRate: rate,
        completedTasks:
            completed, // Represents completions FROM this week's goals
        totalTasks: total,
      );
    } catch (_) {
      rethrow;
    }
  }
}
