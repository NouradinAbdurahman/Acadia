/**
 * Deterministic interpretation + recommendations for AI replies.
 * Rule order and thresholds must match lib/services/ai/academic_insight_layer.dart
 * Recommendations: two short lines joined with \n (primary, then optional support).
 */

export interface AcademicInsightInput {
  overdueTasks: number;
  dueSoonTasks: number;
  studyDeficitHours: number;
  weeklyStudyGoalHours: number;
  consistency01: number;
  riskScore0to100: number;
  calendarWeekTotal: number | null;
  calendarWeekCompleted: number | null;
  semesterTaskTotal?: number | null;
  avgSessionStress?: number | null;
  /** Positive = risk worsened vs last week (points on 0–100 scale). */
  riskTrendDelta?: number | null;
  burnoutScore?: number | null;
}

function reco(primary: string, secondary: string): string {
  return `${primary}\n${secondary}`;
}

function getRecommendedSessionMinutes(consistency: number, avgStress: number): number {
  if (consistency < 0.5) return 30;
  if (avgStress >= 6) return 25;
  return 45;
}

function getFinalRecommendedSessionMinutes(input: AcademicInsightInput): number {
  let minutes = getRecommendedSessionMinutes(input.consistency01, input.avgSessionStress ?? 0);
  const burnout = input.burnoutScore ?? 0;
  if (burnout > 50) {
    const cap = burnout >= 65 ? 30 : 35;
    minutes = Math.min(minutes, cap);
  }
  return minutes;
}

function pickInsightCore(i: AcademicInsightInput): { insight: string; recommendation: string } {
  const stress = i.avgSessionStress;

  if (stress != null && stress >= 7.0) {
    return {
      insight: `Session stress is high (${stress.toFixed(1)}/10). That usually means overload or fatigue.`,
      recommendation: reco(
        "Today: one 20–30 minute session, single topic.",
        "Take a 5-minute break before you start the next block.",
      ),
    };
  }

  if (i.overdueTasks > 0) {
    return {
      insight: `You have ${i.overdueTasks} overdue task${i.overdueTasks > 1 ? "s" : ""} this semester — that pulls your risk up until they move.`,
      recommendation: reco(
        "Today: finish or reschedule the smallest overdue item first.",
        "Then pick the next smallest — estimate a time box before you start.",
      ),
    };
  }

  if (i.riskScore0to100 >= 60) {
    return {
      insight: `Academic risk is high (${i.riskScore0to100.toFixed(0)}/100). Tasks, study time, or consistency are stacking.`,
      recommendation: reco(
        `Before 18:00: tackle the top due-soon or overdue item (${i.dueSoonTasks} due-soon).`,
        "Calendar two 25–40 minute blocks; start the first within 2 hours.",
      ),
    };
  }

  if (i.riskScore0to100 >= 30) {
    const recommendedMinutes = getFinalRecommendedSessionMinutes(i);
    const secondary =
      i.dueSoonTasks > 0
        ? `Reorder your ${i.dueSoonTasks} due-soon task${i.dueSoonTasks > 1 ? "s" : ""} by deadline tonight.`
        : i.studyDeficitHours >= 2
          ? `Do ${i.studyDeficitHours >= 8 ? "3" : "2"} sessions this week to reduce your deficit.`
          : "Tomorrow: second 30-minute block so risk does not climb.";
    return {
      insight: `Academic risk is moderate (${i.riskScore0to100.toFixed(0)}/100). You are falling behind where your weekly goal expects you to be.`,
      recommendation: reco(`Start one focused session now (${recommendedMinutes} min).`, secondary),
    };
  }

  if (i.studyDeficitHours > 10) {
    return {
      insight: `You are about ${i.studyDeficitHours.toFixed(1)}h behind your weekly study goal — missing multiple days adds up fast.`,
      recommendation: reco(
        "Today: schedule 2–3 blocks (25–40 min each) on your calendar.",
        'Use fixed times — not "when I feel like it."',
      ),
    };
  }

  if (i.studyDeficitHours > 5) {
    return {
      insight: `You are roughly ${i.studyDeficitHours.toFixed(1)}h under your weekly goal.`,
      recommendation: reco(
        "Before Sunday: add 1–2 focused sessions toward the course with the nearest deadline.",
        "Pick the course that moves your grades most this week.",
      ),
    };
  }

  if (i.consistency01 < 0.35) {
    return {
      insight: `Consistency is low (${(i.consistency01 * 100).toFixed(0)}%). Irregular days make every deadline feel tighter.`,
      recommendation: reco(
        "Next 5 weekdays: same 30-minute start window (e.g. after lunch).",
        `Tonight: one 25-minute session to move off ${(i.consistency01 * 100).toFixed(0)}%.`,
      ),
    };
  }

  if (i.consistency01 < 0.55) {
    return {
      insight: `Consistency is middling (${(i.consistency01 * 100).toFixed(0)}%). You study, but not on a steady rhythm.`,
      recommendation: reco(
        "Today: 25–35 minutes right after a habit you already have.",
        "Tomorrow: repeat at the same clock time.",
      ),
    };
  }

  if (i.dueSoonTasks >= 3) {
    return {
      insight: `${i.dueSoonTasks} tasks are due soon — switching between them raises stress.`,
      recommendation: reco(
        "Order by deadline: quick wins first, then the hardest task.",
        "Pause new optional work until these clear.",
      ),
    };
  }

  if (i.dueSoonTasks >= 1) {
    return {
      insight: "You have coursework due soon — finishing ahead beats cramming.",
      recommendation: reco(
        "Today: block time for the nearest deadline first.",
        "If nothing is overdue, pre-read for the next lecture or quiz.",
      ),
    };
  }

  const cw = i.calendarWeekTotal;
  const semTotal = i.semesterTaskTotal;
  if (cw != null && cw === 0 && semTotal != null && semTotal > 0) {
    return {
      insight: "No deadlines this calendar week, but semester work is still tracked.",
      recommendation: reco(
        "Use the gap for readings or exam prep.",
        "Add dates to undated tasks so planning stays honest.",
      ),
    };
  }

  if (cw != null && cw === 0) {
    return {
      insight: "No tasks fall in this calendar-week window — deadlines may be further out.",
      recommendation: reco(
        "Advance coursework or shore up weak topics.",
        "Bank extra time before the next busy week.",
      ),
    };
  }

  return {
    insight: "Snapshot looks manageable: no overdue flag here and risk is not in the high band.",
    recommendation: reco(
      "Today: one 25-minute review session.",
      "Mid-week: reload deadlines and date any undated tasks.",
    ),
  };
}

