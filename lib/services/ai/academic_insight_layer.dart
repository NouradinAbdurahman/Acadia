import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/risk/risk_input.dart';
import '../../domain/adaptive/adaptive_profile.dart';
import '../../domain/decision/decision_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../models/analytics_data.dart';

/// Deterministic interpretation + recommendations for AI messages.
/// Mirrors [supabase/functions/acadia-ai/academic_insights.ts] rule order and thresholds.
///
/// Recommendations use two lines max: primary action, then optional support (joined with `\n`).

/// Inputs must come only from existing analytics / risk context — no invented numbers.
class AcademicInsightInput {
  const AcademicInsightInput({
    required this.overdueTasks,
    required this.dueSoonTasks,
    required this.studyDeficitHours,
    required this.weeklyStudyGoalHours,
    required this.consistency01,
    required this.riskScore0to100,
    this.calendarWeekTotal,
    this.calendarWeekCompleted,
    this.semesterTaskTotal,
    this.semesterTaskCompleted,
    this.avgSessionStress,
    this.riskTrendDelta,
    this.adaptiveProfile = const AdaptiveProfile.defaults(),
    this.burnoutRisk = 0,
    this.hasAcademicData = true,
    this.hasEnoughSignal = true,
  });

  final int overdueTasks;
  final int dueSoonTasks;
  final double studyDeficitHours;
  final double weeklyStudyGoalHours;
  final double consistency01;
  final double riskScore0to100;
  final int? calendarWeekTotal;
  final int? calendarWeekCompleted;
  final int? semesterTaskTotal;
  final int? semesterTaskCompleted;
  final double? avgSessionStress;
  /// Positive = risk worsened vs last snapshot week-over-week (points on 0–100 scale).
  final int? riskTrendDelta;
  final AdaptiveProfile adaptiveProfile;
  final double burnoutRisk;
  final bool hasAcademicData;
  final bool hasEnoughSignal;

  factory AcademicInsightInput.fromAnalytics({
    required AnalyticsData data,
    double? riskScoreOverride,
    int? riskTrendDelta,
    AdaptiveProfile adaptiveProfile = const AdaptiveProfile.defaults(),
    double burnoutRisk = 0,
    bool hasAcademicData = true,
    bool hasEnoughSignal = true,
  }) {
    final rs = riskScoreOverride ?? data.riskScore;
    return AcademicInsightInput(
      overdueTasks: data.overdueTasks,
      dueSoonTasks: data.dueSoonTasks,
      studyDeficitHours: data.studyDeficit,
      weeklyStudyGoalHours: data.studyGoal,
      consistency01: data.consistency,
      riskScore0to100: rs,
      calendarWeekTotal: data.totalTasks,
      calendarWeekCompleted: data.completedTasks,
      semesterTaskTotal: null,
      semesterTaskCompleted: null,
      avgSessionStress: data.hasStressData ? data.avgSessionStress : null,
      riskTrendDelta: riskTrendDelta,
      adaptiveProfile: adaptiveProfile,
      burnoutRisk: burnoutRisk,
      hasAcademicData: hasAcademicData,
      hasEnoughSignal: hasEnoughSignal,
    );
  }

  factory AcademicInsightInput.fromRiskOnly({
    required RiskInput risk,
    required double riskScore0to100,
    int? riskTrendDelta,
  }) {
    return AcademicInsightInput(
      overdueTasks: risk.overdueTasks,
      dueSoonTasks: risk.upcomingTasks,
      studyDeficitHours: risk.studyDeficit,
      weeklyStudyGoalHours: risk.studyGoal > 0 ? risk.studyGoal : 15.0,
      consistency01: risk.consistency,
      riskScore0to100: riskScore0to100,
      calendarWeekTotal: null,
      calendarWeekCompleted: null,
      semesterTaskTotal: null,
      avgSessionStress: risk.hasStressData ? risk.avgSessionStress : null,
      riskTrendDelta: riskTrendDelta,
    );
  }
}

extension AcademicInsightInputAppendix on AcademicInsightInput {
  ({String insight, String recommendation}) get parts => _pickInsight(this, _aiL10n());

