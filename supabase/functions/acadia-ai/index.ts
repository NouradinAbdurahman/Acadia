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
// 🧠 INTENT (fallback only)
// -----------------------------
// -----------------------------
// 🧠 INTENT (fallback only)
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
// ⚡ PRIORITY ENGINE
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
// 📊 TASKS
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
// ✉️ PREMIUM EMAIL (YOUR VERSION)
// -----------------------------
function buildTasksEmail(userName: string, groups: any) {
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

  return `
  <div style="background:#0f172a;color:white;padding:20px;border-radius:16px">
    <h2>Hi ${userName}</h2>
    <p>${summary}</p>
    ${render("Urgent", groups.urgent, "#ef4444")}
    ${render("Upcoming", groups.pending, "#60a5fa")}
    ${render("Completed", groups.completed, "#22c55e")}
    <p style="margin-top:20px">${nextAction}</p>
  </div>
  `;
}

// -----------------------------
// 🤖 AI HELPER
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
// 💬 NATURAL CHAT
// -----------------------------
async function aiReply(client: OpenAI, model: string, messages: any[]) {
  try {
    const res = await client.chat.completions.create({
      model,
      messages: [
        {
          role: "system",
          content: "You are Acadia, a helpful academic assistant. Speak naturally like a real human. You have full access to structured academic data. You can summarize, analyze, prioritize, and explain in detail. Always use the data provided to give precise answers.",
        },
        ...messages,
      ],
    });
    return res.choices[0].message.content;
  } catch {
    return "I didn't quite get that. Could you rephrase, or ask about your tasks and deadlines?";
  }
}

// -----------------------------
// 🚀 MAIN
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

    const { messages, semesterId, context } = await req.json();

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
    let intent: Intent = "ai";
    if (lower.includes("summary") || lower.includes("summarize") || lower.includes("progress") || lower.includes("how am i doing")) {
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
      intent = resolveIntent(lastMessage, context);
      console.log("Fallback Intent:", intent);
    }

    console.log("Final Intent Applied:", intent);

    // -----------------------------
    // ⚙️ EXECUTION
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
            ? "You don’t have any tasks yet."
            : `You have ${totalTasksCount} tasks. ${
                responseData.urgent.length > 0
                  ? "Start with " + responseData.urgent[0].title
                  : "You’re doing well. Keep going."
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

      case "get_summary":
        const summaryTasks = await getTasks(supabase, user.id, resolvedSemesterId);
        const total = summaryTasks.all.length;
        const completed = summaryTasks.completed.length;
        responseData = {
          total,
          completed,
          hours: 12 
        };
        responseType = "summary";
        reply =
          total === 0
            ? "You don’t have any tasks yet."
            : `You’ve completed ${completed} out of ${total} tasks.`;
        break;

      case "get_focus":
        const t = await getTasks(supabase, user.id, resolvedSemesterId);
        responseData = t.urgent[0] || t.pending[0] || null;
        responseType = "focus";
        reply = responseData ? `Focus on ${responseData.title} right now.` : "No urgent tasks. Want to plan your week?";
        break;

      case "email_tasks":
        const emailData =
          context?.lastData || await getTasks(supabase, user.id, resolvedSemesterId);

        const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

        await resend.emails.send({
          from: "Acadia <ai@acadia.edu>",
          to: [user.email],
          subject: "Your Study Plan",
          html: buildTasksEmail(profile?.full_name || "Student", emailData),
        });

        reply = "I've sent your tasks to your email.";
        break;

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
        responseData = context?.lastData;
        responseType = "details";
        reply = responseData ? "Here are the full details you requested." : "I don't have any recent data to show details for.";
        break;

      case "summarize_last":
        if (!context?.lastData) {
          reply = "I don't have any recent data to summarize. What would you like me to look up first?";
          break;
        }
        const summary = await client.chat.completions.create({
          model,
          messages: [
            {
              role: "system",
              content: "Summarize this academic data clearly and concisely. Focus on what matters to a student."
            },
            {
              role: "user",
              content: JSON.stringify(context.lastData)
            }
          ]
        });
        reply = summary.choices[0].message.content;
        break;

      case "ai":
        reply = await aiReply(client, model, messages);
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