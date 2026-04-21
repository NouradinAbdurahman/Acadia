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
    required List<MoodLog> moods,
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

    final avgMood = sessionMoods.isNotEmpty 
        ? sessionMoods.reduce((a, b) => a + b) / sessionMoods.length 
        : analytics.avgMood;
    final avgStress = sessionStresses.isNotEmpty 
        ? sessionStresses.reduce((a, b) => a + b) / sessionStresses.length 
        : analytics.avgStress;

    final moodDataPoints = sessionMoods.length + moods.length;
    final now = DateTime.now();
    final hour = now.hour;

    // --- RANKED EXPLANATION LOGIC ---
    final reasonWeights = <Map<String, dynamic>>[];
    
    // Calculate deviations from baseline
    final stressDeviation = avgStress - baselineStress;
    final moodDeviation = baselineMood - avgMood; // positive if mood is LOWER than baseline

    if (stressDeviation >= 1.5) {
      reasonWeights.add({'key': 'signalStressHigh', 'impact': 3, 'value': avgStress});
    } else if (stressDeviation >= 0.8) {
      reasonWeights.add({'key': 'signalStressMedium', 'impact': 2, 'value': avgStress});
    }

    if (moodDeviation >= 1.0) {
      reasonWeights.add({'key': 'signalMoodLow', 'impact': 3, 'value': avgMood});
    }
    
    if (consistencyScore < 50) {
      reasonWeights.add({'key': 'signalConsistencyLow', 'impact': 2, 'value': consistencyScore});
    }
    
    if (weeklyDeficitHours > 5) {
      reasonWeights.add({'key': 'signalDeficitHigh', 'impact': 2, 'value': weeklyDeficitHours});
    }

    // Sort by impact desc
    reasonWeights.sort((a, b) => (b['impact'] as int).compareTo(a['impact'] as int));
    final signals = reasonWeights.map((r) => r['key'] as String).toList();

    int? suggestedSessionMinutes;

    // --- ADAPTIVE LOGIC WITH BASELINE ---
    if (stressDeviation >= 1.5) {
      suggestedSessionMinutes = 25;
      items.add(
        const DecisionItem(
          titleKey: 'takeItSlowerTodayTitle',
          descriptionKey: 'takeItSlowerTodayBody',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    } else if (stressDeviation >= 0.8 && consistencyScore < 50) {
      suggestedSessionMinutes = 30;
      items.add(
        const DecisionItem(
          titleKey: 'decisionRisingStressUnstablePattern',
          descriptionKey: 'decisionActionFixedScheduleFocus',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    } else if (moodDeviation >= 1.0) {
      suggestedSessionMinutes = 20;
      items.add(
        const DecisionItem(
          titleKey: 'moodNameBad',
          descriptionKey: 'decisionLightTasksOnly',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    } else if (avgMood >= 3.5 && avgStress < 5) {
      suggestedSessionMinutes = 45;
      items.add(
        const DecisionItem(
          titleKey: 'strongStateTitle',
          descriptionKey: 'strongStateBody',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else {
      suggestedSessionMinutes = 35;
    }

    // ADAPTIVE: React to behavioral success rate
    if (successRate < 0.6 && suggestedSessionMinutes != null) {
      suggestedSessionMinutes = suggestedSessionMinutes! - 5;
    } else if (successRate > 0.9 && suggestedSessionMinutes != null && suggestedSessionMinutes! < 45) {
       suggestedSessionMinutes = suggestedSessionMinutes! + 5;
    }

    // 2) Burnout Guard
    if (burnoutScore >= 65) {
      suggestedSessionMinutes = (suggestedSessionMinutes ?? 25).clamp(20, 25);
      items.add(
        const DecisionItem(
          titleKey: 'highRisk',
          descriptionKey: 'decisionBurnoutDurationCap',
          type: DecisionType.warning,
          priority: 1,
        ),
      );
    }

    // Emotional Status Key matching (Fix: Use absolute stress for final labels as requested)
    final String statusKey = avgStress >= 7.0
        ? 'decisionStatusHighStress'
        : (avgStress >= 5.0 ? 'decisionStatusModerateStress' : 'decisionStatusLowStress');

    // 3) Trend detection
    if (moodDataPoints >= 5 && DecisionInsights.isStressTrendIncreasing(moods)) {
      items.add(
        const DecisionItem(
          titleKey: 'stressTrends',
          descriptionKey: 'burnoutMessageEmotionalRisk',
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }
    if (moodDataPoints >= 5 && DecisionInsights.isMoodTrendDeclining(moods)) {
      items.add(
        const DecisionItem(
          titleKey: 'moodTrends',
          descriptionKey: 'predictionLevelHigh', 
          type: DecisionType.insight,
          priority: 2,
        ),
      );
    }

    // 4) Deadline + stress combo
    final today = DateTime(now.year, now.month, now.day);
    final hasUpcomingDeadline = deadlines.any((d) {
      if (d.isCompleted) return false;
      final due = DateTime(d.deadlineDate.year, d.deadlineDate.month, d.deadlineDate.day);
      final days = due.difference(today).inDays;
      return days >= 0 && days <= 7;
    });

    if (stressDeviation >= 1.0 && hasUpcomingDeadline) {
      items.add(
        const DecisionItem(
          titleKey: 'upcomingDeadlines',
          descriptionKey: 'takeItSlowerTodayBody',
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
          titleKey: 'decisionWorstDay',
          descriptionKey: 'decisionLightTasksOnly',
          params: {'day': worstDay},
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
          titleKey: 'decisionMainFactor',
          descriptionKey: 'decisionActionBreakDown',
          params: {'factor': factor},
          type: DecisionType.insight,
          priority: 4,
        ),
      );
    }

    // 7) Consistency check
    final lowStudy = analytics.weeklyAverageStudyHours < 1.5;
    if (lowStudy && stressDeviation >= 1.5) {
      items.add(
        const DecisionItem(
          titleKey: 'decisionLowActivityHighStress',
          descriptionKey: 'decisionActionShortSessions',
          type: DecisionType.warning,
          priority: 2,
        ),
      );
    }

    if (consistencyScore < 40) {
      items.add(
        const DecisionItem(
          titleKey: 'decisionFixedSchedule',
          descriptionKey: 'decisionActionFixedSchedule',
          type: DecisionType.recommendation,
          priority: 2,
        ),
      );
    }

    final explanationKeys = <String>[];
    if (avgStress > 7) {
      explanationKeys.add('predictionReasonStressHigh');
    }
    if (consistencyScore < 0.6) {
      explanationKeys.add('predictionReasonLowConsistencyDetail');
    }
    if (tasks.isNotEmpty) {
      explanationKeys.add('predictionReasonTasksPending');
    }
    if (hasUpcomingDeadline) {
      explanationKeys.add('predictionReasonDeadlinesSoon');
    }

    if (avgStress >= 6 && analytics.weeklyAverageStudyHours < 2.0) {
      explanationKeys.add('predictionStressLikelyIncrease');
    }

    // 8) Time-based context
    if (hour >= 6 && hour < 12) {
      items.add(
        const DecisionItem(
          titleKey: 'decisionMorningPlanning',
          descriptionKey: 'decisionActionPlanning',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else if (hour >= 12 && hour < 18) {
      items.add(
        const DecisionItem(
          titleKey: 'decisionAfternoonExecution',
          descriptionKey: 'decisionActionExecution',
          type: DecisionType.recommendation,
          priority: 3,
        ),
      );
    } else if (hour >= 20) {
      items.add(
        const DecisionItem(
          titleKey: 'decisionNightLightReview',
          descriptionKey: 'decisionActionLightReview',
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
      avgMood: avgMood,
      avgStress: avgStress,
      emotionalStatusKey: statusKey,
      signals: signals,
    );
  }

  List<DecisionItem> _unique(List<DecisionItem> values) {
    final seen = <String>{};
    final output = <DecisionItem>[];
    for (final value in values) {
      if (seen.add(value.titleKey)) output.add(value);
    }
    return output;
  }

  double _confidence({
    required int moodDataPoints,
    required int tasksCount,
    required int deadlinesCount,
    required double consistencyScore,
  }) {
    double score = 0;
    if (moodDataPoints >= 4) score += 0.3;
    if (tasksCount >= 2) score += 0.2;
    if (deadlinesCount >= 1) score += 0.2;
    score += (consistencyScore / 100.0) * 0.3;
    return score.clamp(0.0, 1.0);
  }
}
