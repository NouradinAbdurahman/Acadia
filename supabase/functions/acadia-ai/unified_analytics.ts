/**
 * Acadia Unified Analytics Contract — Step 1 (server)
 *
 * Single JSON shape for future: Edge tools, email, client sync, AI resolver.
 * Does NOT replace existing callers yet — import and compare (Step 3) before switching.
 *
 * Parity targets (Dart):
 * - lib/core/services/risk_engine.dart — RiskEngine.calculate
 * - lib/providers/risk_provider.dart — RiskInput metrics (semester-scoped)
 * - lib/repositories/analytics_repository.dart — consistency = distinct session days / 7 (rolling)
 * - Study “this week” hours — calendar week Mon start, same math as getStudyAnalytics in index.ts
 *
 * NOTE: Client risk uses rolling-7-day hours for deficit; analytics UI uses calendar week for
 * “this week” study hours. This contract exposes BOTH study fields explicitly so you can
 * converge UI later without losing either definition during migration.
 */

// -----------------------------------------------------------------------------
// Types (contract)
// -----------------------------------------------------------------------------

export interface UnifiedStudyBlock {
  /** Hours from study_sessions in [weekStart, weekEnd) — calendar week, Monday start */
  thisWeekHours: number;
  weeklyGoal: number;
  /** max(0, weeklyGoal - thisWeekHours) — calendar week */
  studyDeficitCalendar: number;
  /** Semester-length average weekly hours (all sessions in semester / elapsed weeks) */
  weeklyAverage: number;
  /** ISO date (YYYY-MM-DD) Monday week boundary used — computed in UTC for stability */
  weekStart: string;
  weekType: "calendar_monday";
  timezone: "UTC";
  /** Rolling last 7×24h from generatedAt — matches AnalyticsData consistency definition */
  consistencyStudyDays: number;
  /** sessionDays.size / 7, capped 1 — matches analytics_repository rolling window */
  consistency: number;
  /** Sum hours from sessions with created_at >= now - 7 days (floating window) */
  rolling7DayHours: number;
  /** max(0, weeklyGoal - rolling7DayHours) — matches risk_provider deficit input */
  studyDeficitRolling: number;
}

/** Calendar-week task counts (deadline in [weekStart, weekEnd)); same math as weeklyCompletionRate */
export interface UnifiedTasksCalendarWeekBlock {
  total: number;
  completed: number;
}

export interface UnifiedTasksBlock {
  total: number;
  completed: number;
  pending: number;
  overdue: number;
  dueSoon: number;
  completionRate: number;
  /** Tasks with deadline in calendar week / completed in that set — matches computeSummaryData */
  weeklyCompletionRate: number;
  /** Explicit weekly counts (same as local vars weeklyTotal / weeklyCompleted) */
  calendarWeek: UnifiedTasksCalendarWeekBlock;
  /** Normalized rows for consumers */
  items: UnifiedTaskItem[];
}

export interface UnifiedTaskItem {
  id: string;
  title: string;
  deadline: string | null;
  priority: string | null;
  status: string;
  completed: boolean;
}

export interface UnifiedDeadlinesBlock {
  upcoming: UnifiedDeadlineItem[];
  count: number;
}

export interface UnifiedDeadlineItem {
  id: string;
  title: string;
  date: string;
  isCompleted: boolean;
}

export interface UnifiedRiskBlock {
  score: number;
  level: "low" | "medium" | "high";
  breakdown: {
    overdueImpact: number;
    dueSoonImpact: number;
    studyDeficitImpact: number;
    stressImpact: number;
    consistencyImpact: number;
  };
  /** Inputs echoed for audit/compare */
  inputs: {
    overdueTasks: number;
    dueSoonTasks: number;
    studyDeficitHours: number;
    avgSessionStress: number;
    consistency: number;
    hasStressData: boolean;
  };
}

export interface UnifiedMoodBlock {
  avgDailyStress: number;
  avgSessionStress: number;
  trend: "stable" | "increasing" | "decreasing";
  burnoutScore: number;
  /** Task-completion ratio (same as risk consistency), not study-day consistency */
  consistencyTaskCompletion: number;
}

export interface UnifiedCoursesBlock {
  total: number;
  items: Record<string, unknown>[];
}

