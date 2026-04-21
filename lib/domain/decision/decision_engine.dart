import '../../models/analytics_data.dart';
import '../../models/deadline.dart';
import '../../models/mood_log.dart';
import '../../models/task.dart';
import 'decision_insights.dart';
import 'decision_result.dart';
import 'decision_rules.dart';

class DecisionEngine {
  DecisionResult evaluate({
    required AnalyticsData analytics,
    required List<MoodLog> moods,
    required List<Task> tasks,
    required List<Deadline> deadlines,
    double burnoutScore = 0,
    double consistencyScore = 100,
  }) {
    final items = <DecisionItem>[];

    final avgStress = analytics.avgStress;
    final avgMood = analytics.avgMood;
    var suggestedSessionMinutes = DecisionRules.suggestedSessionMinutes(avgStress);
    final hour = DateTime.now().hour;
    final moodDataPoints = moods.length;

    // 1) Stress -> Session adaptation
    if (DecisionRules.highStress(avgStress)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_high_stress',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
      items.add(
        const DecisionItem(
          messageKey: 'decision_short_sessions',
          type: DecisionType.recommendation,
          priority: 1,
        ),
      );
    } else if (DecisionRules.lowStress(avgStress)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_deep_work',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    }

    // Burnout guard: cap recommendations when burnout pressure is high.
    if (burnoutScore > 50) {
      suggestedSessionMinutes = suggestedSessionMinutes > 30 ? 30 : suggestedSessionMinutes;
      items.add(
        const DecisionItem(
          messageKey: 'decision_burnout_duration_cap',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    }

    // 2) Mood -> Performance mode
    if (DecisionRules.lowMood(avgMood)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_light_tasks_only',
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
      items.add(
        const DecisionItem(
          messageKey: 'decision_burnout_warning',
          type: DecisionType.warning,
          priority: 2,
        ),
      );
    } else if (DecisionRules.highMood(avgMood)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_deep_work',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    }

    // 3) Trend detection
    if (moodDataPoints >= 5 && DecisionInsights.isStressTrendIncreasing(moods)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_stress_rising',
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }
    if (moodDataPoints >= 5 && DecisionInsights.isMoodTrendDeclining(moods)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_mood_declining',
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }

    // 4) Deadline + stress combo
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasUpcomingDeadline = deadlines.any((d) {
      if (d.isCompleted) return false;
      final due = DateTime(d.deadlineDate.year, d.deadlineDate.month, d.deadlineDate.day);
      final days = due.difference(today).inDays;
      return days >= 0 && days <= 7;
    });

    if (DecisionRules.highStress(avgStress) && hasUpcomingDeadline) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_deadline_pressure',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    }

    // 5) Weekday pattern
    final worstDay = DecisionInsights.worstMoodWeekday(moods);
    if (moodDataPoints >= 5 && worstDay != null) {
      items.add(
        DecisionItem(
          messageKey: 'decision_worst_day|$worstDay',
          type: DecisionType.insight,
          priority: 3,
        ),
      );
    }

    // 6) Factor analysis
    final factor = DecisionInsights.mostFrequentFactor(moods);
    if (moodDataPoints >= 5 && factor != null) {
      items.add(
        DecisionItem(
          messageKey: 'decision_main_factor|$factor',
          type: DecisionType.insight,
          priority: 4,
        ),
      );
    }

    // 7) Consistency check
    final lowStudy = analytics.weeklyAverageStudyHours < 1.5;
    if (lowStudy && DecisionRules.highStress(avgStress)) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_low_activity_high_stress',
          type: DecisionType.warning,
          priority: 2,
        ),
      );
    }

    // Consistency-driven scheduling rule.
    if (consistencyScore < 40) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_fixed_schedule',
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    }

    // 8) Time-based context
    if (hour >= 6 && hour < 12) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_morning_planning',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else if (hour >= 12 && hour < 18) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_afternoon_execution',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else if (hour >= 20) {
      items.add(
        const DecisionItem(
          messageKey: 'decision_night_light_review',
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    }

    final uniqueItems = _unique(items);
    final confidence = _confidence(
      moodDataPoints: moodDataPoints,
      tasksCount: tasks.length,
      deadlinesCount: deadlines.length,
      consistencyScore: consistencyScore,
    );

    final filteredItems = confidence < 0.45
        ? uniqueItems.where((item) => item.priority <= 2).toList()
        : uniqueItems;

    return DecisionResult(
      items: filteredItems,
      suggestedSessionMinutes: suggestedSessionMinutes,
      confidence: confidence,
    );
  }

  List<DecisionItem> _unique(List<DecisionItem> values) {
    final seen = <String>{};
    final output = <DecisionItem>[];
    for (final value in values) {
      if (seen.add(value.messageKey)) output.add(value);
    }
    return output;
  }

  double _confidence({
    required int moodDataPoints,
    required int tasksCount,
    required int deadlinesCount,
    required double consistencyScore,
  }) {
    final moodSignal = (moodDataPoints / 7.0).clamp(0.0, 1.0);
    final workloadSignal = ((tasksCount + deadlinesCount) / 10.0).clamp(0.0, 1.0);
    final consistencySignal = (consistencyScore / 100.0).clamp(0.0, 1.0);
    return (0.5 * moodSignal + 0.25 * workloadSignal + 0.25 * consistencySignal)
        .clamp(0.0, 1.0);
  }
}
