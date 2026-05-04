// @ts-nocheck
import OpenAI from "npm:openai@4.68.0";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "npm:resend@2.0.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Intent =
  | "get_tasks"
  | "get_deadlines"
  | "get_summary"
  | "get_focus"
  | "email_tasks"
  | "get_profile"
  | "get_courses"
  | "get_details"
  | "summarize_last"
  | "ai";

// -----------------------------
// INTENT (fallback only)
// -----------------------------
function resolveIntent(msg: string, context: any): Intent {
  const m = msg.toLowerCase().trim();

  if (m.includes("task")) return "get_tasks";
  if (m.includes("deadline")) return "get_deadlines";
  if (m.includes("summary") || m.includes("summarize")) return "get_summary";
  if (m.includes("focus")) return "get_focus";
  if (m.includes("email")) return "email_tasks";
  if (m.includes("profile") || m.includes("who am i")) return "get_profile";
  if (m.includes("course")) return "get_courses";
  if (m.includes("detail") || m.includes("more info")) return "get_details";
  if (m.includes("explain") || m.includes("summarize this")) return "summarize_last";

  return "ai";
}

// -----------------------------
// PRIORITY ENGINE
// -----------------------------
function calculatePriority(item: any): number {
  if (item.status === "completed" || item.is_completed === true) return 0;
  if (item.priority?.toLowerCase() === "high") return 4;

  const d = item.deadline || item.deadline_date;
  if (!d) return 1;

  const hours = (new Date(d).getTime() - Date.now()) / (1000 * 60 * 60);

  if (hours < 0) return 4;
  if (hours < 24) return 3;
  if (hours < 72) return 2;
  return 1;
}

// -----------------------------
// TASKS
// -----------------------------
async function getTasks(supabase: any, userId: string, semesterId: string) {
  const { data, error } = await supabase
    .from("tasks")
    .select(`
      id,
      title,
      deadline,
      status,
      priority,
      estimated_time,
      notes,
      course_id,
      semester_id
    `)
    .eq("user_id", userId)
    .eq("semester_id", semesterId)
    .order("deadline", { ascending: true });

  if (error) {
    console.error("TASK ERROR:", error);
    return { urgent: [], pending: [], completed: [], all: [] };
  }

  const tasks = data || [];
  console.log("FETCHED TASKS:", tasks.length);

  return {
    urgent: tasks.filter((t) => {
      const p = (t.priority || "").toLowerCase();
      return t.status !== "completed" && (p === "high" || calculatePriority(t) >= 3);
    }),
    pending: tasks.filter((t) => {
      const p = (t.priority || "").toLowerCase();
      return t.status !== "completed" && t.is_completed !== true && !(p === "high" || calculatePriority(t) >= 3);
    }),
    completed: tasks.filter((t) => t.status === "completed" || t.is_completed === true),
    all: tasks
  };
}

// -----------------------------
// STUDY ANALYTICS (mirrors app AnalyticsRepository logic)
// -----------------------------
async function getStudyAnalytics(supabase: any, userId: string, semesterId: string) {
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7));
  startOfWeek.setHours(0, 0, 0, 0);
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 7);
  const todayStart = new Date(now);
  todayStart.setHours(0, 0, 0, 0);

  const { data: sessions } = await supabase
    .from("study_sessions")
    .select("duration_minutes, created_at, course_id")
    .eq("user_id", userId)
    .eq("semester_id", semesterId);

  const allSessions = sessions || [];

  const thisWeekSessions = allSessions.filter(
    (s: any) => new Date(s.created_at) >= startOfWeek && new Date(s.created_at) < endOfWeek
  );
  const thisWeekMinutes = thisWeekSessions.reduce(
    (sum: number, s: any) => sum + (s.duration_minutes || 0), 0
  );
  const thisWeekHours = thisWeekMinutes / 60.0;

  // Consistency: distinct days with sessions in last 7 days
  const last7Days = new Date(now);
  last7Days.setDate(now.getDate() - 7);
  const sessionDays = new Set(
    allSessions
      .filter((s: any) => new Date(s.created_at) >= last7Days)
      .map((s: any) => new Date(s.created_at).toISOString().split("T")[0])
  );
  const consistency = Math.min(sessionDays.size / 7.0, 1.0);

  // Study goal from semester
  const { data: semData } = await supabase
    .from("semesters")
    .select("weekly_study_goal, start_date, end_date, created_at")
    .eq("id", semesterId)
    .maybeSingle();

  const studyGoal = semData?.weekly_study_goal || 15;
  const studyDeficit = Math.max(0, studyGoal - thisWeekHours);

  // Weekly average across semester
  let weeklyAvg = 0;
  if (semData) {
    const start = new Date(semData.start_date || semData.created_at);
    const end = semData.end_date ? new Date(semData.end_date) : now;
    const weeks = Math.max(1, (end.getTime() - start.getTime()) / (7 * 24 * 60 * 60 * 1000));
    const totalHours = allSessions.reduce(
      (sum: number, s: any) => sum + (s.duration_minutes || 0) / 60.0, 0
    );
    weeklyAvg = totalHours / weeks;
  }

  return {
    thisWeekHours,
    studyGoal,
    studyDeficit,
    consistency,
    weeklyAvg,
    totalSessions: allSessions.length,
  };
}