export interface UnifiedAnalyticsContract {
  semesterId: string;
  generatedAt: string;
  study: UnifiedStudyBlock;
  tasks: UnifiedTasksBlock;
  deadlines: UnifiedDeadlinesBlock;
  risk: UnifiedRiskBlock;
  mood: UnifiedMoodBlock;
  courses: UnifiedCoursesBlock;
}

// -----------------------------------------------------------------------------
// Risk engine (ports lib/core/services/risk_engine.dart)
// -----------------------------------------------------------------------------

export function riskEngineCalculate(input: {
  overdueTasks: number;
  dueSoonTasks: number;
  studyDeficitHours: number;
  stressLevel: number;
  consistency: number;
  hasStressData: boolean;
}): {
  score: number;
  level: "low" | "medium" | "high";
  breakdown: UnifiedRiskBlock["breakdown"];
} {
  const overdueScore = Math.min(30, input.overdueTasks * 10);
  const dueSoonScore = Math.min(15, input.dueSoonTasks * 5);
  const deficitScore = Math.min(
    25,
    Math.max(0, (input.studyDeficitHours / 24.0) * 25.0),
  );
  let stressScore = 0;
  if (input.hasStressData) {
    stressScore = Math.min(15, Math.max(0, (input.stressLevel / 10.0) * 15.0));
  }
  const consistencyScore = Math.min(
    15,
    Math.max(0, (1.0 - input.consistency) * 15.0),
  );

  const totalRaw =
    overdueScore + dueSoonScore + deficitScore + stressScore + consistencyScore;
  const finalScore = Math.min(100, Math.max(0, totalRaw));

  let level: "low" | "medium" | "high";
  if (finalScore >= 60) level = "high";
  else if (finalScore >= 30) level = "medium";
  else level = "low";

  return {
    score: finalScore,
    level,
    breakdown: {
      overdueImpact: overdueScore,
      dueSoonImpact: dueSoonScore,
      studyDeficitImpact: deficitScore,
      stressImpact: stressScore,
      consistencyImpact: consistencyScore,
    },
  };
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function toUtcDateKey(d: Date): string {
  return d.toISOString().split("T")[0];
}

/** Monday 00:00 UTC for the week containing `now` */
function startOfWeekMondayUtc(now: Date): Date {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dow = d.getUTCDay(); // 0 Sun .. 6 Sat
  const offset = (dow + 6) % 7; // Mon => 0
  d.setUTCDate(d.getUTCDate() - offset);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

function taskCompleted(row: Record<string, unknown>): boolean {
  const st = row.status;
  if (typeof st === "string" && st === "completed") return true;
  return false;
}

function computeBurnoutScore(input: {
  avgStress: number;
  studyDeficit: number;
  consistency: number;
}): number {
  const stressFactor = Math.min(1, Math.max(0, input.avgStress / 10.0));
  const deficitFactor = Math.min(1, Math.max(0, input.studyDeficit / 24.0));
  const consistencyFactor = Math.min(1, Math.max(0, 1.0 - input.consistency));
  const score =
    (stressFactor * 0.4 + deficitFactor * 0.4 + consistencyFactor * 0.2) * 100.0;
  return Math.min(100, Math.max(0, score));
}

// -----------------------------------------------------------------------------
// Main API
// -----------------------------------------------------------------------------

export async function getUnifiedAnalytics(
  supabase: any,
  userId: string,
  semesterId: string,
): Promise<UnifiedAnalyticsContract> {
  const generatedAt = new Date().toISOString();
  const now = new Date();

  const weekStart = startOfWeekMondayUtc(now);
  const weekEnd = new Date(weekStart);
  weekEnd.setUTCDate(weekStart.getUTCDate() + 7);

  const todayUtcMidnight = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  const in3Days = new Date(todayUtcMidnight);
  in3Days.setUTCDate(in3Days.getUTCDate() + 3);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const { data: semRow } = await supabase
    .from("semesters")
    .select("weekly_study_goal, start_date, end_date, created_at")
    .eq("id", semesterId)
    .maybeSingle();

  const weeklyGoal = Number(semRow?.weekly_study_goal ?? 15) || 15;

  const { data: sessionsRaw } = await supabase
    .from("study_sessions")
    .select("duration_minutes, created_at, course_id")
    .eq("user_id", userId)
    .eq("semester_id", semesterId);

  const sessions = sessionsRaw || [];

  const calSessions = sessions.filter((s: any) => {
    const t = new Date(s.created_at);
    return t >= weekStart && t < weekEnd;
  });
  const thisWeekMinutes = calSessions.reduce(
    (sum: number, s: any) => sum + (s.duration_minutes || 0),
    0,
  );
  const thisWeekHours = thisWeekMinutes / 60.0;

  const rollingSessions = sessions.filter(
    (s: any) => new Date(s.created_at) >= sevenDaysAgo,
  );
  const rollingHours =
    rollingSessions.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0) /
    60.0;

  const sessionDays = new Set(
    sessions
      .filter((s: any) => new Date(s.created_at) >= sevenDaysAgo)
      .map((s: any) => toUtcDateKey(new Date(s.created_at))),
  );
  const consistencyStudyDays = sessionDays.size;
  const consistency = Math.min(consistencyStudyDays / 7.0, 1.0);

  let weeklyAvg = 0;
  if (semRow) {
    const start = new Date(semRow.start_date || semRow.created_at);
    const end = semRow.end_date ? new Date(semRow.end_date) : now;
    const weeks = Math.max(
      1,
      (end.getTime() - start.getTime()) / (7 * 24 * 60 * 60 * 1000),
    );
    const totalHours =
      sessions.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0) /
      60.0;
    weeklyAvg = totalHours / weeks;
  }

  const studyDeficitCalendar = Math.max(0, weeklyGoal - thisWeekHours);
  const studyDeficitRolling = Math.max(0, weeklyGoal - rollingHours);

  const study: UnifiedStudyBlock = {
    thisWeekHours,
    weeklyGoal,
    studyDeficitCalendar,
    weeklyAverage: weeklyAvg,
    weekStart: toUtcDateKey(weekStart),
    weekType: "calendar_monday",
    timezone: "UTC",
    consistencyStudyDays,
    consistency,
    rolling7DayHours: rollingHours,
    studyDeficitRolling,
  };

  const { data: tasksRaw } = await supabase
    .from("tasks")
    .select(
      "id,title,deadline,status,priority,estimated_time,notes,course_id,semester_id",
    )
    .eq("user_id", userId)
    .eq("semester_id", semesterId);

  const tasks = (tasksRaw || []) as Record<string, unknown>[];

  let completed = 0;
  let overdue = 0;
  let dueSoon = 0;
  const items: UnifiedTaskItem[] = [];

  for (const t of tasks) {
    const done = taskCompleted(t);
    if (done) completed++;
    const dl = t.deadline ? new Date(t.deadline as string) : null;
    if (!done && dl) {
      if (dl < todayUtcMidnight) overdue++;
      else if (dl >= todayUtcMidnight && dl < in3Days) dueSoon++;
    }
    items.push({
      id: String(t.id),
      title: String(t.title ?? ""),
      deadline: t.deadline ? String(t.deadline) : null,
      priority: t.priority ? String(t.priority) : null,
      status: typeof t.status === "string" ? t.status : "pending",
      completed: done,
    });
  }

  const total = tasks.length;
  const pending = total - completed;
  const completionRate = total === 0 ? 0 : Math.round((completed / total) * 1000) / 10;

  const sumWeekStart = weekStart;
  const sumEndOfWeek = weekEnd;
  const weeklyTasks = tasks.filter((t) => {
    if (!t.deadline) return false;
    const taskDate = new Date(t.deadline as string);
    return taskDate >= sumWeekStart && taskDate < sumEndOfWeek;
  });
  const weeklyCompleted = weeklyTasks.filter((t) => taskCompleted(t)).length;
  const weeklyTotal = weeklyTasks.length;
  const weeklyCompletionRate =
    weeklyTotal === 0
      ? 0
      : Math.round((weeklyCompleted / weeklyTotal) * 1000) / 10;

  const tasksBlock: UnifiedTasksBlock = {
    total,
    completed,
    pending,
    overdue,
    dueSoon,
    completionRate,
    weeklyCompletionRate,
    calendarWeek: {
      total: weeklyTotal,
      completed: weeklyCompleted,
    },
    items,
  };

  const { data: dlinesRaw } = await supabase
    .from("academic_deadlines")
    .select(
      "id,title,deadline_date,deadline_type,priority,notes,course_id,is_completed,semester_id",
    )
    .eq("user_id", userId)
    .eq("semester_id", semesterId)
    .eq("is_completed", false)
    .gte("deadline_date", todayUtcMidnight.toISOString())
    .order("deadline_date", { ascending: true });

  const dlines = (dlinesRaw || []) as Record<string, unknown>[];
  const upcoming: UnifiedDeadlineItem[] = dlines.map((d) => ({
    id: String(d.id),
    title: String(d.title ?? ""),
    date: d.deadline_date ? String(d.deadline_date) : "",
    isCompleted: Boolean(d.is_completed),
  }));

  const deadlines: UnifiedDeadlinesBlock = {
    upcoming,
    count: upcoming.length,
  };

  const { data: moodsRaw } = await supabase
    .from("mood_logs")
    .select("mood_level,stress_level,source,created_at")
    .eq("user_id", userId)
    .eq("semester_id", semesterId);

  const moods = moodsRaw || [];
  const sessionMoods = moods.filter(
    (m: any) => String(m.source || "").trim().toLowerCase() === "session",
  );
  const dailyMoods = moods.filter(
    (m: any) => String(m.source || "").trim().toLowerCase() !== "session",
  );

  const avg = (arr: any[], fn: (x: any) => number) =>
    arr.length === 0
      ? 0
      : arr.reduce((s, x) => s + fn(x), 0) / arr.length;

  const avgSessionStress = avg(sessionMoods, (m) => Number(m.stress_level ?? 0));
  const avgDailyStress = avg(dailyMoods, (m) => Number(m.stress_level ?? 0));

  let trend: "stable" | "increasing" | "decreasing" = "stable";
  if (moods.length >= 2) {
    const sorted = [...moods].sort(
      (a: any, b: any) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
    );
    const delta =
      Number(sorted[sorted.length - 1].stress_level ?? 0) -
      Number(sorted[0].stress_level ?? 0);
    if (delta > 0.5) trend = "increasing";
    else if (delta < -0.5) trend = "decreasing";
  }

  const consistencyTaskCompletion = total === 0 ? 1.0 : completed / total;

  const riskInput = {
    overdueTasks: overdue,
    dueSoonTasks: dueSoon,
    studyDeficitHours: studyDeficitRolling,
    stressLevel: avgSessionStress,
    consistency: consistencyTaskCompletion,
    hasStressData: sessionMoods.length > 0,
  };

  const riskCalc = riskEngineCalculate(riskInput);

  const risk: UnifiedRiskBlock = {
    score: riskCalc.score,
    level: riskCalc.level,
    breakdown: {
      overdueImpact: riskCalc.breakdown.overdueImpact,
      dueSoonImpact: riskCalc.breakdown.dueSoonImpact,
      studyDeficitImpact: riskCalc.breakdown.studyDeficitImpact,
      stressImpact: riskCalc.breakdown.stressImpact,
      consistencyImpact: riskCalc.breakdown.consistencyImpact,
    },
    inputs: {
      overdueTasks: overdue,
      dueSoonTasks: dueSoon,
      studyDeficitHours: studyDeficitRolling,
      avgSessionStress,
      consistency: consistencyTaskCompletion,
      hasStressData: sessionMoods.length > 0,
    },
  };

  const mood: UnifiedMoodBlock = {
    avgDailyStress,
    avgSessionStress,
    trend,
    burnoutScore: computeBurnoutScore({
      avgStress: avgSessionStress,
      // Keep parity with client AnalyticsRepository burnout input (calendar-week deficit).
      studyDeficit: studyDeficitCalendar,
      consistency: consistency,
    }),
    consistencyTaskCompletion,
  };

  const { data: coursesRaw } = await supabase
    .from("courses")
    .select("*")
    .eq("user_id", userId)
    .eq("semester_id", semesterId);

  const courses: UnifiedCoursesBlock = {
    total: (coursesRaw || []).length,
    items: coursesRaw || [],
  };

  return {
    semesterId,
    generatedAt,
    study,
    tasks: tasksBlock,
    deadlines,
    risk,
    mood,
    courses,
  };
}
