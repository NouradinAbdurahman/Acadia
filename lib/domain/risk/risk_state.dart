import '../../l10n/app_localizations.dart';
import 'risk_input.dart';
import 'risk_result.dart';

class RiskState {
  final RiskInput input;
  final RiskResult result;
  final int trendDelta;

  const RiskState({
    required this.input,
    required this.result,
    required this.trendDelta,
  });

  /// Generates a smarter interpretation sentence based on risk level.
  String getInterpretation(AppLocalizations l10n) {
    // 1. Positive Reinforcement
    final deficit = (input.studyGoal > 0) 
        ? (input.studyGoal - input.studyHours) / input.studyGoal 
        : 0.0;
    
    if (input.overdueTasks == 0 && deficit < 0.3) {
      return l10n.riskInterpretationOnTrack;
    }

    // 2. Risk Level based interpretation
    switch (result.riskLevel) {
      case 'high':
        return l10n.riskInterpretationHigh;
      case 'medium':
        return l10n.riskInterpretationMedium;
      default:
        return l10n.riskInterpretationLow;
    }
  }

  /// Generate localized reasons list
  List<String> getReasons(AppLocalizations l10n) {
    final reasons = <String>[];
    if (input.overdueTasks > 0) {
      reasons.add(l10n.riskReasonOverdue(input.overdueTasks));
    }
    if (input.studyHours < input.studyGoal) {
      reasons.add(l10n.riskReasonStudyLow);
    }
    if (input.upcomingTasks > 0) {
      reasons.add(l10n.riskReasonUpcoming(input.upcomingTasks));
    }
    if (reasons.isEmpty) {
      reasons.add(l10n.riskNoData); // Optional: if perfectly fine, maybe no reason.
    }
    return reasons;
  }
}
