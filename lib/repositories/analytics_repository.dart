import 'dart:math';
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

      final sessions = await _analyticsService.getStudySessions(
        userId: userId,
        semesterId: semesterId,
      );
      final tasks = await _analyticsService.getTasks(
        userId: userId,
        semesterId: semesterId,
      );
      final results = semesterId == null
          ? const <Map<String, dynamic>>[]
          : await _analyticsService.getCourseResults(
              userId: userId,
              semesterId: semesterId,
            );
      final courses = await _analyticsService.getCourses(semesterId: semesterId);
      final hasData = sessions.isNotEmpty || tasks.isNotEmpty;

      // Study Hours Aggregation
      Map<String, double> hoursPerCourse = {};
      double totalHistoricalHours = 0.0;
      for (final s in sessions) {
        final courseId = s['course_id'];
        if (courseId == null) continue;

        final minutes = s['duration_minutes'] ?? 0;
        final double hoursValue = (minutes / 60.0).clamp(0.0, 100.0);
        
        totalHistoricalHours += hoursValue;
        hoursPerCourse[courseId] = (hoursPerCourse[courseId] ?? 0) + hoursValue;
      }

      // Calculation of "Avg Weekly Hours" for grading-tier normalization
      double weeklyAvg = 0.0;
      if (semesterId != null) {
        final semData = await _analyticsService.getSemester(semesterId);
        if (semData != null) {
          final start = DateTime.tryParse(semData['start_date'] ?? '') ?? DateTime.parse(semData['created_at']);
          final end = DateTime.tryParse(semData['end_date'] ?? '') ?? now;
          
          final weeks = max(1.0, end.difference(start).inDays / 7.0);
          weeklyAvg = totalHistoricalHours / weeks;
        }
      }

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

      // GPA Calculation
      double totalGradePoints = 0.0;
      int gradedCount = 0;
      final gradeDistribution = <String, int>{};
      
      for (final result in results) {
        final rawGrade = (result['letter_grade'] as String? ?? '').trim().toUpperCase();
        if (rawGrade.isEmpty) continue;
        final code = rawGrade.split(' ').first;
        gradeDistribution.update(code, (value) => value + 1, ifAbsent: () => 1);
        
        final val = _gradeToValue(code);
        if (val != null) {
          totalGradePoints += val;
          gradedCount++;
        }
      }

      final averageGPA = gradedCount == 0 ? 0.0 : totalGradePoints / gradedCount;

      // Risk snapshot calculation for historical comparison
      final totalEcts = courses.fold<int>(0, (sum, c) => sum + (c['ects'] as int? ?? 0));
      final overdueTasksCount = tasks.where((t) {
        final status = t['status'] ?? (t['is_completed'] == true ? 'completed' : 'pending');
         if (status == 'completed') return false;
         final deadlineStr = t['deadline'];
         if (deadlineStr == null) return false;
         final dueDate = DateTime.tryParse(deadlineStr);
         return dueDate != null && dueDate.isBefore(startOfToday);
      }).length;
      
      final riskScore = _calculateSnapshotRisk(
        ects: totalEcts,
        overdue: overdueTasksCount,
        weeklyStudy: weeklyAvg,
        gpa: averageGPA,
      );

      return AnalyticsData(
        studyHoursPerCourse: hoursPerCourse,
        gradeDistribution: gradeDistribution,
        taskCompletionRate: rate,
        completedTasks: completed, 
        totalTasks: total,
        averageGPA: averageGPA,
        weeklyAverageStudyHours: weeklyAvg,
        totalECTS: totalEcts,
        riskScore: riskScore,
        hasData: hasData,
      );
    } catch (_) {
      rethrow;
    }
  }

  double _calculateSnapshotRisk({
    required int ects,
    required int overdue,
    required double weeklyStudy,
    required double gpa,
  }) {
    // academic risk formula for semester aggregates
    double score = 0;
    score += (overdue.clamp(0, 5) * 10.0);
    score += (ects > 0 ? (ects / 30.0) * 15.0 : 0);
    
    // low study hours vs common 10h goal
    if (weeklyStudy < 5) {
      score += 20;
    } else if (weeklyStudy < 10) {
      score += 10;
    }
    
    // low gpa penalty
    if (gpa > 0 && gpa < 2.0) {
      score += 25;
    } else if (gpa > 0 && gpa < 3.0) {
      score += 10;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double? _gradeToValue(String code) {
    const map = <String, double>{
      'AA': 4.0, 'BA': 3.5, 'BB': 3.0, 'CB': 2.5,
      'CC': 2.0, 'DC': 1.5, 'DD': 1.0, 'FF': 0.0,
    };
    return map[code];
  }
}
