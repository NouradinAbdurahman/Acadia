# Acadia

Acadia is a Flutter-based academic productivity app that helps students plan coursework, track deadlines, log study sessions, monitor mood and stress, and get AI-powered insights — all scoped to their active academic semester.

## Core Features

- **Authentication** — Email/password signup with OTP verification, password reset via OTP flow, Google + Apple OAuth (Supabase PKCE), auth rate limiting with exponential backoff
- **Multi-step onboarding** — Language selection, welcome carousel, academic profile wizard, mandatory first-semester creation before entering Home
- **Semester management** — Create/edit/delete semesters, set active semester as the app-wide data scope, weekly study goals per semester
- **Course management** — CRUD courses per semester with ECTS credits, color coding, and active/inactive status
- **Task and deadline planning** — Tasks with course/deadline linking, priority, estimated time; deadlines with type (assignment/exam/quiz/project), completion tracking
- **Exam schedule module** — Semester-scoped exam CRUD with types (midterm/final/quiz), list + calendar + detail flows, urgency summary on Home, and local reminder scheduling
- **Study timer** — Pomodoro (4-round cycle with breaks), Deep Work, and Review modes; audio/haptic feedback; Hive-persisted timer state across app restarts; app lifecycle recovery
- **Mood and stress tracking** — 5-level mood selector, stress/energy sliders, factor chips (sleep, workload, health, motivation, social, exams), optional notes; daily + post-session logging; configurable reminders
- **Analytics** — Study hours per course, semester GPA + cumulative GPA (CGPA), task completion rate, consistency, study deficit, burnout score, risk score, weekly/semester comparison
- **Decision engine** — Multi-factor scored priority (urgency 34%, deficit 24%, workload 16%, ECTS 16%, risk 10%) recommending which course to study and for how long
- **Risk scoring** — `riskProvider` builds `RiskInput` from live tasks, sessions, moods, deadlines, courses, and results; `RiskCalculator` feeds `RiskEngine` (overdue, due soon, study deficit, **session** stress, **task-completion** consistency — not the analytics “study-day” consistency metric)
- **AI assistant** — Regex intent parser → local answers use the **same Riverpod snapshots as the UI** (`analyticsProvider` for summaries/progress, `riskProvider` for academic risk so scores match Home/Analytics). Unknown intents → Supabase `acadia-ai` Edge Function (NVIDIA NIM) with server-side summary math aligned to the app’s week/study logic
- **Smart notifications** — Context-aware push alerts (overdue, deadline, risk, stress, batched academic summary) with anti-spam cooldowns, daily rate limits, behavior adaptation, night-time suppression, and background evaluation
- **Dashboard** — Greeting, mood card, study heatmap, live session card, tasks preview, GPA cards, semester comparison, smart insights, quick-action FAB
- **Profile and settings** — Avatar upload, academic profile editing, study preferences, mood settings, theme (light/dark/system), language (EN/TR), change password, and legal/compliance pages (Privacy Policy, Terms of Service, Data & Permissions, Contact/Support)
- **Supabase Realtime** — Live sync for tasks, deadlines, study sessions, course results, and courses with 250ms debounced provider invalidation

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart SDK ^3.10.4) |
| State Management | flutter_riverpod (StateNotifiers + Providers) |
| Routing | go_router (centralized with auth/profile guards) |
| Backend | Supabase (Auth + Postgres + Storage + Realtime + Edge Functions) |
| Push Notifications | Firebase Cloud Messaging |
| Local Storage | Hive (settings, theme, locale, timer state, burnout history) |
| Charts | fl_chart |
| Animations | Lottie, flutter_animate |
| Icons | Phosphor, Heroicons |
| Fonts | google_fonts |
| Localization | flutter_localizations + intl (English + Turkish, 500+ strings) |
| AI | NVIDIA NIM LLM (Llama 3.1 70B) via Supabase Edge Function |
| Background Work | Workmanager (Android) + BackgroundFetch (iOS) |

## Project Architecture

The app follows a layered architecture with strict single-responsibility boundaries:

```
UI (Screens / Widgets)
  ↓ watch / call
Providers (Riverpod StateNotifiers — state + orchestration)
  ↓ call
Repositories (JSON ↔ Model mapping, caching, rate limiting)
  ↓ delegate
Services (raw Supabase / FCM / Hive operations)
  ↓ query
Supabase (Postgres + Auth + Storage + Realtime + Edge Functions)
```

