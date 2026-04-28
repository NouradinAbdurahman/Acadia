import 'app_localizations.dart';

extension LocalizationHelper on AppLocalizations {
  String get(String key, [Map<String, dynamic>? params]) {
    switch (key) {
      case 'predictionPressureLikelyToIncrease':
      case 'prediction_pressure_likely_to_increase':
        return predictionPressureLikelyToIncrease(params?['hours']?.toString() ?? '0.0');
      case 'predictionStressLikelyIncrease':
      case 'prediction_stress_likely_increase':
        return predictionStressLikelyIncrease;
      case 'decisionRisingStressUnstablePattern':
      case 'decision_rising_stress_unstable_pattern':
        return decisionRisingStressUnstablePattern;
      case 'burnoutRisingStressInconsistentPattern':
      case 'burnout_rising_stress_inconsistent_pattern':
        return burnoutRisingStressInconsistentPattern;
      case 'decisionActionFixedScheduleFocus':
        return decisionActionFixedScheduleFocus;
      case 'analyticsNotEnoughData':
        return analyticsNotEnoughData;
      case 'decisionHighStress':
      case 'decisionStatusHighStress':
        return decisionStatusHighStress;
      case 'decisionLowMotivation':
        return moodNameBad;
      case 'decisionHealthyState':
        return strongStateTitle;
      case 'decisionStatusModerateStress':
        return decisionStatusModerateStress;
      case 'decisionStatusLowStress':
        return decisionStatusLowStress;
      case 'decisionShortSessions':
        return decisionShortSessions;
      case 'decisionDeepWork':
        return decisionDeepWork;
      case 'decisionBurnoutWarning':
        return decisionBurnoutWarning;
      case 'decisionStressRising':
        return decisionStressRising;
      case 'decisionMoodDeclining':
        return decisionMoodDeclining;
      case 'decisionDeadlinePressure':
        return decisionDeadlinePressure;
      case 'predictionReasonHighStressToday':
        return predictionReasonHighStressToday(params?['stress']?.toString() ?? '0.0');
      case 'predictionReasonLowConsistency':
        return predictionReasonLowConsistency(params?['percent']?.toString() ?? '0');
      case 'predictionReasonUpcomingWorkload':
        return predictionReasonUpcomingWorkload(params?['count'] as int? ?? 0);
      case 'predictionReasonStressHigh':
        return predictionReasonStressHigh(params?['stress']?.toString() ?? '0.0');
      case 'predictionReasonLowConsistencyDetail':
        return predictionReasonLowConsistencyDetail(params?['delta']?.toString() ?? '0');
      case 'predictionReasonTasksPending':
        return predictionReasonTasksPending(params?['count'] as int? ?? 0);
      case 'predictionReasonDeadlinesSoon':
        return predictionReasonDeadlinesSoon(params?['count'] as int? ?? 0);
      case 'postSessionMoodImproved':
        return postSessionMoodImproved;
      case 'signalStressHigh':
        return signalStressHigh;
      case 'signalStressMedium':
        return signalStressMedium;
      case 'signalMoodLow':
        return moodNameBad;
      case 'signalConsistencyLow':
        return signalConsistencyLow;
      case 'signalDeficitHigh':
        return signalDeficitHigh;
      case 'consistency':
        return consistency;
      case 'stress':
        return stress;
      case 'decisionWorstDay':
        return decisionWorstDay(params?['day']?.toString() ?? '');
      case 'decisionMainFactor':
        return decisionMainFactor(params?['factor']?.toString() ?? '');
      case 'takeItSlowerTodayTitle':
        return takeItSlowerTodayTitle;
      case 'takeItSlowerTodayBody':
        return takeItSlowerTodayBody;
      case 'moodNameBad':
        return moodNameBad;
      case 'decisionLightTasksOnly':
        return decisionLightTasksOnly;
      case 'strongStateTitle':
        return strongStateTitle;
      case 'strongStateBody':
        return strongStateBody;
      case 'highRisk':
        return highRisk;
      case 'decisionBurnoutDurationCap':
        return decisionBurnoutDurationCap;
      case 'stressTrends':
        return stressTrends;
      case 'burnoutMessageEmotionalRisk':
        return burnoutMessageEmotionalRisk;
      case 'moodTrends':
        return moodTrends;
      case 'predictionLevelHigh':
        return predictionLevelHigh;
      case 'upcomingDeadlines':
        return upcomingDeadlines;
      case 'decisionLowActivityHighStress':
        return decisionLowActivityHighStress;
      case 'decisionActionShortSessions':
        return decisionActionShortSessions;
      case 'decisionFixedSchedule':
        return decisionFixedSchedule;
      case 'decisionActionFixedSchedule':
        return decisionActionFixedSchedule;
      case 'decisionMorningPlanning':
        return decisionMorningPlanning;
      case 'predictionPlanLightFocus':
        return predictionPlanLightFocus;
      case 'predictionPlanFocusExecution':
        return predictionPlanFocusExecution;
      case 'predictionPlanDeepExecution':
        return predictionPlanDeepExecution;
      case 'predictionPlanLightReview':
        return predictionPlanLightReview;
      case 'decisionActionPlanning':
        return decisionActionPlanning;
      case 'decisionAfternoonExecution':
        return decisionAfternoonExecution;
      case 'decisionActionExecution':
        return decisionActionExecution;
      case 'decisionNightLightReview':
        return decisionNightLightReview;
      case 'decisionActionLightReview':
        return decisionActionLightReview;
      case 'decisionActionBreakDown':
        return decisionActionBreakDown;
      case 'studyProfileMorning':
        return studyProfileMorning;
      case 'studyProfileAfternoon':
        return studyProfileAfternoon;
      case 'studyProfileEvening':
        return studyProfileEvening;
      case 'studyProfileMainFactor':
        return studyProfileMainFactor(params?['factor']?.toString() ?? '');
      case 'studyProfileSecondaryFactor':
        return studyProfileSecondaryFactor(params?['factor']?.toString() ?? '');
      case 'decisionRecommendedSession':
        final mins = params?['minutes'];
        return decisionRecommendedSession(mins is num ? mins.toInt() : 0);
      default:
        return key;
    }
  }

  String translateTrend(String trend) {
    switch (trend) {
      case 'Improving':
        return statusImproving;
      case 'Worsening':
        return statusDeclining;
      case 'Unstable':
        return statusVariable;
      case 'Moderate':
        return statusModerate;
      case 'Stable':
        return statusStable;
      default:
        return trend;
    }
  }

  String getConfidenceLabel(double confidence) {
    if (confidence >= 0.7) return confidenceHigh;
    if (confidence >= 0.4) return confidenceMedium;
    return confidenceLow;
  }
}
