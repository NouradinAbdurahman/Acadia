# acadia-ai Edge Function

Tool-based AI assistant for academic questions.

## Environment

Use project root env and Supabase secrets (no function-local `.env`).

Required variables:

- `NVIDIA_API_KEY`
- `NVIDIA_MODEL` (default: `meta/llama-3.1-70b-instruct`)
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

**Email (`email_tasks` intent)** — required if students use “Send to email”:

- `RESEND_API_KEY` — from [Resend](https://resend.com) API keys
- `RESEND_FROM` — **required** verified sender (e.g. `Acadia <noreply@yourdomain.com>`). There is no default in code; set it in Supabase secrets and mirror it in project `.env` for `supabase functions serve --env-file .env`.

## Local run

```bash
supabase functions serve acadia-ai --env-file .env
```

## Secrets (production)

```bash
supabase secrets set NVIDIA_API_KEY=your_key
supabase secrets set NVIDIA_MODEL=meta/llama-3.1-70b-instruct
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
supabase secrets set RESEND_API_KEY=re_xxxx
# Optional — after verifying your domain in Resend:
# supabase secrets set RESEND_FROM="Acadia <notify@yourdomain.com>"
```

## Request body

```json
{
  "message": "Do I have tasks due tomorrow?"
}
```

## Response body

```json
{
  "reply": "You have 2 tasks due tomorrow...",
  "usedTools": ["get_tasks"]
}
```

## Unified analytics contract (migration Step 1)

Module **`unified_analytics.ts`** exports **`getUnifiedAnalytics(supabase, userId, semesterId)`**, returning one JSON object shared by future AI/email/UI parity work.

### Debug validation (Step 1 — no AI)

POST **`acadia-ai`** with body:

```json
{
  "debug": "get_unified_analytics",
  "semesterId": "<optional uuid; else uses student_profiles.active_semester_id>"
}
```

Same **Authorization: Bearer** as normal function calls. Response: `{ "debug": "get_unified_analytics", "unified": { ... } }`.

In **debug** Flutter builds, **Home** logs this next to `analyticsProvider` and `riskProvider` once per screen load (see `lib/screens/home/home_screen.dart`).

- **Not yet** replacing `computeSummaryData` / `getStudyAnalytics` inside the main chat path — that is Step 3 after numbers match.
- **`riskEngineCalculate`** mirrors **`lib/core/services/risk_engine.dart`** (same caps and weights).
- **Risk inputs** follow **`risk_provider`** semantics (task overdue / due-soon counts, rolling study deficit, session stress averages, task-completion consistency).
- **Study block** uses **UTC Monday** week boundaries for calendar metrics and exposes **both** calendar and rolling deficit fields so you can align the rest of the app without hiding today’s differences.
- **`burnoutScore`** is **`null`** until Flutter **`StudyAnalytics.burnoutScore`** is ported or computed server-side.
- **Deadlines** list: **`is_completed = false`** and **`deadline_date >=` today (UTC midnight)**.

Example (local serve, Deno):

```ts
import { getUnifiedAnalytics } from "./unified_analytics.ts";
// after createClient + auth:
const contract = await getUnifiedAnalytics(supabase, user.id, semesterId);
```

### HTTP 520 from Flutter `functions.invoke`

Usually means the Edge worker returned **no valid JSON body** (crash before `Response`, `JSON.stringify` threw — e.g. **BigInt** in a row — or the bundle failed to load).

This repo now:

- **`jsonResponse()`** stringifies with a **BigInt** replacer on success paths that use it (including **`debug: get_unified_analytics`**).
- **`get_unified_analytics`** loads **`unified_analytics.ts`** via **dynamic `import()`** and wraps failures in **JSON `{ error, message, stack }`** with status **500** so the client gets a parseable error instead of an empty 520.

After pulling changes, **`supabase functions deploy acadia-ai`** (or restart local `serve`). If you still see 520, check **Dashboard → Edge Functions → acadia-ai → Logs** for the real stack trace.