**Domain logic** lives in `lib/domain/` and `lib/core/services/` — pure business rules (RiskEngine, DecisionEngine, PredictionEngine) that are consumed by providers but never directly by UI.

### Provider Dependency Layers

```
Layer 1: Infrastructure   supabaseProvider → Services → Repositories
Layer 2: Auth & Identity  authStateProvider → currentUserProvider → currentAppUserProvider
Layer 3: Session/Profile  semesterProvider → activeSemesterProvider → studentProfileProvider
Layer 4: Core Data        courseProvider, tasksProvider, deadlinesProvider,
                           studySessionsProvider, courseResultsProvider, moodLogsProvider
Layer 5: Analytics        analyticsProvider → studyAnalyticsProvider, trendProvider, riskProvider
Layer 6: Intelligence     decisionProvider (V1 + V2), predictionProvider
Layer 7: UI Aggregation   dashboardProvider
```

`activeSemesterProvider` is the **keystone** — nearly all data providers are scoped to it.

## Folder Structure

```text
lib/
  main.dart                 # App bootstrap, Supabase/Firebase/Hive init, GoRouter with redirect guards
  components/               # Design primitives (AppButton, AppTextField, AppGlassCard, etc.)
  core/
    design/                 # Design tokens (spacing, radius, blur, durations, shadows, icons)
    services/               # RiskEngine, domain logic
    theme/                  # AppTheme (light + dark ThemeData)
    utils/                  # Shared utilities
  domain/
    decision/               # DecisionEngine, decision models
    prediction/             # PredictionEngine, prediction models
    risk/                   # RiskCalculator, risk models
    tasks/                  # Task validation helpers
    academic_deadline_task.dart
  l10n/                     # ARB files + generated AppLocalizations
  models/                   # 23 domain models (AppUser, Semester, Course, Task, Deadline,
                            #   StudySession, MoodLog, CourseResult, AnalyticsData, etc.)
  providers/                # 29 Riverpod provider files
    app_providers.dart      # Central service + repository registry
    analytics_provider.dart # Analytics computation engine (largest provider)
    study_sessions_provider.dart  # Study timer state machine
    ...
  repositories/             # 13 repositories (JSON ↔ Model mapping)
  screens/                  # 40 screens across 15 feature areas
    ai/                     # AI chat assistant
    analytics/              # Analytics tabs (Overview/GPA/Trends/Mood)
    app/                    # AppShell (5-tab IndexedStack) + liquid glass navbar
    auth/                   # Login, Signup, OTP verify, password reset
    courses/                # Course + semester CRUD, course results
    home/                   # Dashboard, quick menu, study heatmap widget
    language/               # Language selection
    mood/                   # Mood logging, mood history
    notifications/          # Notification inbox with deep links
    onboarding/             # Welcome carousel, academic profile wizard
    profile/                # Profile hub, edit profile, study prefs, change password
    settings/               # Mood tracking settings
    splash/                 # Splash screen
    study/                  # Study timer, session history, session detail
    tasks/                  # Task/deadline list, create/edit/detail screens
  services/
    ai/                     # AiIntentParser (regex NLU), AiDataResolver
    storage/                # AvatarService (Supabase Storage upload)
    supabase/               # 14 Supabase CRUD services
    notification_service.dart       # Local + FCM push delivery
    notification_config.dart        # Per-type config (cooldown, criticality)
    notification_behavior_service.dart  # Engagement tracking
    smart_notification_engine.dart  # Decides what to notify
    notification_intelligence_service.dart  # Unified facade
    background_notification_service.dart    # Mobile + stub for web/desktop
  theme/                    # AppColors (context-aware color accessors)
  utils/                    # GoRouterRefreshStream
  widgets/                  # Feature widgets (mood, analytics, risk, semester, settings)

assets/
  images/                   # Static images
  onboarding/               # Onboarding illustrations
  sounds/                   # Timer completion sound

supabase/
  schema.sql                # Base database schema
  2026031602_*.sql ...      # migration scripts (latest includes legacy weekly-goal cleanup)
  functions/
    acadia-ai/              # AI assistant Edge Function (Deno, NVIDIA NIM, Resend)
    send-push/              # FCM push notification Edge Function (Deno)

android/ ios/ macos/ web/ linux/ windows/   # Platform runners
```

## Database Schema

14 user-facing tables plus `auth.users`:

```text
auth.users
  ├── users (1:1, lightweight app user)
  ├── student_profiles (1:1, academic identity + active_semester_id)
  ├── semesters (1:N)
  │   ├── courses (1:N)
  │   ├── tasks (1:N, course_id + deadline_id FKs)
  │   ├── study_sessions (1:N, course_id FK)
  │   ├── academic_deadlines (1:N, course_id FK)
  │   ├── mood_logs (1:N)
  │   ├── notifications (1:N)
  │   └── course_results (1:N, course_id FK)
  │       └── course_result_components (1:N, result_id FK)
  ├── academic_calendar (1:N)
  ├── exams (1:N, course_id FK)
  ├── mood_settings (1:1)
  └── analytics (1:N, weekly snapshots)
```

**Key database features:**
- **Row Level Security (RLS)** on every table — `auth.uid() = user_id` policies
- **`save_course_result_with_components()`** — atomic upsert RPC for grades + components
- **`update_updated_at_column()`** trigger — auto-timestamps on `student_profiles` and `course_results`
- **Partial unique index** on `notifications(user_id, reference_id, type)` — deduplication
- **Semester isolation** — NOT NULL `semester_id` on tasks, deadlines, study sessions, mood logs, notifications, course results

## App Startup Flow

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp()` — FCM push notifications
3. `Hive.initFlutter()` + open `settings` box — local persistence
4. `dotenv.load(".env")` — Supabase/Auth/OAuth environment keys
5. `Supabase.initialize()` — Auth + DB + Realtime (`AuthFlowType.pkce`, `detectSessionInUri: true`)
6. `NotificationService.init()` — local notification channels, FCM permissions
7. `BackgroundNotificationService.initialize()` — periodic background worker (Android via Workmanager, iOS via BackgroundFetch)
8. `runApp(ProviderScope(child: MyApp()))` — Riverpod-wrapped app

## Routing and Auth Guards

Routing is centralized in `main.dart` using `go_router` with a redirect function enforcing this flow:

```
Splash → Language Selection → Onboarding → Login/Signup → Academic Onboarding → Onboarding Semester → Home
```

Guard logic (evaluated in order):
1. **Settings loading** — If locale/theme/onboarding haven't loaded from Hive → stay on `/splash`
2. **Not logged in** — No language → `/language`; onboarding incomplete → `/onboarding`; else → `/login`
3. **Logged in but profile loading** → stay on `/splash`
4. **Academic profile incomplete** → `/academic-onboarding`
5. **No active semester in `student_profiles.active_semester_id`** → `/onboarding-semester`
6. **All complete** → redirect auth/onboarding/language screens to `/home`

The router also watches `GoRouterRefreshStream` on Supabase auth state changes for auto-redirect on login/logout.

### 5-Tab App Shell

| Tab | Screen | Purpose |
|---|---|---|
| 0 | HomeScreen | Dashboard: greeting, mood card, heatmap, tasks preview, GPA, insights |
| 1 | TasksListScreen | Tasks & deadlines management (segmented view) |
| 2 | StudyScreen | Study timer + session history |
| 3 | AnalyticsScreen | 4-tab analytics (Overview/GPA/Trends/Mood) |
| 4 | ProfileScreen | Settings hub |

## Smart Notification System

Three layers working together with a single deterministic contract:

1. **WHEN to notify** (`SmartNotificationEngine`):
   - Overdue tasks → `overdue` notification (`reference_id: task:<taskId>`)
   - Due within 24h → `due_tomorrow` notification (`reference_id: task:<taskId>`)
   - Multiple items → batched `academic_summary` (`reference_id: academic_summary:<yyyy-mm-dd>`)
   - Risk score ≥ 70 → `risk` alert
   - Risk score 50–69 → moderate `risk` alert
   - Avg stress ≥ 7 → `stress` warning

2. **HOW to deliver** (`NotificationService`):
   - Anti-spam cooldown (4–24h per type)
   - Daily rate limit (max 5/day, max 2 high-priority)
   - Night-time suppression (7am–10pm only)
   - Behavior adaptation (ignore >3 → double cooldown; engage >50% → boost priority)
   - **Single write path**: `_writeInbox(...)` is the only inbox insert path (used by both enqueue/send flows)
   - **Semester-scoped writes**: every inbox insert includes `semester_id` from active semester
   - **Dual-channel delivery**: same event writes inbox and sends push/local notification in the same flow
   - Push bridge: `send-push` Edge Function sends FCM payload with `type` + `id` (`reference_id`) for deep links
   - Cold-start handling: terminated-app push taps are handled via `FirebaseMessaging.getInitialMessage()`

3. **BACKGROUND** (`BackgroundNotificationService`):
   - Runs every 30 min (Workmanager on Android, BackgroundFetch on iOS)
   - Fetches fresh data from Supabase → evaluates → sends if conditions met

### Notification Contract (single source of truth)

- **Allowed DB types** (constraint + app config aligned):
  - `deadline`, `deadline_batch`, `task_overdue`, `overdue`, `overdue_batch`
  - `study_goal`, `system`, `due_today`, `due_tomorrow`
  - `risk`, `stress`, `academic_summary`, `mood`, `mood_check`
- **Reference format**:
  - task-linked: `task:<id>`
  - deadline-linked: `deadline:<id>`
  - aggregate/time-keyed: `academic_summary:<date>`, `risk:<date>`, `stress:<date>`
- **Deduplication key**: `(user_id, reference_id, type)` partial unique index
- **Tap routing**:
  - `task:*` → task detail
  - `deadline:*` → deadline detail
  - `risk` / `stress` / `academic_summary` / `study_goal` → home
  - `mood*` → mood log if today not logged, otherwise mood history
  - fallback → tasks/home depending on payload

## AI Assistant

Two processing paths:

- **Local intent resolution** (fast, free): User message → `AiIntentParser` (regex NLU) → `AiDataResolver`. Tasks/deadlines still load from repositories; **study summary / progress** use the same `AnalyticsData` as `analyticsProvider` (not a separate DB path). **Academic risk** reuses `riskProvider`’s precomputed `RiskState` (same score and inputs as the Risk Breakdown card — e.g. session stress and task-completion %, not `AnalyticsData.consistency` which measures distinct study days).

- **LLM fallback** (cloud, paid): Unknown intent → Supabase Edge Function `acadia-ai` → NVIDIA NIM (Llama 3.1 70B). The function’s `get_summary` path computes real **this-week study hours** and **weekly task completion** from Postgres (no hardcoded placeholders); free-form `ai` chat receives a short numeric context block built the same way so answers stay close to in-app numbers.

Also on the Edge path: `email_tasks` (Resend), `get_focus`, `summarize_last`, `get_profile`, `get_courses`.

### Recent AI updates (May 2026)

- **Smart Planning (Step 1)** — Added deterministic weekly planning (`planWeek`) with round-robin session distribution, urgency boost for today, priority assignment for near-term deadlines, and empty-day suppression.
- **Priority Ranking (Step 2)** — Added deterministic `rankTasks` intent with scored top priorities across both pending tasks and unlinked deadlines (deduped), including due-date-aware output.
- **Focus Mode (Step 3)** — Added `focusNow` action flow that selects the top-ranked task, returns structured `focus_session` payload, and starts study sessions directly from chat/UI.
- **Explainability Layer (Step 4)** — Added deterministic reasons for task choice and session duration (`why this task`, `why this duration`) rendered in focus and planning surfaces.
- **Smart Daily Plan (Step 5)** — Added `planToday` with 2–4 executable sessions, time-slot labeling, 150-minute cap, deficit recovery block, and per-session start actions.
- **Adaptive Learning Layer (Step 6)** — Added behavior-aware duration adaptation using `AdaptiveProfile` (completion rate, actual/planned ratio, average actual minutes, consistency) and unified adaptive minutes across Home/Study/Analytics/Chat.
- **Risk + Burnout ownership unified** — Burnout now flows from analytics/unified data contracts into decision rules and assistant contexts; final recommendations consistently apply burnout-aware caps through a single final duration rule.
- **Truth-value parity fixed** — AI summary/progress uses the same `analyticsProvider` snapshot as UI; risk uses `riskProvider` `RiskState` values, so chat text/cards and Home/Analytics show the same score.
- **Unified AI decision layer finalized** — Home, Study, Analytics, and Chat all use `AcademicInsightInput` (`academic_insight_layer.dart` / `academic_insights.ts`) with the same rule order, trend-priority behavior, and two-line recommendation format.
- **Deterministic risk override locked** — resolver/debug/edge appendix generation now pins `riskScoreOverride` to the same analytics-aligned score source to prevent `31 vs 33` drift and remove consistency warnings caused by mixed risk sources.
- **Intent consistency hardened** — for task/deadline intents, when `analytics.hasData`, resolver always appends the unified insight block; fallback task-only heuristics are used only when analytics data is unavailable.
- **Analytics-task parity improved** — `AnalyticsRepository.computeFromPreloaded(...)` now accepts `deadlines` and merges task + deadline workload for weekly totals, due-soon, and overdue metrics so assistant and analytics scopes stay aligned.
- **Risk input parity improved** — `riskProvider` now includes `academic_deadlines` in overdue/upcoming computations and core-data readiness checks, reducing deadline-only semester mismatches.
- **AI UX hierarchy polished** — Home flow is now action-first (`PassiveAiHomeNudge`) → state (`RiskScoreCard`) → explanation (`AcademicAssistantInsightBlock`), with duplicate insight panels removed from key surfaces.
- **Flexible email sending** — phrases like “send this to email”, “email my risk/summary/deadlines/courses/profile” are routed to Edge email flow (not just tasks). Sender is required from env/secret: `RESEND_FROM` (no hardcoded fallback).
- **Exact time/month filtering** — local intent parsing now supports explicit month ranges (e.g. “in April”, “April 2026”) and resolver enforces exact date windows instead of broad matches.
- **Task fallback improved** — if `tasks` table has no items for a request, assistant falls back to `academic_deadlines` and still returns actionable task-like results.
- **Summary expanded** — summary now includes risk, deficit, due soon/overdue, stress values, and consistency in both text and summary card data payload.
- **AI chat UX updates** — keyboard dismisses on send, auto-scroll follows the latest content at bottom while typing, empty state layout is centered/responsive, added extra empty-state action button, header now supports minimize (down arrow) and “Close & Clear Chat”.
- **AI route animation** — opening/closing AI chat now uses a longer slide + fade transition; dismiss (minimize/close-clear) animates downward.
- **Localization hardening for deterministic insights** — moved deterministic insight/recommendation output to l10n-backed text paths and removed mixed hardcoded fallback behavior in the active insight flow.
- **Insight activation quality gates** — insight visibility and generation now require semester-scoped academic signal (`tasks`/`sessions`), with a minimum threshold (`>=2 tasks` or `>=2 sessions`) to avoid low-signal noisy output.
- **Home/Analytics consistency lock** — shared `hasAcademicData` + `hasEnoughSignal` gating is applied across Home insight card, Analytics insight card, and insight generation layer for parity.
- **Analytics fallback hint** — when insight is intentionally hidden due to missing study signal, Analytics shows a localized non-AI guidance hint instead of blank space.

### Recent product updates (May 2026)

- **Exam module completed** — added exam list/create/edit/detail screens, calendar view, exam-type color coding, countdowns, today/tomorrow formatting, and safer delete confirmations.
- **Exam reminders + inbox parity** — exam reminders now schedule reliably with timezone-safe handling, write to in-app notifications inbox, and deep-link to exam detail.
- **Semester strictness** — exam fetch/create/update paths and semester activation behavior were hardened to prevent cross-semester leakage and silent semester reversion.
- **Home dashboard reorder** — Home card flow was reordered to action-first and urgency-first sequencing (live session, exams/deadlines, risk, insight, analytics blocks, history, quick menu).
- **Section labeling polish** — added Home section labels for previously unlabeled cards (including Exams) and right-side “View” navigation on the Exams header to open `/exams`.
- **Legal/compliance layer completed** — added in-app Privacy Policy, Terms of Service, Data & Permissions, and Contact/Support screens with EN/TR localization and profile routing for publication readiness.
- **Legal content expansion + visual polish** — legal pages now include more explicit Acadia data-handling details (optional mood data, AI disclaimer, notifications scope, third-party infrastructure notes) and icon-based section cards for clearer readability.
- **Mood logic correctness hardening** — when mood tracking is disabled, mood data is excluded from analytics/risk/AI inputs; reminder toggle and time changes now schedule/cancel daily local reminders through the notifier path.
- **Settings/profile UX simplification** — Mood Settings UI was reduced to active controls only (tracking + mood history), and Profile Account navigation was cleaned to remove assistant duplication while exposing legal/support entries.
- **Academic history + grade math alignment** — GPA now uses credit-weighted calculation (`sum(gradePoint * credits) / sum(credits)`), CGPA is computed cumulatively across semesters, and both values are shown in Academic History and AI summary surfaces.
- **Home deadline consistency fixes** — Upcoming Deadlines now show linked-task progress (`completed / total`) and use the same day-normalized due-date math as Deadline Detail to avoid off-by-one day labels.
- **Home exams card interaction polish** — Exams urgency card now expands inline within the same parent border, and each expanded exam row is fully tappable (entire row area) to open exam details.
- **Notification inbox behavior hardening** — Added daily `mood_check` notification generation when mood tracking/reminders are enabled, category-specific empty states for Mood/Academic tabs, locale-change-driven notification reload, and mood notification tap routing (`/mood/log` if today is not logged, otherwise `/mood/history`).
- **Academic tab reliability** — Academic notification filtering now includes due/overdue academic workload signals and preserves historical academic notifications by narrowing duplicate-cleanup scope to noisy repeatable types only.
- **Mood tracking disabled UX system** — 7-point system that makes the tracking-off state fully transparent without hiding historical data: persistent info banners on Home and Analytics, "Tracking Off" pill badge on the mood history row, status text under the toggle in Mood Settings, toggle SnackBar confirmations (enabled/disabled), session-end SnackBar when tracking is off, and an always-visible mood history. Core rule: tracking OFF stops collecting NEW data but never erases or hides OLD data. Adds `moodTrackingOffSnackbarProvider` (`StateProvider<bool>`) and 10 new l10n keys.
- **Analytics tracking-coupling fix** — `analyticsProvider` no longer gates mood reads with `trackingEnabled`. Historical mood data is always passed to `AnalyticsData` regardless of tracking state. Tracking state only controls new data collection (prompts, reminders, session logging) — it must never gate reads, charts, averages, or AI inputs.
- **Notification dynamic UI translation** — Notification cards in `NotificationsScreen` are now translated at the UI layer using live provider data (`tasksProvider`, `deadlinesProvider`, `localeProvider`) instead of relying on static strings stored in the Supabase DB. Adds `_localizedTitle()`, `_localizedMessage()`, `_localizedContext()` helpers that resolve titles from task/deadline models and format dates with `DateFormat.MMMd(locale)`. Fixes a regression where cards would not translate even after manual pull-to-refresh when the app language changed.
- **Notification locale reload race-condition fix** — `NotificationsNotifier` now tracks `_pendingLocaleReload` to prevent the locale-change reload from being silently dropped when an initial load is already in flight. The pending reload is retried in the `finally` block after the in-flight load completes.
- **Notification write path unified** — All inbox inserts now go through a single `_writeInbox(...)` method. Removed duplicate write paths that caused the same notification to appear more than once. Every insert includes `semester_id` from the active semester. Deduplication key `(user_id, reference_id, type)` is enforced at the DB layer by a partial unique index, and the notification service now avoids inserting when an unexpired duplicate already exists.
- **Notification timing fix** — Scheduled local notifications (exam reminders, deadline alerts) were firing at the wrong time due to missing timezone offset correction. `FlutterTimezone.getLocalTimezone()` is now called before scheduling and all `tz.TZDateTime` conversions use the device's resolved timezone. Added a guard that skips scheduling for dates already in the past to prevent instant false-fires on app open.
- **Exams screen redesign** — Exam cards rebuilt from scratch: compact layout with 12 px internal padding, `_MetaChip` inline meta widgets (date, weight, course), 8 px card gap, no left color border, no inner divider. Edit and delete buttons removed from the card surface — they remain accessible in the detail screen. Filter tabs replaced with the same pill-tab design used in the Notifications screen: 36 px height, 18 px radius, 16 px horizontal padding, 13 px font, `theme.colorScheme.primary` for the selected state, and `BouncingScrollPhysics`.
- **Profile: Manage Exams entry** — "Manage Exams" nav item added to the Academic Information section of Profile screen (`HeroIcons.clipboardDocumentList`) linking to `/exams`.
- **In-app update prompt** — Integrated `upgrader` v11.4.0 (`UpgradeAlert` wrapping the app shell in `main.dart`). When a newer build is available on the App Store / Play Store, users see a native-style Cupertino dialog prompting them to update. Prompt re-appears every 24 h if dismissed. No changes required on the backend — version comparison is handled entirely by the `upgrader` package against the live store listing.
- **AppToast component** — Replaced all ~60 `ScaffoldMessenger.of(context).showSnackBar(...)` calls across 25 screen files with a shared `AppToast.show(context, message, type: AppToastType.xxx)` API (`lib/components/app_toast.dart`). The toast floats above the bottom navigation bar using a root `Overlay` entry (independent of `Scaffold`), features a glassmorphism blur background, a 3 px left accent pill, a tinted icon container, and a slide-up + fade entrance/exit animation (300 ms in, 180 ms out). Four variants: `success` (green), `error` (red), `warning` (orange), `info` (blue). Tap-to-dismiss supported.
- **Academic profile major field placeholder** — Added localized hint text to the Major field in the academic profile setup wizard. New l10n key `majorPlaceholder` (`"e.g. Computer Science"` / `"ör. Bilgisayar Mühendisliği"`) appears as `InputDecoration.hintText` when the field is empty. `_buildTextField` helper updated with an optional `hint` parameter.
- **Remember Me persistence fix** — Remembered email/password credentials stored in Hive (`settings` box) were being deleted on every logout. Fixed by removing `clearRememberedCredentials()` from the logout flow in `ProfileScreen`. Credentials are now only cleared when the user explicitly triggers **Delete Account** in Account Settings, which is the correct lifecycle point.

### Deploying AI changes

```bash
supabase functions deploy acadia-ai
```

## Study Timer

A full state machine managed by `StudyTimerProvider`:

```
IDLE → RUNNING ↔ PAUSED → COMPLETED
         ↕ (Pomodoro cycles: Focus → Break → Focus → ... 4 rounds)