export function pickInsight(i: AcademicInsightInput): { insight: string; recommendation: string } {
  const core = pickInsightCore(i);
  const td = i.riskTrendDelta;
  if (td != null && td > 0) {
    return {
      insight: `Your risk increased by ${td}% this week.\n${core.insight}`,
      recommendation: core.recommendation,
    };
  }
  return core;
}

export function buildAcademicInsightAppendix(i: AcademicInsightInput): string {
  const r = pickInsight(i);
  return `\n\nInsight:\n${r.insight}\n\nRecommendation:\n${r.recommendation}\n`;
}

export function buildAcademicInsightParts(i: AcademicInsightInput): {
  insight: string;
  recommendation: string;
} {
  return pickInsight(i);
}

export function buildTaskListInsightAppendix(urgentCount: number, pendingCount: number): string {
  if (urgentCount > 0) {
    return `\n\nInsight:\nYou have high-priority open work — tackle it before optional tasks.\n\nRecommendation:\nFinish one urgent item to completion.\nThen pick the next urgent line only.\n`;
  }
  if (pendingCount >= 5) {
    return `\n\nInsight:\nLarge backlogs increase avoidance.\n\nRecommendation:\nToday: finish the two smallest tasks.\nThat shrinks the list you see every morning.\n`;
  }
  if (pendingCount >= 1) {
    return `\n\nInsight:\nQueued work without dates tends to slip.\n\nRecommendation:\nSchedule the next two tasks on your calendar.\nGive each a start time, not only a due date.\n`;
  }
  return `\n\nInsight:\nNo urgent items in this view.\n\nRecommendation:\nUse spare time for readings or long assignments.\nAdd the next exam date if it is not in yet.\n`;
}
