import '../../l10n/app_localizations.dart';
import 'risk_input.dart';
import 'risk_result.dart';

class RiskState {
  final RiskInput input;
  final RiskResult result;
  final bool isLoading;
  final bool hasData;
  final int? trendDelta;

  const RiskState({
    required this.input,
    required this.result,
    this.isLoading = false,
    this.hasData = true,
    this.trendDelta,
  });

  factory RiskState.loading() => const RiskState(
        input: RiskInput(
          overdueTasks: 0,
          upcomingTasks: 0,
          totalECTS: 0,
          studyHours: 0,
          studyGoal: 10.0,
        ),
        result: RiskResult(
          totalScore: 0,
          riskLevel: 'low',
          overdueContribution: 0,
          upcomingContribution: 0,
          ectsContribution: 0,
          studyContribution: 0,
          sessionStressContribution: 0,
          consistencyContribution: 0,
        ),
        isLoading: true,
        hasData: false,
      );

  factory RiskState.empty() => const RiskState(
        input: RiskInput(
          overdueTasks: 0,
          upcomingTasks: 0,
          totalECTS: 0,
          studyHours: 0,
          studyGoal: 10.0,
        ),
        result: RiskResult(
          totalScore: 0,
          riskLevel: 'low',
          overdueContribution: 0,
          upcomingContribution: 0,
          ectsContribution: 0,
          studyContribution: 0,
          sessionStressContribution: 0,
          consistencyContribution: 0,
        ),
        hasData: false,
      );

  /// Generates a smarter interpretation sentence based on risk level.
  String getInterpretation(AppLocalizations l10n) {
    // 1. High Priority Overrides (Per USER request)
    // RULE 2: Stress > Deficit Override
    if (input.avgSessionStress >= 7) {
      return l10n.decisionHighStressOverrideBody;
    }

    if (input.studyDeficit > 10) {
      return l10n.riskInterpretationStudyDeficit;
    }
    
    if (input.overdueTasks + input.upcomingTasks > 0) {
      return l10n.riskInterpretationFocusTasks;
    }

    // 2. Positive Reinforcement (If everything is perfect)
    if (input.overdueTasks == 0 && input.upcomingTasks == 0 && input.studyDeficit <= 0) {
      return l10n.riskInterpretationOnTrack;
    }

    // 3. Fallback to Risk Level based interpretation
    switch (result.riskLevel) {
      case 'high':
        return l10n.riskInterpretationHigh;
      case 'medium':
        return l10n.riskInterpretationMedium;
      default:
        return l10n.riskInterpretationLow;
    }
  }

  /// Appends 1-line reason to High Risk labels
  String getRiskExplanation(AppLocalizations l10n) {
    if (result.riskLevel != 'high') return '';
    
    if (input.studyHours < 2.0 && input.avgSessionStress >= 7) {
      return l10n.riskExplanationLowStudyHighStress;
    }
    if (input.studyDeficit > 15) {
      return l10n.riskExplanationDeficitOnly;
    }
    if (input.avgSessionStress >= 8) {
      return l10n.riskExplanationStressOnly;
    }
    return l10n.riskExplanationGeneric;
  }

  /// Generate localized reasons list
  List<String> getReasons(AppLocalizations l10n) {
    final reasons = <String>[];
    
    // Stress Override: If stress is high, prioritize it and suppress deficit messages
    if (input.avgSessionStress >= 7) {
      reasons.add(l10n.burnoutReasonStress);
      if (input.overdueTasks > 0) reasons.add(l10n.riskReasonOverdue(input.overdueTasks));
      return reasons;
    }

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
      reasons.add(l10n.riskNoData);
    }
    return reasons;
  }
}