// -----------------------------
// PREMIUM EMAIL
// -----------------------------
function buildTasksEmailInner(groups: any) {
  const hasUrgent = groups.urgent.length > 0;
  const hasPending = groups.pending.length > 0;
  const hasCompleted = groups.completed.length > 0;

  let summary = "";
  if (hasUrgent) summary += `<span style="color:#ef4444;font-weight:bold;">${groups.urgent.length} urgent</span>`;
  if (hasPending) summary += `${summary ? " and " : ""}<span style="color:#60a5fa;font-weight:bold;">${groups.pending.length} upcoming</span>`;
  if (!summary) summary = "You're all caught up";

  const nextAction = hasUrgent
    ? `Start with: ${groups.urgent[0].title}`
    : hasPending
      ? `Next up: ${groups.pending[0].title}`
      : "Keep going";

  const render = (title: string, list: any[], color: string) =>
    list.length
      ? `<h3 style="color:${color}">${title}</h3>` +
        list.map(t => `<p>${t.title} - ${t.deadline || "No date"}</p>`).join("")
      : "";

  return `<p>${summary}</p>
    ${render("Urgent", groups.urgent, "#ef4444")}
    ${render("Upcoming", groups.pending, "#60a5fa")}
    ${render("Completed", groups.completed, "#22c55e")}
    <p style="margin-top:20px">${nextAction}</p>`;
}

function buildTasksEmail(userName: string, groups: any) {
  return `
  <div style="background:#0f172a;color:white;padding:20px;border-radius:16px">
    <h2>Hi ${userName}</h2>
    ${buildTasksEmailInner(groups)}
  </div>
  `;
}

function escapeHtml(s: string) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function emailShell(title: string, userName: string, inner: string) {
  return `<div style="background:#0f172a;color:#e2e8f0;padding:24px;border-radius:16px;font-family:system-ui,sans-serif;max-width:560px">
    <h2 style="color:#fff;margin:0 0 8px">${escapeHtml(title)}</h2>
    <p style="color:#94a3b8;margin:0 0 16px">Hi ${escapeHtml(userName)}</p>
    ${inner}
    <p style="margin-top:24px;font-size:12px;color:#64748b">Sent from Acadia</p>
  </div>`;
}

function userWantsEmailDelivery(lower: string): boolean {
  if (/\bemail\s+me\b/.test(lower)) return true;
  const targetsEmail =
    lower.includes("email") || lower.includes("e-mail") || lower.includes("inbox");
  if (targetsEmail && /\b(send|forward|mail|deliver|shoot|push)\b/.test(lower)) return true;
  if (/\b(send|mail)\s+this\b/.test(lower) || /\bmail\s+this\b/.test(lower)) return true;
  if (
    /\bto\s+(my\s+)?(email|e-?mail|inbox)\b/.test(lower) &&
    /\b(send|forward|mail|get)\b/.test(lower)
  )
    return true;
  return false;
}

type EmailKind =
  | "risk"
  | "tasks"
  | "summary"
  | "deadlines"
  | "courses"
  | "profile"
  | "focus"
  | "last_reply"
  | "bundle";