```

- 3 session types: Pomodoro, Deep Work, Review
- Audio completion sound + haptic feedback
- Timer state persisted to Hive (survives app restarts)
- App lifecycle awareness (recovers from background)
- Auto-saves session to Supabase on completion
- Optionally queues a post-session mood prompt

## Environment Variables

Create a `.env` file in the project root. Copy from `.env.example`:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY
NVIDIA_API_KEY=YOUR_NVIDIA_API_KEY
NVIDIA_MODEL=meta/llama-3.1-70b-instruct
APP_ENV=development
API_TIMEOUT=10000
OAUTH_REDIRECT_URL=com.acadia.app://auth-callback
PASSWORD_RESET_REDIRECT_URL=com.acadia.app://reset-password
# Optional for Flutter web OAuth callback:
# WEB_OAUTH_REDIRECT_URL=https://your-deployed-app.example/
```

Required for startup:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OAUTH_REDIRECT_URL`
- `PASSWORD_RESET_REDIRECT_URL`

Required for AI assistant:
- `NVIDIA_API_KEY`
- `NVIDIA_MODEL`

Required for push notifications:
- Firebase project configured (google-services.json / GoogleService-Info.plist)

## Getting Started

### 1. Install Flutter and dependencies

```bash
flutter --version
flutter pub get
```

### 2. Configure environment

Create `.env` from `.env.example` and set your Supabase project values.

### 3. Configure Supabase database

Run the SQL files in the Supabase dashboard SQL editor, in this order:

1. `supabase/schema.sql`
2. `supabase/2026031602_academic_structure_updates.sql`
3. `supabase/2026031603_semester_structure.sql`
4. `supabase/2026031604_foundation_updates.sql`
5. `supabase/2026031605_foundation_hardening.sql`
6. `supabase/2026031606_profile_split_and_study_reflection.sql`
7. `supabase/2026031701_stability_patch.sql`
8. `supabase/2026031901_study_session_history_foundation.sql`
9. `supabase/2026031902_notifications_dynamic_types.sql`
10. `supabase/2026031903_notifications_reference_dedup.sql`
11. `supabase/2026033101_course_results_foundation.sql`
12. `supabase/2026033102_course_results_outcome_status.sql`
13. `supabase/2026033103_course_results_semester_fk.sql`
14. `supabase/2026033104_course_results_atomic_save.sql`
15. `supabase/2026033111_deadline_completion_status.sql`
16. `supabase/2026033112_tasks_deadline_fk.sql`
17. `supabase/2026040501_semester_isolation_phase1.sql`
18. `supabase/2026040502_enforce_semester_not_null.sql`
19. `supabase/2026040503_notifications_semester_scope.sql`
20. `supabase/2026040901_study_sessions_only_fix.sql`
21. `supabase/2026040902_ensure_study_sessions_course_fk.sql`
22. `supabase/2026041601_mood_stress_foundation.sql`
23. `supabase/2026041602_mood_settings_tracking_enabled.sql`
24. `supabase/2026042101_add_users_weekly_study_goal.sql` (legacy)
25. `supabase/2026042102_semesters_weekly_study_goal.sql`
26. `supabase/2026042901_drop_legacy_users_weekly_goal.sql`
27. `supabase/2026050501_notifications_type_expand.sql`

These scripts create/update tables, constraints, triggers, and RPC functions.

Then run:

28. `lib/services/supabase/rls_policies.sql`

This applies the current RLS policy set used by the app (`users`, `student_profiles`, `semesters`, `courses`, `tasks`, `deadlines`).

### 4. Deploy Edge Functions

```bash
supabase functions deploy acadia-ai
supabase functions deploy send-push
```

Set Edge Function secrets:
- `NVIDIA_API_KEY`, `NVIDIA_MODEL` (for acadia-ai)
- `RESEND_API_KEY` (required for **Email my tasks** in the AI assistant)
- `RESEND_FROM` (required for email sends — e.g. `Acadia <noreply@yourdomain.com>`; must match a verified sender in Resend, no hardcoded default in code)
- `FIREBASE_SERVICE_ACCOUNT` (for send-push)
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (both functions)

### 5. Configure Firebase

Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) for FCM.

### 6. Run the app

```bash
flutter run
```

Run on a specific platform:

```bash
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

