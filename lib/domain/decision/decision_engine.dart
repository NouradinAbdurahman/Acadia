import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/analytics_data.dart';
import '../../models/course.dart';
import '../../models/mood_log.dart';
import '../../models/study_session.dart';
import '../../models/task.dart';
import '../../models/deadline.dart';
import 'decision_result.dart';
import 'decision_insights.dart';
import 'decision_rules.dart';

class DecisionEngine {
  DecisionResult evaluate({
    required AnalyticsData analytics,
    required AppLocalizations l10n,
    required List<MoodLog> dailyMoods,
    required List<MoodLog> sessionMoodLogs,
    required List<Task> tasks,
    required List<Deadline> deadlines,
    required List<StudySession> recentSessions,
    double burnoutScore = 0,
    double consistencyScore = 100,
    double weeklyDeficitHours = 0,
    double baselineStress = 5.0,
    double baselineMood = 3.0,
    double successRate = 1.0,
  }) {
    final items = <DecisionItem>[];

    final last7Sessions = recentSessions.take(7).toList();
    final sessionMoods = last7Sessions.where((s) => s.mood != null).map((s) => s.mood!).toList();
    final sessionStresses = last7Sessions.where((s) => s.stress != null).map((s) => s.stress!).toList();

    final sessionMoodValues = [
      ...sessionMoodLogs.map((log) => log.moodLevel.toDouble()),
      ...sessionMoods,
    ];
    final sessionStressValues = [
      ...sessionMoodLogs.map((log) => log.stressLevel.toDouble()),
      ...sessionStresses,
    ];

    final avgDailyStress = analytics.avgDailyStress;
    final avgSessionStress = analytics.avgSessionStress;
    final isStressRising = analytics.isStressRising;
    final consistency = analytics.consistency;

    final now = DateTime.now();
    final hour = now.hour;
    final moodDataPoints = dailyMoods.length;
    final avgStress = avgDailyStress;

    // Signals for explanation
    final signals = <String>[];
    if (avgDailyStress >= 7.0 || avgSessionStress >= 7.0) {
      signals.add(l10n.signalStressHigh); // "High study stress"
    } else if (avgDailyStress >= 5.0) {
      signals.add(l10n.signalStressMedium);
    }

    if (analytics.studyDeficit > 15) {
      signals.add(l10n.signalDeficitHigh); // "Study deficit"
    }

    if (consistency < 0.5) {
      signals.add(l10n.signalConsistencyLow);
    }

    if (signals.isEmpty) signals.add(l10n.baseline);

    // Stress deviation
    double stressDeviation = 0;
    if (dailyMoods.length > 1) {
      final scores = dailyMoods.map((m) => m.stressLevel.toDouble()).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      final sumSq = scores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b);
      stressDeviation = (sumSq / scores.length);
    }

    int suggestedSessionMinutes = DecisionRules.getRecommendedSessionLength(avgSessionStress);
    final isHighStress = DecisionRules.isHighStress(avgSessionStress);

