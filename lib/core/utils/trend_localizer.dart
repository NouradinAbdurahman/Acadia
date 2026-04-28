import '../../l10n/app_localizations.dart';
import '../../models/trend_data.dart';

class TrendLocalizer {
  static String localizeTitle(AppLocalizations l10n, TrendInsight insight) {
    switch (insight.key) {
      case 'study_build_consistency':
        return l10n.trendInsightBuildConsistencyTitle;
      case 'study_increased':
        return l10n.trendInsightStudyIncreasedSignificantlyTitle;
      case 'study_improved':
        return l10n.trendInsightStudyImprovedTitle;
      case 'study_declined':
        return l10n.trendInsightStudyDeclinedTitle;
      case 'no_tasks':
        return l10n.trendInsightNoTasksTitle;
      case 'task_completion_low_none':
      case 'task_completion_low_some':
        return l10n.trendInsightTaskLowTitle;
      case 'no_workload':
        return l10n.trendInsightNoWorkloadTitle;
      case 'workload_increased':
        return l10n.trendInsightWorkloadSharpTitle;
      case 'workload_rising':
        return l10n.trendInsightWorkloadRisingTitle;
      case 'performance_declining':
        return l10n.trendInsightPerformanceDecliningTitle;
      case 'performance_improving':
        return l10n.trendInsightPerformanceImprovingTitle;
      case 'performance_stable':
        return l10n.trendInsightPerformanceStableTitle;
      case 'stable_trends':
        return l10n.trendInsightStableTitle;
      case 'limited_data_period':
        return l10n.trendInsightLimitedDataTitle;
      default:
        return insight.title;
    }
  }

  static String localizeMessage(AppLocalizations l10n, TrendInsight insight) {
    switch (insight.key) {
      case 'study_build_consistency':
        return l10n.trendInsightBuildConsistencyMessage;
      case 'study_increased':
      case 'study_improved':
        return l10n.trendInsightStudyIncreasedMessage(
          insight.params['percent'] ?? 0,
        );
      case 'study_declined':
        return l10n.trendInsightStudyDroppedMessage(
          insight.params['percent'] ?? 0,
        );
      case 'no_tasks':
        return l10n.trendInsightNoTasksMessage;
      case 'task_completion_low_none':
        return l10n.trendInsightNoTasksCompletedMessage;
      case 'task_completion_low_some':
        return l10n.trendInsightTaskCompletedFractionMessage(
          insight.params['completed'] ?? 0,
          insight.params['total'] ?? 0,
        );
      case 'no_workload':
        return l10n.trendInsightNoWorkloadMessage;
      case 'workload_increased':
      case 'workload_rising':
        return l10n.trendInsightWorkloadAddedMessage(
          insight.params['count'] ?? 0,
        );
      case 'performance_declining':
        return l10n.trendInsightPerformanceDecliningMessage;
      case 'performance_improving':
        return l10n.trendInsightPerformanceImprovingMessage;
      case 'performance_stable':
        return l10n.trendInsightPerformanceStableMessage;
      case 'stable_trends':
        return l10n.trendInsightStableMessage;
      case 'limited_data_period':
        return l10n.trendInsightLimitedDataMessage;
      default:
        return insight.message;
    }
  }
}
