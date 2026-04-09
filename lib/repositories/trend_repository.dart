import '../models/trend_data.dart';
import '../services/supabase/trend_service.dart';

class TrendRepository {
  TrendRepository(this._service);

  final TrendService _service;

  Future<TrendData> getTrendData({
    required String userId,
    required int days,
    String? semesterId,
  }) async {
    if (userId.trim().isEmpty || days <= 0) return const TrendData.empty();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final since = startOfToday.subtract(Duration(days: days - 1));

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _service.getStudySessions(userId: userId, since: since, semesterId: semesterId),
      _service.getCompletedTasks(userId: userId, since: since, semesterId: semesterId),
      _service.getCreatedTasks(userId: userId, since: since, semesterId: semesterId),
      _service.getCreatedDeadlines(userId: userId, since: since, semesterId: semesterId),
      _service.getCourseResults(userId: userId, since: since),
    ]);

    final studyRows = results[0];
    final completedTaskRows = results[1];
    final createdTaskRows = results[2];
    final createdDeadlineRows = results[3];
    final gradeRows = results[4];

    final studyTrend = <DateTime, double>{};
    final taskTrend = <DateTime, int>{};
    final workloadTrend = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final day = since.add(Duration(days: i));
      studyTrend[day] = 0;
      taskTrend[day] = 0;
      workloadTrend[day] = 0;
    }

    for (final row in studyRows) {
      final raw = row['created_at']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (!studyTrend.containsKey(day)) continue;
      final minutes = (row['duration_minutes'] as num?)?.toDouble() ?? 0;
      studyTrend[day] = (studyTrend[day] ?? 0) + (minutes / 60.0);
    }

    for (final row in completedTaskRows) {
      final raw = row['updated_at']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (!taskTrend.containsKey(day)) continue;
      taskTrend[day] = (taskTrend[day] ?? 0) + 1;
    }

    for (final row in createdTaskRows) {
      final raw = row['created_at']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (!workloadTrend.containsKey(day)) continue;
      workloadTrend[day] = (workloadTrend[day] ?? 0) + 1;
    }
    for (final row in createdDeadlineRows) {
      final raw = row['created_at']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (!workloadTrend.containsKey(day)) continue;
      workloadTrend[day] = (workloadTrend[day] ?? 0) + 1;
    }

    final gradeTrend = <GradePoint>[];
    for (final row in gradeRows) {
      final rawDate = row['created_at']?.toString();
      final date = rawDate == null ? null : DateTime.tryParse(rawDate);
      if (date == null) continue;
      final letter = (row['letter_grade'] as String? ?? '')
          .trim()
          .toUpperCase();
      final code = letter.isEmpty ? '' : letter.split(' ').first;
      final value = _gradeValue(code);
      if (value == null) continue;
      gradeTrend.add(GradePoint(date: date, value: value));
    }
    gradeTrend.sort((a, b) => a.date.compareTo(b.date));

    final insights = _buildInsights(
      studyTrend: studyTrend,
      workloadTrend: workloadTrend,
      gradeTrend: gradeTrend,
      completedTasksInRange: completedTaskRows.length,
      totalTasksInRange: createdTaskRows.length,
    );

    final studyValues = studyTrend.values.toList();
    final split = (studyValues.length / 2).ceil();
    final studyPrev = studyValues
        .take(split)
        .fold<double>(0, (sum, value) => sum + value);
    final studyLast = studyValues
        .skip(split)
        .fold<double>(0, (sum, value) => sum + value);
    final studyChangePercent = _normalizePercent(
      _safePercentChange(oldValue: studyPrev, newValue: studyLast),
    );

    final workloadValues = workloadTrend.values.toList();
    final workloadPrev = workloadValues
        .take(split)
        .fold<int>(0, (sum, value) => sum + value);
    final workloadLast = workloadValues
        .skip(split)
        .fold<int>(0, (sum, value) => sum + value);
    final workloadChangePercent = _normalizePercent(
      _safePercentChange(
        oldValue: workloadPrev.toDouble(),
        newValue: workloadLast.toDouble(),
      ),
    );

    final taskCompletionRate = createdTaskRows.isEmpty
        ? 0.0
        : (completedTaskRows.length / createdTaskRows.length).clamp(0.0, 1.0);

    double performanceChange = 0;
    if (gradeTrend.length >= 3) {
      final splitGrades = (gradeTrend.length / 2).ceil();
      final firstAvg =
          gradeTrend
              .take(splitGrades)
              .fold<double>(0, (sum, point) => sum + point.value) /
          splitGrades;
      final secondPart = gradeTrend.skip(splitGrades).toList();
      if (secondPart.isNotEmpty) {
        final secondAvg =
            secondPart.fold<double>(0, (sum, point) => sum + point.value) /
            secondPart.length;
        performanceChange = secondAvg - firstAvg;
      }
    }

    return TrendData(
      studyTrend: studyTrend,
      taskTrend: taskTrend,
      workloadTrend: workloadTrend,
      gradeTrend: gradeTrend,
      insights: insights,
      studyChangePercent: studyChangePercent,
      workloadChangePercent: workloadChangePercent,
      taskCompletionRate: taskCompletionRate,
      performanceChange: performanceChange,
    );
  }

  double? _gradeValue(String code) {
    const map = <String, double>{
      'AA': 4.0,
      'BA': 3.5,
      'BB': 3.0,
      'CB': 2.5,
      'CC': 2.0,
      'DC': 1.5,
      'DD': 1.0,
      'FF': 0.0,
    };
    return map[code];
  }

  List<TrendInsight> _buildInsights({
    required Map<DateTime, double> studyTrend,
    required Map<DateTime, int> workloadTrend,
    required List<GradePoint> gradeTrend,
    required int completedTasksInRange,
    required int totalTasksInRange,
  }) {
    final insights = <TrendInsight>[];
    final studyValues = studyTrend.values.toList();
    final workloadValues = workloadTrend.values.toList();
    final split = (studyValues.length / 2).ceil();

    final studyPrev = studyValues
        .take(split)
        .fold<double>(0, (sum, value) => sum + value);
    final studyLast = studyValues
        .skip(split)
        .fold<double>(0, (sum, value) => sum + value);
    final totalStudyHours = studyValues.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final studyChange = _normalizePercent(
      _safePercentChange(oldValue: studyPrev, newValue: studyLast),
    );
    if (totalStudyHours < 1) {
      insights.add(
        const TrendInsight(
          type: InsightType.warning,
          title: 'Build study consistency',
          message:
              'You have just started tracking study sessions. Try to study daily.',
          key: 'study_build_consistency',
        ),
      );
    } else if (studyChange > 10) {
      final title = studyChange > 50
          ? 'Study increased significantly'
          : 'Study improved';
      insights.add(
        TrendInsight(
          type: InsightType.good,
          title: title,
          message:
              'Study increased by ${studyChange.round()}%. Keep this pace to stay ahead.',
          key: 'study_increased',
          params: {'percent': studyChange.round()},
        ),
      );
    } else if (studyChange < -10) {
      insights.add(
        TrendInsight(
          type: InsightType.warning,
          title: 'Study declined',
          message:
              'Study dropped by ${studyChange.abs().round()}%. Consider scheduling extra sessions.',
          key: 'study_declined',
          params: {'percent': studyChange.abs().round()},
        ),
      );
    }

    if (totalTasksInRange == 0) {
      insights.add(
        const TrendInsight(
          type: InsightType.good,
          title: 'No tasks in this period',
          message: 'No tasks were due in this period.',
          key: 'no_tasks',
        ),
      );
    } else {
      final completionRate = (completedTasksInRange / totalTasksInRange).clamp(
        0.0,
        1.0,
      );
      if (completionRate < 0.5) {
        insights.add(
          TrendInsight(
            type: InsightType.warning,
            title: 'Task completion is low',
            message: completedTasksInRange == 0
                ? 'No tasks completed yet. Start completing tasks to track performance.'
                : 'You completed $completedTasksInRange of $totalTasksInRange tasks. Try to complete more next period.',
            key: completedTasksInRange == 0
                ? 'task_completion_low_none'
                : 'task_completion_low_some',
            params: {
              'completed': completedTasksInRange,
              'total': totalTasksInRange,
            },
          ),
        );
      }
    }

    final workloadPrev = workloadValues
        .take(split)
        .fold<int>(0, (sum, value) => sum + value);
    final workloadLast = workloadValues
        .skip(split)
        .fold<int>(0, (sum, value) => sum + value);
    final workloadChange = _normalizePercent(
      _safePercentChange(
        oldValue: workloadPrev.toDouble(),
        newValue: workloadLast.toDouble(),
      ),
    );
    final totalWorkload = workloadValues.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (totalWorkload == 0) {
      insights.add(
        const TrendInsight(
          type: InsightType.good,
          title: 'No new workload',
          message: 'No new tasks or deadlines were added in this period.',
          key: 'no_workload',
        ),
      );
    } else if (workloadChange > 10) {
      final isSharp = workloadChange > 50 && totalWorkload > 5;
      final title = isSharp
          ? 'Workload increased sharply'
          : 'Workload is rising';
      insights.add(
        TrendInsight(
          type: isSharp ? InsightType.critical : InsightType.warning,
          title: title,
          message:
              'You added $totalWorkload tasks/deadlines in this period. Plan ahead to avoid overload.',
          key: 'workload_increased',
          params: {'count': totalWorkload},
        ),
      );
    }

    if (gradeTrend.length >= 3) {
      final splitGrades = (gradeTrend.length / 2).ceil();
      final firstAvg =
          gradeTrend
              .take(splitGrades)
              .fold<double>(0, (sum, point) => sum + point.value) /
          splitGrades;
      final secondPart = gradeTrend.skip(splitGrades).toList();
      if (secondPart.isNotEmpty) {
        final secondAvg =
            secondPart.fold<double>(0, (sum, point) => sum + point.value) /
            secondPart.length;
        if (secondAvg < firstAvg) {
          insights.add(
            const TrendInsight(
              type: InsightType.warning,
              title: 'Performance declining',
              message:
                  'Performance trend is decreasing. Review weak courses this week.',
              key: 'performance_declining',
            ),
          );
        } else if (secondAvg > firstAvg) {
          insights.add(
            const TrendInsight(
              type: InsightType.good,
              title: 'Performance improving',
              message:
                  'Performance trend is improving. Keep the same study consistency.',
              key: 'performance_improving',
            ),
          );
        }
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const TrendInsight(
          type: InsightType.good,
          title: 'Stable trends',
          message: 'No significant change yet. Keep logging consistently.',
          key: 'stable_trends',
        ),
      );
    }
    return insights;
  }

  double _safePercentChange({
    required double oldValue,
    required double newValue,
  }) {
    if (oldValue == 0 && newValue == 0) return 0;
    if (oldValue < 0.5) {
      return newValue > 0 ? 10 : 0;
    }
    return ((newValue - oldValue) / oldValue) * 100;
  }

  double _normalizePercent(double value) {
    return value.clamp(-100, 100).toDouble();
  }
}