## Localization

Localization config is in `l10n.yaml`. Supported locales:
- English (`en`) — template
- Turkish (`tr`)

To regenerate localization files:

```bash
flutter gen-l10n
```

## Common Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter build ios
flutter build web
flutter gen-l10n
```

## Development Tips

- Keep business logic in providers/repositories, not UI widgets.
- Keep Supabase calls in `services/supabase/`.
- Domain engines (risk, decision, prediction) are pure Dart in `lib/domain/` and `lib/core/services/` — no Flutter or Supabase imports.
- Update model `fromJson`/`toJson` mappings when schema fields change.
- If you change onboarding/auth flow, review route redirect logic in `main.dart`.
- New tables must have RLS enabled and `auth.uid() = user_id` policies defined.
- Use `globalRefreshProvider` for bulk data refresh (respects dependency order).
- When changing risk or analytics formulas, update **both** `riskProvider` / `analyticsProvider` **and** the assistant (`AiDataResolver`, optional `acadia-ai` summaries) so numbers stay aligned.
- Timer state persists in Hive box `timer_state` — clear it in `StudyTimerNotifier.reset()` if you modify timer logic.
- Notification deduplication and deep-link routing rely on `(user_id, reference_id, type)` + normalized `referenceId` format (`task:<id>`, `deadline:<id>`, etc.).

## Security and Data Access

- **Row Level Security (RLS)** on every table — `auth.uid() = user_id` policies
- `course_result_components` uses an EXISTS subquery via parent `course_results` ownership
- Auth rate limiting with exponential backoff persisted in Hive
- `.env` file is gitignored — never commit secrets
- Edge Functions validate Bearer tokens via `supabase.auth.getUser()`
- Background worker re-initializes Supabase in an isolated context (no shared state)

## Models (23)

| Model | Purpose |
|---|---|
| `AppUser` | Auth-linked app user (id, email, name, avatar, academic_profile_completed) |
| `StudentProfile` | Academic profile (university, degree, major, study preferences) |
| `Semester` | Academic term (name, dates, weekly_study_goal, is_current) |
| `Course` | Course (name, code, ECTS, credits, color, semester_id) |
| `Task` | Actionable task (title, course, deadline_id, priority, status, estimated_time) |
| `Deadline` | Academic deadline (title, course, date, type, priority, is_completed) |
| `StudySession` | Timed study record (session_type, duration, Pomodoro metadata, mood/stress) |
| `MoodLog` | Mood/stress/energy entry (mood_level 1-5, stress 1-10, factors, source) |
| `MoodSettings` | Per-user mood tracking config (tracking/reminder enabled, time, type) |
| `CourseResult` | Grade record (letter_grade, final_average, result_status, components) |
| `CourseResultComponent` | Grading breakdown item (title, score, percentage) |
| `NotificationModel` | In-app notification (title, message, type, reference_id, is_read) |
| `AnalyticsData` | Computed analytics aggregate (~25 fields: GPA, risk, consistency, deficit...) |
| `AnalyticsModel` | Persisted weekly analytics snapshot |
| `TrendData` | Time-series trends (study, workload, grade) + insights |
| `SemesterComparison` | Current vs. previous semester delta with computed insight generation |
| `PerformanceSummary` | Lifetime academic performance (best/worst/most-improved semester) |
| `DecisionSnapshot` | AI study recommendation (next action, focus, what changed) |
| `HeatmapDay` | Daily study activity score (minutes + sessions) |
| `AiMessage` | Chat message (text, isUser, type, data payload, suggestions) |
| `AiIntent` | Parsed user intent (type, time range filter, course filter) |
| `ExamModel` | Exam record (course, date, weight) |
| `AcademicCalendarModel` | Semester calendar boundaries |