  ({String insight, String recommendation}) partsWithL10n(AppLocalizations l10n) =>
      _pickInsight(this, l10n);

  String buildAppendix() {
    return buildAppendixWithL10n(_aiL10n());
  }

  String buildAppendixWithL10n(AppLocalizations l10n) {
    final r = _pickInsight(this, l10n);
    return '\n\n${l10n.aiInsightTitle}:\n${r.insight}\n\n${l10n.aiRecommendationTitle}:\n${r.recommendation}\n';
  }
}

String _reco(String primary, String secondary) => '$primary\n$secondary';

AppLocalizations _aiL10n() {
  final locale = Intl.getCurrentLocale();
  final languageCode = locale.split(RegExp('[-_]')).first;
  return lookupAppLocalizations(Locale(languageCode));
}

({String insight, String recommendation}) _pickInsight(
  AcademicInsightInput i,
  AppLocalizations l10n,
) {
  debugPrint('[AI Insight] hasData=${i.hasAcademicData} hasSignal=${i.hasEnoughSignal}');
  if (!i.hasAcademicData) {
    return (insight: '', recommendation: '');
  }
  if (!i.hasEnoughSignal) {
    return (insight: '', recommendation: '');
  }
  final core = _pickInsightCore(i, l10n);
  final td = i.riskTrendDelta;
  if (td != null && td > 0) {
    return (
      insight: l10n.aiDetRiskIncreased(td, core.insight),
      recommendation: core.recommendation,
    );
  }
  return core;
}