    // --- UNIFIED SMART DECISION LOGIC (STRICT PRIORITY) ---
    if (isHighStress) {
      // RULE 2: Stress > Deficit Override
      items.add(
        DecisionItem(
          title: l10n.decisionHighStressOverrideTitle,
          description: l10n.decisionHighStressOverrideBody,
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    } else if (analytics.studyDeficit > 10) {
      items.add(
        DecisionItem(
          title: l10n.studyDeficitTitle,
          description: l10n.studyDeficitBody,
          type: DecisionType.warning,
          priority: 2,
        ),
      );
    } else if (consistency < 0.6) {
      items.add(
        DecisionItem(
          title: l10n.decisionLowConsistencyTitle,
          description: l10n.decisionLowConsistencyBody,
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else if (avgDailyStress >= 6.5 && isStressRising) {
      suggestedSessionMinutes = DecisionRules.getRecommendedSessionLength(7.0);
      items.add(
        DecisionItem(
          title: l10n.decisionRisingStressTitle,
          description: l10n.decisionActionLightReview,
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    } else if (analytics.avgDailyMood > 7 && avgDailyStress < 4) {
      items.add(
        DecisionItem(
          title: l10n.strongStateTitle,
          description: l10n.strongStateBody,
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    }

    // 2) Burnout Guard
    if (burnoutScore >= 65) {
      items.add(
        DecisionItem(
          title: l10n.highRisk,
          description: l10n.decisionBurnoutDurationCap,
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    }

    // Emotional Status Label
    final String statusKey = (avgSessionStress >= 7.0 || avgDailyStress >= 7.0)
        ? 'decisionStatusHighStress'
        : (analytics.studyDeficit > 15)
        ? 'decisionStatusDeficit'
        : (consistency < 0.5)
        ? 'decisionStatusInconsistent'
        : 'statusStable';

    // 3) Trend detection (Threshold: 3 sessions)
    final hasEnoughData = recentSessions.length >= 5;
    if (hasEnoughData && DecisionInsights.isStressTrendIncreasing(dailyMoods)) {
      items.add(
        DecisionItem(
          title: l10n.stressTrends,
          description: l10n.burnoutMessageEmotionalRisk,
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }
    if (hasEnoughData && DecisionInsights.isMoodTrendDeclining(dailyMoods)) {
      items.add(
        DecisionItem(
          title: l10n.moodTrends,
          description: l10n.predictionLevelHigh, 
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }

    // 4) Deadline + stress combo
    if (deadlines.any((d) => d.dueDate.difference(now).inDays <= 3)) {
      items.add(
        DecisionItem(
          title: l10n.upcomingDeadlines,
          description: l10n.takeItSlowerTodayBody,
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    }

    // 5) Weekday pattern
    final worstDay = DecisionInsights.worstMoodWeekday(dailyMoods);
    if (worstDay != null) {
      items.add(
        DecisionItem(
          title: l10n.decisionWorstDay(_weekdayName(worstDay, l10n)),
          description: l10n.decisionLightTasksOnly,
          type: DecisionType.insight,
          priority: 3,
        ),
      );
    }

    // 6) Factor analysis
    final factor = DecisionInsights.mostFrequentFactor(dailyMoods);
    if (factor != null) {
      items.add(
        DecisionItem(
          title: l10n.decisionMainFactor(factor),
          description: l10n.decisionActionBreakDown,
          type: DecisionType.insight,
          priority: 3,
        ),
      );
    }

    // 7) Consistency check
    final hasLowActivity = analytics.weeklyAverageStudyHours < 1.5;
    if (hasLowActivity && avgDailyStress > 6) {
      items.add(
        DecisionItem(
          title: l10n.decisionLowActivityHighStress,
          description: l10n.decisionActionShortSessions,
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    }

    // Consistency check - only add if no higher priority warning exists
    final hasPriorityWarning = items.any((item) => item.priority <= 2);
    if (!hasPriorityWarning && consistency < 0.4 && moodDataPoints >= 3) {
      items.add(
        DecisionItem(
          title: l10n.decisionFixedSchedule,
          description: l10n.decisionActionFixedSchedule,
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    }



    // 8) Time-based context
    if (hour < 11) {
      items.add(
        DecisionItem(
          title: l10n.decisionMorningPlanning,
          description: l10n.decisionActionPlanning,
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    } else if (hour >= 11 && hour < 17) {
      items.add(
        DecisionItem(
          title: l10n.decisionAfternoonExecution,
          description: l10n.decisionActionExecution,
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    } else if (hour >= 17) {
      items.add(
        DecisionItem(
          title: l10n.decisionNightLightReview,
          description: l10n.decisionActionLightReview,
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    }

    final uniqueItems = _unique(items);
    final sessionsCount = recentSessions.length;
    final confidence = _confidence(
      moodDataPoints: moodDataPoints,
      sessionsCount: sessionsCount,
      consistency: consistency,
    );

    final filteredItems = sessionsCount < 5
        ? uniqueItems.where((item) => item.priority == 1).toList()
        : uniqueItems;

    // Truth-consistency: if low data, add a "Collecting data" item
    if (sessionsCount < 5) {
      filteredItems.insert(
        0,
        DecisionItem(
          title: l10n.predictionCollectingData,
          description: l10n.predictionCollectingDataDetail,
          type: DecisionType.insight,
          priority: 1,
        ),
      );
    }

    return DecisionResult(
      items: filteredItems,
      suggestedSessionMinutes: suggestedSessionMinutes,
      confidence: confidence,
      avgMood: analytics.avgDailyMood,
      avgStress: analytics.avgDailyStress,
      avgDailyStress: analytics.avgDailyStress,
      avgSessionStress: analytics.avgSessionStress,
      emotionalStatusKey: statusKey,
      signals: signals,
    );
  }

  List<DecisionItem> _unique(List<DecisionItem> values) {
    final seen = <String>{};
    final output = <DecisionItem>[];
    for (final value in values) {
      if (seen.add(value.title)) output.add(value);
    }
    return output;
  }

  double _confidence({
    required int moodDataPoints,
    required int sessionsCount,
    required double consistency,
  }) {
    // Truth-Consistency Calibration
    if (sessionsCount >= 10 && consistency > 0.7) return 0.9; // High
    if (sessionsCount >= 5) return 0.6; // Medium
    return 0.3; // Low
  }

  String _weekdayName(int day, AppLocalizations l10n) {
    switch (day) {
      case 1: return l10n.monday;
      case 2: return l10n.tuesday;
      case 3: return l10n.wednesday;
      case 4: return l10n.thursday;
      case 5: return l10n.friday;
      case 6: return l10n.saturday;
      case 7: return l10n.sunday;
      default: return '';
    }
  }
}