function detectEmailKind(lower: string, context: any): EmailKind {
  if (
    /\b(risk|at[- ]risk|academic risk|risk score)\b/.test(lower) ||
    (/\b(send|email)\b/.test(lower) && /\b(burnout|struggling)\b/.test(lower))
  ) {
    return "risk";
  }
  if (/\b(deadline|due dates?)\b/.test(lower)) return "deadlines";
  if (/\b(courses?|my classes|classes)\b/.test(lower)) return "courses";
  if (/\b(profile|my profile|who am i)\b/.test(lower)) return "profile";
  if (/\b(focus|next task|what to do first)\b/.test(lower)) return "focus";
  if (/\b(task|todo|assignment|study plan)\b/.test(lower)) return "tasks";
  if (
    /\b(summary|progress|stats|how am i|dashboard|recap|performance)\b/.test(lower)
  ) {
    return "summary";
  }
  const refPrev =
    /\b(this|that|it|above|last (message|reply)?|what you (said|wrote)|your (last|previous) (message|reply))\b/.test(
      lower,
    );
  if (refPrev && context?.lastAssistantText) return "last_reply";
  return "bundle";
}

function summaryDataToHtml(d: any) {
  return `<ul style="line-height:1.7">
    <li>Tasks: ${d.completed} completed of ${d.total} total</li>
    <li>This week: ${d.weeklyCompleted} / ${d.weeklyTotal} tasks (${d.completionRate}%)</li>
    <li>Study this week: ${d.hours}h (goal ${d.studyGoal}h, deficit ${d.studyDeficit}h)</li>
    <li>Weekly average: ${d.weeklyAvg}h</li>
    <li>Consistency: ${d.consistency}%</li>
    <li>Overdue tasks: ${d.overdue}</li>
  </ul>`;
}

async function computeSummaryData(supabase: any, userId: string, semesterId: string | null) {
  if (!semesterId) return null;
  const summaryTasks = await getTasks(supabase, userId, semesterId);
  const total = summaryTasks.all.length;
  const completed = summaryTasks.completed.length;
  const studyStats = await getStudyAnalytics(supabase, userId, semesterId);

  const sumNow = new Date();
  const sumWeekStart = new Date(sumNow);
  sumWeekStart.setDate(sumNow.getDate() - ((sumNow.getDay() + 6) % 7));
  sumWeekStart.setHours(0, 0, 0, 0);
  const sumEndOfWeek = new Date(sumWeekStart);
  sumEndOfWeek.setDate(sumWeekStart.getDate() + 7);
  const sumTodayStart = new Date(sumNow);
  sumTodayStart.setHours(0, 0, 0, 0);

  const sumWeeklyTasks = summaryTasks.all.filter((t: any) => {
    if (!t.deadline) return false;
    const taskDate = new Date(t.deadline);
    return taskDate >= sumWeekStart && taskDate < sumEndOfWeek;
  });
  const sumWeeklyCompleted = sumWeeklyTasks.filter((t: any) => t.status === "completed").length;
  const sumWeeklyTotal = sumWeeklyTasks.length;
  const sumCompletionRate = sumWeeklyTotal === 0 ? 0 : (sumWeeklyCompleted / sumWeeklyTotal) * 100;

  const sumOverdue = summaryTasks.all.filter((t: any) => {
    if (t.status === "completed") return false;
    if (!t.deadline) return false;
    return new Date(t.deadline) < sumTodayStart;
  }).length;

  const data = {
    total,
    completed,
    weeklyTotal: sumWeeklyTotal,
    weeklyCompleted: sumWeeklyCompleted,
    completionRate: sumCompletionRate.toFixed(1),
    hours: studyStats.thisWeekHours.toFixed(1),
    weeklyAvg: studyStats.weeklyAvg.toFixed(1),
    studyGoal: studyStats.studyGoal,
    studyDeficit: studyStats.studyDeficit.toFixed(1),
    consistency: (studyStats.consistency * 100).toFixed(0),
    overdue: sumOverdue,
  };

  const reply =
    total === 0
      ? "You don't have any tasks yet."
      : `You've completed ${sumWeeklyCompleted} out of ${sumWeeklyTotal} tasks this week (${sumCompletionRate.toFixed(0)}%). You've studied ${studyStats.thisWeekHours.toFixed(1)}h this week (goal: ${studyStats.studyGoal}h).${sumOverdue > 0 ? ` ${sumOverdue} task${sumOverdue > 1 ? "s are" : " is"} overdue.` : ""}`;

  return { data, reply };
}