({String insight, String recommendation}) _pickInsightCore(
  AcademicInsightInput i,
  AppLocalizations l10n,
) {
  final stress = i.avgSessionStress;

  if (stress != null && stress >= 7.0) {
    return (
      insight: l10n.aiDetHighStressInsight(stress.toStringAsFixed(1)),
      recommendation: _reco(
        l10n.aiDetHighStressRecoPrimary,
        l10n.aiDetHighStressRecoSecondary,
      ),
    );
  }

  if (i.overdueTasks > 0) {
    return (
      insight: l10n.aiDetOverdueInsight(i.overdueTasks),
      recommendation: _reco(
        l10n.aiDetOverdueRecoPrimary,
        l10n.aiDetOverdueRecoSecondary,
      ),
    );
  }

  if (i.riskScore0to100 >= 60) {
    return (
      insight: l10n.aiDetRiskHighInsight(i.riskScore0to100.toStringAsFixed(0)),
      recommendation: _reco(
        l10n.aiDetRiskHighRecoPrimary(i.dueSoonTasks),
        l10n.aiDetRiskHighRecoSecondary,
      ),
    );
  }

  if (i.riskScore0to100 >= 30) {
    final recommendedMinutes = DecisionRules.getFinalRecommendedMinutes(
      consistency: i.consistency01,
      stress: i.avgSessionStress ?? 0.0,
      profile: i.adaptiveProfile,
      burnoutRisk: i.burnoutRisk,
    );
    final dailySessions = DecisionRules.getRecommendedDailySessions(
      i.studyDeficitHours,
    );
    final secondary = i.dueSoonTasks > 0
        ? l10n.aiDetModerateSecondaryDueSoon(i.dueSoonTasks)
        : (i.studyDeficitHours >= 2
            ? (dailySessions > 1
                ? l10n.aiDetModerateSecondaryDeficitMulti(
                    dailySessions,
                    recommendedMinutes,
                    math.max(10, recommendedMinutes - 5),
                  )
                : l10n.aiDetModerateSecondaryDeficitSingle(recommendedMinutes))
            : l10n.aiDetModerateSecondaryTomorrow);
    return (
      insight: l10n.aiDetRiskModerateInsight(i.riskScore0to100.toStringAsFixed(0)),
      recommendation: _reco(
        l10n.aiDetRiskModerateRecoPrimary(recommendedMinutes),
        secondary,
      ),
    );
  }

  if (i.studyDeficitHours > 10) {
    return (
      insight: l10n.aiDetDeficitHighInsight(i.studyDeficitHours.toStringAsFixed(1)),
      recommendation: _reco(
        l10n.aiDetDeficitHighRecoPrimary,
        l10n.aiDetDeficitHighRecoSecondary,
      ),
    );
  }

  if (i.studyDeficitHours > 5) {
    return (
      insight: l10n.aiDetDeficitMediumInsight(i.studyDeficitHours.toStringAsFixed(1)),
      recommendation: _reco(
        l10n.aiDetDeficitMediumRecoPrimary,
        l10n.aiDetDeficitMediumRecoSecondary,
      ),
    );
  }

  if (i.consistency01 < 0.35) {
    return (
      insight: l10n.aiDetConsistencyLowInsight((i.consistency01 * 100).toStringAsFixed(0)),
      recommendation: _reco(
        l10n.aiDetConsistencyLowRecoPrimary,
        l10n.aiDetConsistencyLowRecoSecondary,
      ),
    );
  }

  if (i.consistency01 < 0.55) {
    return (
      insight: l10n.aiDetConsistencyMidInsight((i.consistency01 * 100).toStringAsFixed(0)),
      recommendation: _reco(
        l10n.aiDetConsistencyMidRecoPrimary,
        l10n.aiDetConsistencyMidRecoSecondary,
      ),
    );
  }

  if (i.dueSoonTasks >= 3) {
    return (
      insight: l10n.aiDetDueSoonManyInsight(i.dueSoonTasks),
      recommendation: _reco(
        l10n.aiDetDueSoonManyRecoPrimary,
        l10n.aiDetDueSoonManyRecoSecondary,
      ),
    );
  }

  if (i.dueSoonTasks >= 1) {
    return (
      insight: l10n.aiDetDueSoonSomeInsight,
      recommendation: _reco(
        l10n.aiDetDueSoonSomeRecoPrimary,
        l10n.aiDetDueSoonSomeRecoSecondary,
      ),
    );
  }

  final calendarWeekTotal = i.calendarWeekTotal;
  final semTotal = i.semesterTaskTotal;
  if (calendarWeekTotal != null &&
      calendarWeekTotal == 0 &&
      semTotal != null &&
      semTotal > 0) {
    return (
      insight: l10n.aiDetCalendarNoDeadlinesButSemesterInsight,
      recommendation: _reco(
        l10n.aiDetCalendarNoDeadlinesButSemesterRecoPrimary,
        l10n.aiDetCalendarNoDeadlinesButSemesterRecoSecondary,
      ),
    );
  }

  if (calendarWeekTotal != null && calendarWeekTotal == 0) {
    return (
      insight: l10n.aiDetCalendarNoTasksInsight,
      recommendation: _reco(
        l10n.aiDetCalendarNoTasksRecoPrimary,
        l10n.aiDetCalendarNoTasksRecoSecondary,
      ),
    );
  }

  return (
    insight: l10n.aiDetDefaultInsight,
    recommendation: _reco(
      l10n.aiDetDefaultRecoPrimary,
      l10n.aiDetDefaultRecoSecondary,
    ),
  );
}

/// Task-list intents: urgency / backlog hints only (no new numbers).
String buildTaskListInsightAppendix({
  required int urgentCount,
  required int pendingCount,
}) {
  final l10n = _aiL10n();
  if (urgentCount > 0) {
    return '\n\nInsight:\n${l10n.aiTaskUrgentInsight}\n\nRecommendation:\n${l10n.aiTaskUrgentRecoPrimary}\n${l10n.aiTaskUrgentRecoSecondary}\n';
  }
  if (pendingCount >= 5) {
    return '\n\nInsight:\n${l10n.aiTaskBacklogInsight}\n\nRecommendation:\n${l10n.aiTaskBacklogRecoPrimary}\n${l10n.aiTaskBacklogRecoSecondary}\n';
  }
  if (pendingCount >= 1) {
    return '\n\nInsight:\n${l10n.aiTaskQueuedInsight}\n\nRecommendation:\n${l10n.aiTaskQueuedRecoPrimary}\n${l10n.aiTaskQueuedRecoSecondary}\n';
  }
  return '\n\nInsight:\n${l10n.aiTaskNoneInsight}\n\nRecommendation:\n${l10n.aiTaskNoneRecoPrimary}\n${l10n.aiTaskNoneRecoSecondary}\n';
}
