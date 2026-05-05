import 'dart:math' as math;

import '../../domain/risk/risk_input.dart';
import '../../domain/adaptive/adaptive_profile.dart';
import '../../domain/decision/decision_rules.dart';
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

  factory AcademicInsightInput.fromAnalytics({
    required AnalyticsData data,
    double? riskScoreOverride,
    int? riskTrendDelta,
    AdaptiveProfile adaptiveProfile = const AdaptiveProfile.defaults(),
    double burnoutRisk = 0,
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
  ({String insight, String recommendation}) get parts => _pickInsight(this);

  String buildAppendix() {
    final r = parts;
    return '\n\nInsight:\n${r.insight}\n\nRecommendation:\n${r.recommendation}\n';
  }
}

String _reco(String primary, String secondary) => '$primary\n$secondary';

({String insight, String recommendation}) _pickInsight(AcademicInsightInput i) {
  final core = _pickInsightCore(i);
  final td = i.riskTrendDelta;
  if (td != null && td > 0) {
    return (
      insight:
          'Your risk increased by $td% this week.\n${core.insight}',
      recommendation: core.recommendation,
    );
  }
  return core;
}

({String insight, String recommendation}) _pickInsightCore(AcademicInsightInput i) {
  final stress = i.avgSessionStress;

  if (stress != null && stress >= 7.0) {
    return (
      insight:
          'Session stress is high (${stress.toStringAsFixed(1)}/10). That usually means overload or fatigue.',
      recommendation: _reco(
        'Today: one 20–30 minute session, single topic.',
        'Take a 5-minute break before you start the next block.',
      ),
    );
  }

  if (i.overdueTasks > 0) {
    return (
      insight:
          'You have ${i.overdueTasks} overdue task${i.overdueTasks > 1 ? 's' : ''} this semester — that pulls your risk up until they move.',
      recommendation: _reco(
        'Today: finish or reschedule the smallest overdue item first.',
        'Then pick the next smallest — estimate a time box before you start.',
      ),
    );
  }

  if (i.riskScore0to100 >= 60) {
    return (
      insight:
          'Academic risk is high (${i.riskScore0to100.toStringAsFixed(0)}/100). Tasks, study time, or consistency are stacking.',
      recommendation: _reco(
        'Before 18:00: tackle the top due-soon or overdue item (${i.dueSoonTasks} due-soon).',
        'Calendar two 25–40 minute blocks; start the first within 2 hours.',
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
        ? 'Reorder your ${i.dueSoonTasks} due-soon task${i.dueSoonTasks > 1 ? 's' : ''} by deadline tonight.'
        : (i.studyDeficitHours >= 2
            ? (dailySessions > 1
                ? 'Today: do $dailySessions sessions (${recommendedMinutes} + ${math.max(10, recommendedMinutes - 5)} min) to reduce deficit faster.'
                : 'Today: start one ${recommendedMinutes}-minute recovery session.')
            : 'Tomorrow: second 30-minute block so risk does not climb.');
    return (
      insight:
          'Academic risk is moderate (${i.riskScore0to100.toStringAsFixed(0)}/100). Weekly progress is below target and needs recovery actions.',
      recommendation: _reco(
        'Start one focused session now ($recommendedMinutes min).',
        secondary,
      ),
    );
  }

  if (i.studyDeficitHours > 10) {
    return (
      insight:
          'You are about ${i.studyDeficitHours.toStringAsFixed(1)}h behind your weekly study goal — missing multiple days adds up fast.',
      recommendation: _reco(
        'Today: schedule 2–3 blocks (25–40 min each) on your calendar.',
        'Use fixed times — not “when I feel like it.”',
      ),
    );
  }

  if (i.studyDeficitHours > 5) {
    return (
      insight:
          'You are roughly ${i.studyDeficitHours.toStringAsFixed(1)}h under your weekly goal.',
      recommendation: _reco(
        'Before Sunday: add 1–2 focused sessions toward the course with the nearest deadline.',
        'Pick the course that moves your grades most this week.',
      ),
    );
  }

  if (i.consistency01 < 0.35) {
    return (
      insight:
          'Consistency is low (${(i.consistency01 * 100).toStringAsFixed(0)}%). Irregular days make every deadline feel tighter.',
      recommendation: _reco(
        'Next 5 weekdays: same 30-minute start window (e.g. after lunch).',
        'Tonight: one 25-minute session to move off ${(i.consistency01 * 100).toStringAsFixed(0)}%.',
      ),
    );
  }

  if (i.consistency01 < 0.55) {
    return (
      insight:
          'Consistency is middling (${(i.consistency01 * 100).toStringAsFixed(0)}%). You study, but not on a steady rhythm.',
      recommendation: _reco(
        'Today: 25–35 minutes right after a habit you already have.',
        'Tomorrow: repeat at the same clock time.',
      ),
    );
  }

  if (i.dueSoonTasks >= 3) {
    return (
      insight:
          '${i.dueSoonTasks} tasks are due soon — switching between them raises stress.',
      recommendation: _reco(
        'Order by deadline: quick wins first, then the hardest task.',
        'Pause new optional work until these clear.',
      ),
    );
  }

  if (i.dueSoonTasks >= 1) {
    return (
      insight:
          'You have coursework due soon — finishing ahead beats cramming.',
      recommendation: _reco(
        'Today: block time for the nearest deadline first.',
        'If nothing is overdue, pre-read for the next lecture or quiz.',
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
      insight:
          'No deadlines this calendar week, but semester work is still tracked.',
      recommendation: _reco(
        'Use the gap for readings or exam prep.',
        'Add dates to undated tasks so planning stays honest.',
      ),
    );
  }

  if (calendarWeekTotal != null && calendarWeekTotal == 0) {
    return (
      insight:
          'No tasks fall in this calendar-week window — deadlines may be further out.',
      recommendation: _reco(
        'Advance coursework or shore up weak topics.',
        'Bank extra time before the next busy week.',
      ),
    );
  }

  return (
    insight:
        'Snapshot looks manageable: no overdue flag here and risk is not in the high band.',
    recommendation: _reco(
      'Today: one 25-minute review session.',
      'Mid-week: reload deadlines and date any undated tasks.',
    ),
  );
}

/// Task-list intents: urgency / backlog hints only (no new numbers).
String buildTaskListInsightAppendix({
  required int urgentCount,
  required int pendingCount,
}) {
  if (urgentCount > 0) {
    return '\n\nInsight:\n'
        'You have high-priority open work — tackle it before optional tasks.\n\n'
        'Recommendation:\n'
        'Finish one urgent item to completion.\n'
        'Then pick the next urgent line only.\n';
  }
  if (pendingCount >= 5) {
    return '\n\nInsight:\n'
        'Large backlogs increase avoidance.\n\n'
        'Recommendation:\n'
        'Today: finish the two smallest tasks.\n'
        'That shrinks the list you see every morning.\n';
  }
  if (pendingCount >= 1) {
    return '\n\nInsight:\n'
        'Queued work without dates tends to slip.\n\n'
        'Recommendation:\n'
        'Schedule the next two tasks on your calendar.\n'
        'Give each a start time, not only a due date.\n';
  }
  return '\n\nInsight:\n'
      'No urgent items in this view.\n\n'
      'Recommendation:\n'
      'Use spare time for readings or long assignments.\n'
      'Add the next exam date if it is not in yet.\n';
}