function emailSentLabel(kind: EmailKind): string {
  switch (kind) {
    case "risk":
      return "I've sent your academic risk assessment to your email. Check spam if you don't see it within a minute.";
    case "tasks":
      return "I've sent your tasks to your email. Check spam if you don't see it within a minute.";
    case "summary":
      return "I've sent your study summary to your email. Check spam if you don't see it within a minute.";
    case "deadlines":
      return "I've sent your deadlines to your email. Check spam if you don't see it within a minute.";
    case "courses":
      return "I've sent your courses to your email. Check spam if you don't see it within a minute.";
    case "profile":
      return "I've sent your profile to your email. Check spam if you don't see it within a minute.";
    case "focus":
      return "I've sent your focus task to your email. Check spam if you don't see it within a minute.";
    case "last_reply":
      return "I've sent that message to your email. Check spam if you don't see it within a minute.";
    default:
      return "I've sent an overview to your email. Check spam if you don't see it within a minute.";
  }
}

// -----------------------------
// AI HELPER
// -----------------------------
async function aiDetectIntent(client: OpenAI, model: string, messages: any[]) {
  try {
    const res = await client.chat.completions.create({
      model,
      messages: [
        {
          role: "system",
          content:
            "Classify user intent: tasks, deadlines, summary, focus, email, profile, courses, details, or chat. Return ONE word.",
        },
        ...messages,
      ],
    });

    const text = res.choices[0].message.content.toLowerCase();

    if (text.includes("details") || text.includes("info")) return "get_details";
    if (text.includes("summarize") || text.includes("explain")) return "summarize_last";
    if (text.includes("task")) return "get_tasks";
    if (text.includes("deadline")) return "get_deadlines";
    if (text.includes("summary")) return "get_summary";
    if (text.includes("focus")) return "get_focus";
    if (text.includes("email")) return "email_tasks";
    if (text.includes("profile")) return "get_profile";
    if (text.includes("course")) return "get_courses";

    return "ai";
  } catch {
    return "ai";
  }
}

// -----------------------------
// NATURAL CHAT
// -----------------------------
async function aiReply(client: OpenAI, model: string, messages: any[], contextData: any) {
  try {
    const systemPrompt = contextData
      ? `You are Acadia, a helpful academic assistant. You have full access to the student's real-time academic data below. Use these exact numbers when answering questions - never make up data.

STUDENT DATA:
- Study this week: ${contextData.studyHours}h (Goal: ${contextData.studyGoal}h)
- Study deficit: ${contextData.studyDeficit}h
- Weekly average: ${contextData.weeklyAvg}h
- Consistency: ${(contextData.consistency * 100).toFixed(0)}%
- Tasks: ${contextData.completedTasks} completed / ${contextData.totalTasks} total (this week: ${contextData.weeklyCompleted}/${contextData.weeklyTotal})
- Overdue tasks: ${contextData.overdue}
- Completion rate (weekly): ${contextData.completionRate}%

Speak naturally like a real human. Always use the data above to give precise answers.`
      : "You are Acadia, a helpful academic assistant. Speak naturally like a real human. You have full access to structured academic data. You can summarize, analyze, prioritize, and explain in detail. Always use the data provided to give precise answers.";

    const res = await client.chat.completions.create({
      model,
      messages: [
        { role: "system", content: systemPrompt },
        ...messages,
      ],
    });
    return res.choices[0].message.content;
  } catch {
    return "I didn't quite get that. Could you rephrase, or ask about your tasks and deadlines?";
  }
}

// -----------------------------
// MAIN
// -----------------------------
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { messages, semesterId, context: clientContext, moodContext } = await req.json();

    const token = req.headers.get("Authorization")?.split(" ")[1];
    const { data: { user } } = await supabase.auth.getUser(token);

    if (!user) {
      return new Response("Unauthorized", { status: 401 });
    }

    const { data: profile } = await supabase
      .from("student_profiles")
      .select("full_name, active_semester_id")
      .eq("user_id", user.id)
      .maybeSingle();

    const resolvedSemesterId =
      semesterId || profile?.active_semester_id;

    const client = new OpenAI({
      apiKey: Deno.env.get("NVIDIA_API_KEY"),
      baseURL: "https://integrate.api.nvidia.com/v1",
    });

    const model = Deno.env.get("NVIDIA_MODEL");

    const lastMessage = messages[messages.length - 1].content;
    const lower = lastMessage.toLowerCase().trim();

    console.log("User Message:", lastMessage);

    // 1. Pre-Detection (Hard Routing for critical terms)
    // Email first — avoids "email my summary" being swallowed by get_summary.
    let intent: Intent = "ai";
    if (userWantsEmailDelivery(lower)) {
      intent = "email_tasks";
    } else if (lower.includes("summary") || lower.includes("summarize") || lower.includes("progress") || lower.includes("how am i doing")) {
      intent = "get_summary";
    } else if (lower.includes("focus") && (lower.includes("now") || lower.includes("right now"))) {
      intent = "get_focus";
    }

    // 2. AI Intelligence Layer (if not hard-routed)
    if (intent === "ai") {
      intent = await aiDetectIntent(client, model, messages);
      console.log("AI Detected Intent:", intent);
    }

    // 3. Fallback Safety Layer
    if (intent === "ai") {
      intent = resolveIntent(lastMessage, clientContext);
      console.log("Fallback Intent:", intent);
    }

    console.log("Final Intent Applied:", intent);

    // -----------------------------
    // EXECUTION
    // -----------------------------
    let responseData: any = null;
    let responseType = "text";
    let reply = "";

    switch (intent) {
      case "get_tasks":
        responseData = await getTasks(supabase, user.id, resolvedSemesterId);
        responseType = "tasks";
        const totalTasksCount = responseData.all.length;
        reply =
          totalTasksCount === 0
            ? "You don't have any tasks yet."
            : `You have ${totalTasksCount} tasks. ${
                responseData.urgent.length > 0
                  ? "Start with " + responseData.urgent[0].title
                  : "You're doing well. Keep going."
              }`;
        break;

      case "get_deadlines":
        console.log("SEMESTER USED:", resolvedSemesterId);
        const { data: d, error: dErr } = await supabase
          .from("academic_deadlines")
          .select(`
            id,
            title,
            deadline_date,
            deadline_type,
            priority,
            notes,
            course_id,
            is_completed,
            semester_id
          `)
          .eq("user_id", user.id)
          .eq("semester_id", resolvedSemesterId || profile?.active_semester_id)
          .order("deadline_date", { ascending: true });

        if (dErr) console.error("DEADLINE ERROR:", dErr);
        responseData = d || [];

        if (!responseData.length) {
          const { data: allDeadlines } = await supabase
            .from("academic_deadlines")
            .select("*")
            .eq("user_id", user.id);
          console.log("ALL DEADLINES (NO FILTER):", allDeadlines);
        }

        responseType = "deadlines";
        reply = responseData.length ? `You have ${responseData.length} upcoming deadlines.` : "No deadlines found for this semester.";
        break;

      case "get_summary": {
        const sum = await computeSummaryData(supabase, user.id, resolvedSemesterId);
        if (!sum) {
          responseType = "text";
          reply = "Select an active semester first to see your summary.";
          break;
        }
        responseData = sum.data;
        responseType = "summary";
        reply = sum.reply;
        break;
      }

      case "get_focus":
        const t = await getTasks(supabase, user.id, resolvedSemesterId);
        responseData = t.urgent[0] || t.pending[0] || null;
        responseType = "focus";
        reply = responseData ? `Focus on ${responseData.title} right now.` : "No urgent tasks. Want to plan your week?";
        break;

      case "email_tasks": {
        const apiKey = Deno.env.get("RESEND_API_KEY")?.trim();
        if (!apiKey) {
          reply =
            "Email is not configured: add the RESEND_API_KEY secret to the acadia-ai Edge Function in the Supabase dashboard, redeploy the function, then try again.";
          responseType = "text";
          break;
        }

        const toAddr = (user.email ?? "").trim();
        if (!toAddr) {
          reply = "Your account has no email address. Add one in your auth provider or profile, then try again.";
          responseType = "text";
          break;
        }

        const fromRaw = Deno.env.get("RESEND_FROM")?.trim();
        if (!fromRaw) {
          reply =
            "Email sender is not configured: set the RESEND_FROM secret for the acadia-ai function (e.g. Acadia <noreply@nouradin.com> — same verified address as in Resend / your .env for local serve).";
          responseType = "text";
          break;
        }

        const kind = detectEmailKind(lower, clientContext);
        const needsSemester = !["risk", "profile", "last_reply"].includes(kind);
        if (needsSemester && !resolvedSemesterId) {
          reply = "Select an active semester first, then I can email that for you.";
          responseType = "text";
          break;
        }

        const displayName = profile?.full_name || "Student";
        const fromHeader = fromRaw.includes("<") ? fromRaw : `Acadia <${fromRaw}>`;
        const mood = moodContext && typeof moodContext === "object" ? moodContext : {};
        let subject = "Your Acadia update";
        let html = "";
        let preSendError: string | null = null;

        if (kind === "risk") {
          const d = mood.riskDetail;
          if (!d || typeof d.score !== "number") {
            preSendError =
              "I couldn’t include your risk in the email. Open the app home screen so your risk updates, then try again.";
          } else {
            subject = "Your Acadia academic risk";
            html = emailShell(
              "Academic risk",
              displayName,
              `<p style="font-size:28px;font-weight:700;margin:0;color:#f8fafc">${Number(d.score).toFixed(1)}<span style="font-size:14px">/100</span></p>
              <p>Level: <strong>${escapeHtml(String(d.level ?? ""))}</strong></p>
              <ul style="line-height:1.7">
                <li>Overdue tasks: ${d.overdueTasks ?? "—"}</li>
                <li>Due soon: ${d.upcomingTasks ?? "—"}</li>
                <li>Study deficit: ${
  typeof d.studyDeficit === "number" ? d.studyDeficit.toFixed(1) + "h" : "—"
}</li>
                <li>Session stress: ${
  typeof d.avgSessionStress === "number" ? d.avgSessionStress.toFixed(1) : "—"
}</li>
                <li>Task completion: ${
  typeof d.consistency === "number" ? (d.consistency * 100).toFixed(0) + "%" : "—"
}</li>
                ${
  d.trendDelta != null
    ? `<li>Trend: ${d.trendDelta > 0 ? "+" : ""}${d.trendDelta}</li>`
    : ""
}
              </ul>`,
            );
          }
        } else if (kind === "last_reply") {
          const text = (clientContext?.lastAssistantText || "").trim();
          if (!text) {
            preSendError =
              "I don’t have a previous assistant message to email. Ask something first, then say “send that to my email.”";
          } else {
            subject = "Your Acadia assistant message";
            html = emailShell(
              "Message from Acadia",
              displayName,
              `<div style="white-space:pre-wrap;line-height:1.6">${escapeHtml(text)}</div>`,
            );
          }
        } else if (kind === "profile") {
          const { data: prof, error: pe } = await supabase
            .from("student_profiles")
            .select("*")
            .eq("user_id", user.id)
            .maybeSingle();
          if (pe || !prof) {
            preSendError = "Couldn’t load your profile.";
          } else {
            subject = "Your Acadia profile";
            html = emailShell(
              "Profile",
              displayName,
              `<pre style="white-space:pre-wrap;font-size:13px;color:#cbd5e1">${
  escapeHtml(JSON.stringify(prof, null, 2))
}</pre>`,
            );
          }
        } else if (kind === "courses") {
          const { data: courses } = await supabase
            .from("courses")
            .select("*")
            .eq("user_id", user.id)
            .eq("semester_id", resolvedSemesterId);
          const list = courses || [];
          subject = "Your Acadia courses";
          html = emailShell(
            "Courses",
            displayName,
            list.length === 0
              ? "<p>No courses for this semester.</p>"
              : `<ul style="line-height:1.7">${
  list
    .map(
      (c: any) =>
        `<li><strong>${escapeHtml(c.title || "Course")}</strong>${
          c.code ? ` (${escapeHtml(String(c.code))})` : ""
        }</li>`,
    )
    .join("")
}</ul>`,
          );
        } else if (kind === "deadlines") {
          const { data: dlines } = await supabase
            .from("academic_deadlines")
            .select("id,title,deadline_date,deadline_type,priority,notes")
            .eq("user_id", user.id)
            .eq("semester_id", resolvedSemesterId)
            .order("deadline_date", { ascending: true });
          const list = dlines || [];
          subject = "Your Acadia deadlines";
          html = emailShell(
            "Deadlines",
            displayName,
            list.length === 0
              ? "<p>No deadlines for this semester.</p>"
              : `<ul style="line-height:1.7">${
  list
    .map((d: any) =>
      `<li>${escapeHtml(d.title)} — ${escapeHtml(String(d.deadline_date || "?"))}</li>`
    )
    .join("")
}</ul>`,
          );
        } else if (kind === "focus") {
          const t = await getTasks(supabase, user.id, resolvedSemesterId);
          const focusTask = t.urgent[0] || t.pending[0] || null;
          subject = "Your Acadia focus task";
          html = emailShell(
            "Focus",
            displayName,
            focusTask
              ? `<p><strong>${escapeHtml(focusTask.title)}</strong></p><p>Deadline: ${
  escapeHtml(String(focusTask.deadline || "—"))
}</p>`
              : "<p>No urgent or upcoming tasks.</p>",
          );
        } else if (kind === "summary") {
          const sum = await computeSummaryData(supabase, user.id, resolvedSemesterId);
          if (!sum) {
            preSendError = "Couldn’t build your summary.";
          } else {
            subject = "Your Acadia study summary";
            html = emailShell("Study summary", displayName, summaryDataToHtml(sum.data));
          }
        } else if (kind === "tasks") {
          let emailPayload: any = clientContext?.lastData;
          const looksLikeTaskGroups =
            emailPayload &&
            typeof emailPayload === "object" &&
            Array.isArray(emailPayload.urgent) &&
            Array.isArray(emailPayload.pending) &&
            Array.isArray(emailPayload.completed);
          if (!looksLikeTaskGroups) {
            emailPayload = await getTasks(supabase, user.id, resolvedSemesterId);
          }
          subject = "Your Acadia study plan";
          html = buildTasksEmail(displayName, emailPayload);
        } else {
          const sum = await computeSummaryData(supabase, user.id, resolvedSemesterId);
          const tasks = await getTasks(supabase, user.id, resolvedSemesterId);
          subject = "Your Acadia overview";
          html = `<div style="background:#0f172a;color:#e2e8f0;padding:24px;border-radius:16px;font-family:system-ui,sans-serif;max-width:560px">
            <h2 style="color:#fff;margin:0 0 8px">Your overview</h2>
            <p style="color:#94a3b8;margin:0 0 16px">Hi ${escapeHtml(displayName)}</p>
            ${
  sum
    ? `<h3 style="color:#94a3b8;font-size:14px;margin:0 0 8px">Summary</h3>${summaryDataToHtml(sum.data)}`
    : "<p>Summary unavailable.</p>"
}
            <h3 style="color:#94a3b8;font-size:14px;margin:16px 0 8px">Tasks</h3>
            ${buildTasksEmailInner(tasks)}
            <p style="margin-top:24px;font-size:12px;color:#64748b">Sent from Acadia</p>
          </div>`;
        }

        if (preSendError) {
          reply = preSendError;
          responseType = "text";
          break;
        }

        if (!html) {
          reply = "Nothing to send — try rephrasing what you want emailed.";
          responseType = "text";
          break;
        }

        const resend = new Resend(apiKey);
        const { error: sendErr } = await resend.emails.send({
          from: fromHeader,
          to: [toAddr],
          subject,
          html,
        });

        if (sendErr) {
          console.error("RESEND_ERROR:", sendErr);
          const hint =
            sendErr.message?.includes("verify") || sendErr.message?.includes("domain")
              ? " Set the RESEND_FROM secret to a sender from a domain you verified in Resend (see https://resend.com/docs)."
              : "";
          reply = `Email could not be sent: ${sendErr.message ?? JSON.stringify(sendErr)}.${hint}`;
          responseType = "text";
          break;
        }

        reply = emailSentLabel(kind);
        break;
      }

      case "get_profile":
        const { data: p } = await supabase
          .from("student_profiles")
          .select("*")
          .eq("user_id", user.id)
          .single();
        responseData = p;
        responseType = "profile";
        reply = "Here is your academic profile.";
        break;

      case "get_courses":
        const { data: c } = await supabase
          .from("courses")
          .select("*")
          .eq("user_id", user.id)
          .eq("semester_id", resolvedSemesterId);
        responseData = c || [];
        responseType = "courses";
        reply = responseData.length ? `Here are your ${responseData.length} courses.` : "No courses found for this semester.";
        break;

      case "get_details":
        responseData = clientContext?.lastData;
        responseType = "details";
        reply = responseData ? "Here are the full details you requested." : "I don't have any recent data to show details for.";
        break;

      case "summarize_last":
        if (!clientContext?.lastData) {
          reply = "I don't have any recent data to summarize. What would you like me to look up first?";
          break;
        }
        const summaryResp = await client.chat.completions.create({
          model,
          messages: [
            {
              role: "system",
              content: "Summarize this academic data clearly and concisely. Focus on what matters to a student."
            },
            {
              role: "user",
              content: JSON.stringify(clientContext.lastData)
            }
          ]
        });
        reply = summaryResp.choices[0].message.content;
        break;

      case "ai":
        // Build real context data for the LLM so it uses correct numbers
        const aiStudyStats = await getStudyAnalytics(supabase, user.id, resolvedSemesterId);
        const aiTasks = await getTasks(supabase, user.id, resolvedSemesterId);

        const aiNow = new Date();
        const aiWeekStart = new Date(aiNow);
        aiWeekStart.setDate(aiNow.getDate() - ((aiNow.getDay() + 6) % 7));
        aiWeekStart.setHours(0, 0, 0, 0);
        const aiEndOfWeek = new Date(aiWeekStart);
        aiEndOfWeek.setDate(aiWeekStart.getDate() + 7);
        const aiTodayStart = new Date(aiNow);
        aiTodayStart.setHours(0, 0, 0, 0);

        const aiWeeklyTasks = aiTasks.all.filter((tk: any) => {
          if (!tk.deadline) return false;
          const dd = new Date(tk.deadline);
          return dd >= aiWeekStart && dd < aiEndOfWeek;
        });
        const aiWeeklyCompleted = aiWeeklyTasks.filter((tk: any) => tk.status === "completed").length;
        const aiOverdue = aiTasks.all.filter((tk: any) => {
          if (tk.status === "completed") return false;
          if (!tk.deadline) return false;
          return new Date(tk.deadline) < aiTodayStart;
        }).length;
        const aiCompletionRate = aiWeeklyTasks.length === 0 ? 0 : ((aiWeeklyCompleted / aiWeeklyTasks.length) * 100);

        const contextData = {
          studyHours: aiStudyStats.thisWeekHours.toFixed(1),
          studyGoal: aiStudyStats.studyGoal,
          studyDeficit: aiStudyStats.studyDeficit.toFixed(1),
          weeklyAvg: aiStudyStats.weeklyAvg.toFixed(1),
          consistency: aiStudyStats.consistency,
          totalTasks: aiTasks.all.length,
          completedTasks: aiTasks.completed.length,
          weeklyTotal: aiWeeklyTasks.length,
          weeklyCompleted: aiWeeklyCompleted,
          overdue: aiOverdue,
          completionRate: aiCompletionRate.toFixed(1),
        };

        reply = await aiReply(client, model, messages, contextData);
        break;
    }

    if (responseData?.all) {
      console.log("TASKS RAW:", JSON.stringify(responseData.all, null, 2));
    }
    console.log("FINAL DATA LOG:", JSON.stringify(responseData, null, 2));

    return new Response(
      JSON.stringify({
        type: responseType,
        data: responseData,
        reply,
        context: {
          lastIntent: intent,
          lastData: responseData,
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
