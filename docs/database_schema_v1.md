# Acadia — Database Schema Reference v1.0

**Frozen:** 2026-05-08  
**Last migration applied:** `2026050601_study_sessions_rich_fields.sql`  
**Environment:** Supabase (PostgreSQL 15), Row Level Security enabled on all tables  
**Auth provider:** Supabase Auth (`auth.users` — managed, not documented here)

---

## Table of Contents

1. [ERD Overview](#erd-overview)
2. [Table Reference](#table-reference)
   - [users (auth extension)](#users-auth-extension)
   - [student_profiles](#student_profiles)
   - [semesters](#semesters)
   - [courses](#courses)
   - [tasks](#tasks)
   - [academic_deadlines](#academic_deadlines)
   - [study_sessions](#study_sessions)
   - [mood_logs](#mood_logs)
   - [mood_settings](#mood_settings)
   - [notifications](#notifications)
   - [course_results](#course_results)
   - [course_result_components](#course_result_components)
   - [exams](#exams)
   - [analytics](#analytics)
   - [academic_calendar](#academic_calendar)
3. [Relationship Map](#relationship-map)
4. [Analytics Source of Truth](#analytics-source-of-truth)
5. [Session Lifecycle](#session-lifecycle)
6. [Mood Lifecycle](#mood-lifecycle)
7. [Semester Scoping Contract](#semester-scoping-contract)
8. [RLS Policy Summary](#rls-policy-summary)
9. [Migration History](#migration-history)

---

## ERD Overview

```
auth.users
│
├─── users (academic_profile_completed)
│
├─── student_profiles ────────────────── active_semester_id → semesters
│
└─── semesters (1:N per user)
      │
      ├─── courses (1:N per semester)
      │     │
      │     ├─── tasks ──────────────── deadline_id → academic_deadlines
      │     ├─── academic_deadlines
      │     ├─── study_sessions
      │     ├─── course_results
      │     │     └─── course_result_components
      │     └─── exams
      │
      ├─── mood_logs
      └─── notifications
```

All user-owned data is strictly scoped to `user_id = auth.uid()` via RLS.  
All transactional data (sessions, tasks, deadlines, mood, notifications, exams) is additionally scoped to `semester_id`.

---

## Table Reference

---

### `users` (auth extension)

Thin extension of `auth.users`. Stores only app-level flags not managed by Supabase Auth.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | — | FK → `auth.users.id`, PK |
| `academic_profile_completed` | boolean | NOT NULL | `false` | Set to `true` after onboarding step 3 completes |

**RLS:** `auth.uid() = id`

---

### `student_profiles`

One row per user. Stores academic identity and the active semester pointer.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL UNIQUE | — | FK → `auth.users.id` CASCADE |
| `full_name` | text | nullable | — | Display name |
| `university_name` | text | nullable | — | |
| `degree_type` | text | nullable | — | e.g. `BSc`, `MSc` |
| `major` | text | nullable | — | |
| `minor` | text | nullable | — | |
| `academic_year` | integer | nullable | — | |
| `current_semester` | integer | nullable | — | Ordinal (1st, 2nd…) |
| `expected_graduation_year` | integer | nullable | — | |
| `study_hours_per_week` | integer | nullable | — | User preference target |
| `preferred_study_time` | text | nullable | — | `morning`, `afternoon`, `evening`, `night` |
| `break_pattern` | text | nullable | — | `short`, `long`, `mixed` |
| `timezone` | text | nullable | — | IANA timezone string |
| `country` | text | nullable | — | |
| `onboarding_complete` | boolean | nullable | `false` | Legacy — use `users.academic_profile_completed` |
| `active_semester_id` | uuid | nullable | — | FK → `semesters.id` SET NULL — **keystone of all data scoping** |
| `created_at` | timestamptz | NOT NULL | `now()` | |
| `updated_at` | timestamptz | NOT NULL | `now()` | Auto-updated via trigger |

**RLS:** SELECT / UPDATE / INSERT for `auth.uid() = user_id`  
**Trigger:** `update_updated_at_column()` on UPDATE

> **Important:** `active_semester_id` is the single source of truth for which semester all providers, queries, and analytics are scoped to. Never query user data without this filter.

---

### `semesters`

Academic terms. Each user can have multiple, exactly one `is_current = true`.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `name` | text | NOT NULL | — | e.g. `Spring 2026` |
| `start_date` | timestamptz | nullable | — | Semester start |
| `end_date` | timestamptz | nullable | — | Semester end |
| `is_current` | boolean | nullable | `false` | Only one should be `true` per user at a time |
| `weekly_study_goal` | integer | nullable | `15` | Hours/week target for analytics deficit |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

### `courses`

Courses within a semester. All transactional data (sessions, tasks, deadlines, results, exams) links here.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `course_name` | text | NOT NULL | — | |
| `course_code` | text | nullable | — | e.g. `CS301` |
| `professor` | text | nullable | — | |
| `semester` | integer | nullable | — | Legacy ordinal field — use `semester_id` |
| `semester_id` | uuid | nullable | — | FK → `semesters.id` SET NULL |
| `credits` | integer | nullable | — | Also stored as `ects` in some query aliases |
| `color` | text | nullable | — | Hex color string for UI |
| `is_active` | boolean | nullable | `true` | Inactive courses excluded from recommendations |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

### `tasks`

Actionable work items. Can be linked to an `academic_deadline` as sub-tasks.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester_id` | uuid | NOT NULL | — | FK → `semesters.id` CASCADE |
| `course_id` | uuid | nullable | — | FK → `courses.id` SET NULL |
| `deadline_id` | uuid | nullable | — | FK → `academic_deadlines.id` SET NULL — links task to parent deadline |
| `title` | text | NOT NULL | — | |
| `course` | text | nullable | — | Legacy string field — use `course_id` |
| `deadline` | timestamptz | nullable | — | Due date |
| `priority` | text | nullable | — | `low`, `medium`, `high` |
| `estimated_time` | integer | nullable | — | Minutes |
| `status` | text | nullable | `'pending'` | `pending`, `completed` |
| `notes` | text | nullable | — | |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

### `academic_deadlines`

Academic work targets (assignments, exams, projects, quizzes). Tasks link to these as sub-tasks.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester_id` | uuid | NOT NULL | — | FK → `semesters.id` CASCADE |
| `course_id` | uuid | nullable | — | FK → `courses.id` SET NULL |
| `title` | text | NOT NULL | — | |
| `course` | text | NOT NULL | — | Legacy string field |
| `deadline_date` | timestamptz | NOT NULL | — | |
| `deadline_type` | text | NOT NULL | — | CHECK: `assignment`, `exam`, `quiz`, `project` |
| `priority` | text | NOT NULL | — | CHECK: `low`, `medium`, `high` |
| `is_completed` | boolean | NOT NULL | `false` | Auto-set when all child tasks complete |
| `completed_at` | timestamptz | nullable | — | Set when `is_completed` becomes `true` |
| `notes` | text | nullable | — | |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

### `study_sessions`

The central record of every study session. Supports both standard (deep work / review) and structured Pomodoro sessions.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `course_id` | uuid | NOT NULL | — | FK → `courses.id` CASCADE |
| `semester_id` | uuid | NOT NULL | — | FK → `semesters.id` CASCADE |
| `session_type` | text | NOT NULL | — | CHECK: `pomodoro`, `deep_work`, `review` |
| `duration_minutes` | integer | NOT NULL | — | **Analytics canonical duration.** For Pomodoro = `total_focus_minutes`. Used by study-hour calculations everywhere. |
| `created_at` | timestamptz | NOT NULL | `now()` | Session timestamp — used for consistency, weekly filtering, heatmap |
| `intent` | text | nullable | — | User-entered study goal (e.g. `"Complete chapter 3"`) |
| `completed` | boolean | NOT NULL | `true` | `false` = session stopped early |
| `is_pomodoro` | boolean | NOT NULL | `false` | Shortcut — equivalent to `session_type = 'pomodoro'` |
| `planned_minutes` | integer | nullable | — | Target duration set before starting. Used by AdaptiveEngine for completion ratio. |
| `actual_minutes` | integer | nullable | — | Real elapsed minutes. Used by AdaptiveEngine for avg actual session length. |
| `started_at` | timestamptz | nullable | — | Wall-clock start time |
| `ended_at` | timestamptz | nullable | — | Wall-clock end time |
| `mood` | double precision | nullable | — | **Session-level mood** (1–5). Set post-session by `attachMoodToLastSession()`. Used by DecisionEngine and burnout heatmap. NOT a substitute for `mood_logs`. |
| `stress` | double precision | nullable | — | **Session-level stress** (1–10). Set post-session. Used by DecisionEngine, burnout score, and risk engine. |
| `completed_cycles` | integer | nullable | — | For non-Pomodoro sessions — number of focus cycles completed |
| `skipped_breaks` | integer | nullable | — | Count of breaks skipped during session |
| `total_focus_minutes` | integer | nullable | — | **Pomodoro only.** Total focus time across all rounds |
| `total_break_minutes` | integer | nullable | — | **Pomodoro only.** Total break time across all rounds |
| `cycles_completed` | integer | nullable | — | **Pomodoro only.** Completed rounds out of `total_cycles` |
| `total_cycles` | integer | nullable | — | **Pomodoro only.** Total planned rounds (usually 4) |
| `reflection_tag` | text | nullable | — | Legacy field — not actively used |
| `reflection` | text | nullable | — | Legacy field — not actively used |

**Indexes:** `idx_study_sessions_semester_id (semester_id)`, `study_sessions_user_created_at_idx (user_id, created_at DESC)`  
**RLS:** All operations for `auth.uid() = user_id`

> **Session mood vs mood_logs:** `study_sessions.mood/stress` is attached to the specific session record for per-session history and the decision/risk engines. `mood_logs` stores standalone mood entries for aggregate trend analysis and the Analytics Mood tab. They are separate data sources with different analytical roles — do not merge or deduplicate.

---

### `mood_logs`

Standalone mood entries. Source of truth for mood/stress analytics, burnout score, and the Analytics Mood tab.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester_id` | uuid | NOT NULL | — | FK → `semesters.id` CASCADE |
| `mood_level` | integer | NOT NULL | — | CHECK: 1–5 (1=awful, 5=great) |
| `stress_level` | integer | NOT NULL | — | CHECK: 1–10 |
| `energy_level` | integer | nullable | — | 1–10 |
| `source` | text | NOT NULL | `'manual'` | CHECK: `manual`, `session`. Determines classification in analytics (daily vs session moods). |
| `factors` | text[] | nullable | — | Selected factors: `sleep`, `workload`, `health`, `motivation`, `social`, `exams` |
| `note` | text | nullable | — | Optional free-text reflection |
| `mood` | text | nullable | — | Legacy label field (`very_bad`…`very_good`) — use `mood_level` |
| `created_at` | timestamptz | nullable | `now()` | |

**Deduplication index:** partial unique on `(user_id, reference_id, type)` (notifications table — not applicable here)  
**RLS:** All operations for `auth.uid() = user_id`

> **Analytics classification:** rows with `source = 'session'` are classified as session moods; all others as daily moods. This determines which average appears in which Analytics tab. If `mood_settings.tracking_enabled = false`, all mood rows are excluded from analytics computation entirely.

---

### `mood_settings`

One row per user. Controls mood tracking behavior and reminder scheduling.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `user_id` | uuid | NOT NULL | — | PK, FK → `auth.users.id` CASCADE |
| `tracking_enabled` | boolean | nullable | `true` | Master toggle. If `false`, mood data excluded from all analytics. |
| `reminder_enabled` | boolean | nullable | `true` | Whether daily reminder notifications are sent |
| `reminder_time` | time | nullable | — | Time of day for daily reminder (HH:MM) |
| `reminder_type` | text | nullable | `'both'` | CHECK: `daily`, `session`, `both` — controls when mood prompt appears |

**Upsert key:** `user_id`  
**RLS:** All operations for `auth.uid() = user_id`

---

### `notifications`

In-app notification inbox. Every notification is semester-scoped and deduplicated by reference.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester_id` | uuid | nullable | — | FK → `semesters.id` CASCADE |
| `title` | text | NOT NULL | — | |
| `message` | text | NOT NULL | — | |
| `type` | text | NOT NULL | — | CHECK: `deadline`, `deadline_batch`, `task_overdue`, `overdue`, `overdue_batch`, `study_goal`, `system`, `due_today`, `due_tomorrow`, `risk`, `stress`, `academic_summary`, `mood`, `mood_check`, `exam` |
| `reference_id` | text | nullable | — | Format: `task:<uuid>`, `deadline:<uuid>`, `academic_summary:<date>`, `exam:<uuid>` — used for deep-link routing and deduplication |
| `is_read` | boolean | nullable | `false` | |
| `created_at` | timestamptz | nullable | `now()` | |

**Deduplication index:** partial unique on `(user_id, reference_id, type)` — prevents duplicate notifications for the same event  
**RLS:** All operations for `auth.uid() = user_id`

---

### `course_results`

Grade records per course per semester. Used for GPA and CGPA computation.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `course_id` | uuid | NOT NULL | — | FK → `courses.id` CASCADE |
| `semester_id` | uuid | nullable | — | FK → `semesters.id` CASCADE |
| `semester` | text | NOT NULL | — | Legacy text label — use `semester_id` |
| `letter_grade` | text | NOT NULL | — | e.g. `AA`, `BB`, `CC`, `FF` (Turkish grade scale) |
| `final_average` | numeric | nullable | — | Weighted numeric average |
| `result_status` | text | nullable | — | CHECK: `successful`, `failed` |
| `created_at` | timestamptz | NOT NULL | `now()` | |
| `updated_at` | timestamptz | NOT NULL | `now()` | |

**Save pattern:** atomic upsert via `save_course_result_with_components()` RPC  
**GPA policy:** for retaken courses only the latest attempt (by `updated_at`) counts  
**RLS:** All operations for `auth.uid() = user_id`

---

### `course_result_components`

Grade breakdown per result (individual exam/assignment scores).

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `result_id` | uuid | NOT NULL | — | FK → `course_results.id` CASCADE |
| `title` | text | NOT NULL | — | e.g. `Midterm`, `Final`, `Assignment 1` |
| `score` | numeric | NOT NULL | — | Raw score |
| `percentage` | numeric | NOT NULL | — | Weight of this component in final grade |

**RLS:** Inherited from `course_results` via RPC; direct RLS also enforced on parent join

---

### `exams`

Scheduled exams within a semester. Supports countdown display and calendar view.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester_id` | uuid | NOT NULL | — | FK → `semesters.id` CASCADE |
| `course_id` | uuid | nullable | — | FK → `courses.id` SET NULL |
| `title` | text | nullable | — | Exam name |
| `type` | text | nullable | — | CHECK: `midterm`, `final`, `quiz` |
| `exam_datetime` | timestamptz | nullable | — | **Canonical exam time** — use this, not legacy `exam_date` |
| `weight` | integer | nullable | — | Grade weight percentage |
| `classroom` | text | nullable | — | Physical location |
| `is_online` | boolean | nullable | `false` | |
| `instructor_name` | text | nullable | — | |
| `notes` | text | nullable | — | |
| `course` | text | nullable | — | Legacy string field — use `course_id` |
| `exam_date` | timestamptz | nullable | — | Legacy field — use `exam_datetime` |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

### `analytics`

Persisted weekly analytics snapshots. Secondary store — primary analytics are computed in-memory by `analyticsProvider`.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `performance_score` | integer | nullable | — | |
| `workload_density` | integer | nullable | — | |
| `burnout_risk` | integer | nullable | — | |
| `week_start` | date | nullable | — | ISO week start date |
| `created_at` | timestamptz | nullable | `now()` | |

**Note:** This table is a historical snapshot store. The live analytics shown in the app are computed by `AnalyticsRepository.computeFromPreloaded()` using Riverpod provider data — not read from this table in the primary flow.

---

### `academic_calendar`

Semester boundary metadata for academic planning.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NOT NULL | `uuid_generate_v4()` | PK |
| `user_id` | uuid | NOT NULL | — | FK → `auth.users.id` CASCADE |
| `semester` | integer | nullable | — | Legacy ordinal |
| `semester_start` | date | NOT NULL | — | |
| `semester_end` | date | NOT NULL | — | |
| `exam_period_start` | date | nullable | — | |
| `exam_period_end` | date | nullable | — | |
| `created_at` | timestamptz | nullable | `now()` | |

**RLS:** All operations for `auth.uid() = user_id`

---

## Relationship Map

```
auth.users (1)
 │
 ├── (1:1) users                     — academic_profile_completed flag
 ├── (1:1) student_profiles          — active_semester_id (keystone pointer)
 ├── (1:1) mood_settings             — tracking, reminders, type
 │
 └── (1:N) semesters
            │
            ├── (1:N) courses
            │          │
            │          ├── (1:N) tasks ──────────── (N:1) academic_deadlines
            │          ├── (1:N) academic_deadlines
            │          ├── (1:N) study_sessions
            │          ├── (1:N) course_results
            │          │          └── (1:N) course_result_components
            │          └── (1:N) exams
            │
            ├── (1:N) mood_logs
            └── (1:N) notifications
```

**Cascade rules summary:**
- Deleting `auth.users` → cascades to everything
- Deleting a `semester` → cascades to all semester-scoped tables
- Deleting a `course` → cascades to `study_sessions`, `course_results`; SET NULL on `tasks`, `academic_deadlines`, `exams`
- Deleting an `academic_deadline` → SET NULL on linked `tasks.deadline_id`

---

## Analytics Source of Truth

| Metric | Primary Source | Query Path |
|---|---|---|
| Study hours (week) | `study_sessions.duration_minutes` | Filtered by `created_at >= week_start` |
| Study hours (all-time) | `study_sessions.duration_minutes` | All rows in semester |
| Consistency | `study_sessions.created_at` | Distinct study days / 7 |
| Weekly avg hours | `study_sessions.duration_minutes` | Total / semester weeks |
| GPA (semester) | `course_results.letter_grade` + `courses.credits` | Credit-weighted, latest attempt per course |
| CGPA (cumulative) | `course_results` + `courses` (all semesters) | Same formula, cross-semester |
| Task completion rate | `tasks.status` + `academic_deadlines.is_completed` | Current week only |
| Overdue count | `tasks.deadline`, `academic_deadlines.deadline_date` | Past due, not completed |
| Due soon count | `tasks.deadline`, `academic_deadlines.deadline_date` | Within 3 days, not completed |
| Avg mood (daily) | `mood_logs.mood_level` WHERE `source != 'session'` | All semester rows |
| Avg mood (session) | `mood_logs.mood_level` WHERE `source = 'session'` | All semester rows |
| Avg stress (daily) | `mood_logs.stress_level` WHERE `source != 'session'` | All semester rows |
| Avg stress (session) | `mood_logs.stress_level` WHERE `source = 'session'` | All semester rows |
| Burnout score | `mood_logs.stress_level` (session avg) + study deficit + consistency | Computed in `_computeBurnoutScore()` |
| Risk score | overdue + due soon + study deficit + session stress + consistency | `RiskEngine.calculate()` |
| Session mood trend | `study_sessions.mood` + `study_sessions.stress` | DecisionEngine, per-session history |
| Adaptive profile | `study_sessions.planned_minutes` vs `actual_minutes` | `AdaptiveEngine.build()` |

**Mood data split:** `mood_logs.source` determines which average goes to which UI tab. Aggregate analytics (`avgMood`, `avgStress`) span both sources for backward compatibility.

**mood_logs vs study_sessions.mood/stress:** These are separate data paths. `mood_logs` drives aggregate wellness analytics. `study_sessions.mood/stress` drives the DecisionEngine recommendations and per-session detail display.

---

## Session Lifecycle

```
1. USER STARTS SESSION
   StudyTimerNotifier.start()
   → state persisted to Hive (survives app kill)

2. TIMER RUNS
   Every 1s: elapsed updated, Hive synced
   On app resume: time-jump calculated

3. SESSION ENDS (auto or manual stop)
   _onPhaseComplete() or stop()

4. SAVE DECISION
   Pomodoro:  savePomodoroSession()  if totalFocusMinutes >= 10
   Standard:  saveFromTimer()        if isCompleted && minutes >= 10

5. DB INSERT
   StudySession.toJson() → StudyService.createSession()
   → study_sessions row created with all fields

6. STATE UPDATE
   studySessionsProvider state updated ([newSession, ...existing])
   analyticsProvider.refresh() called immediately

7. MOOD PROMPT (if enabled)
   moodSettingsProvider.shouldShowAfterStudy == true
   → moodActionsProvider.queueSessionMoodPrompt()
   → LogMoodScreen navigated to with source='session'

8. MOOD ATTACHED
   User submits mood → MoodActions.saveMoodLog(source: 'session')
   → mood_logs row inserted
   → attachMoodToLastSession(mood, stress) called
     → study_sessions row UPDATEd with mood/stress values
   → All providers invalidated synchronously (before navigation)
   → Home + Analytics rebuild with fresh data
```

**Duplicate save guard:** `_pomodoroSaved` flag on `StudySessionsNotifier` prevents double-save when both `_onPhaseComplete()` and `stop()` fire in the same session.

---

## Mood Lifecycle

```
1. TRIGGER
   a. Daily reminder notification → taps → LogMoodScreen (source='manual')
   b. Post-session prompt → LogMoodScreen (source='session')
   c. Manual tap from Home mood card → LogMoodScreen (source='manual')

2. USER INPUT
   mood_level (1–5), stress_level (1–10), energy_level (1–10),
   factors (multi-select), note (optional)

3. INSERT
   MoodActions.saveMoodLog()
   → MoodRepository.insertMood()
   → MoodService.insertMood()
   → mood_logs row created

4. SESSION ATTACHMENT (source='session' only)
   attachMoodToLastSession(mood, stress)
   → study_sessions.mood + study_sessions.stress SET for most recent session

5. PROVIDER INVALIDATION (synchronous, before navigation)
   ref.invalidate(moodLogsProvider)
   ref.invalidate(dailyMoodLogsProvider)
   ref.invalidate(sessionMoodLogsProvider)
   ref.invalidate(todayMoodProvider)
   ref.invalidate(analyticsProvider)
   ref.invalidate(riskProvider)

6. ANALYTICS RECOMPUTE
   analyticsProvider builds with fresh moodLogsProvider data
   Cache busted by moodFingerprint (polynomial fold over all entries)

7. UI UPDATE
   Home screen: avgMood, avgStress, burnoutScore, riskScore
   Analytics Mood tab: trend charts, averages, daily vs session split
   Home AI insights: updated via analyticsProvider dependency
```

**Once-per-day gate:** `todayMoodProvider` checks if a non-session mood exists for today (used to suppress daily reminder after logging). There is no hard database constraint preventing multiple logs per day.

---

## Semester Scoping Contract

Every table that holds user study data enforces `semester_id NOT NULL`:

| Table | semester_id | Cascade on delete |
|---|---|---|
| `tasks` | NOT NULL | CASCADE |
| `academic_deadlines` | NOT NULL | CASCADE |
| `study_sessions` | NOT NULL | CASCADE |
| `mood_logs` | NOT NULL | CASCADE |
| `notifications` | nullable | CASCADE |
| `exams` | NOT NULL | CASCADE |
| `course_results` | nullable | CASCADE |

**Rule:** Never query any of these tables without a `semester_id` filter. All Riverpod providers gate on `activeSemesterProvider` and return empty if it is null. All Supabase queries use `.eq('semester_id', semesterId)`.

**Changing active semester:** updating `student_profiles.active_semester_id` triggers a cascade of provider invalidations via `activeSemesterProvider` listener in `analyticsProvider`, resetting all cached data.

---

## RLS Policy Summary

| Table | Policy |
|---|---|
| All tables | `auth.uid() = user_id` for all operations |
| `study_sessions` | Additional policies: SELECT, INSERT, UPDATE, DELETE each with `auth.uid() = user_id` |
| `course_result_components` | Access via parent `course_results` (joined queries) |
| `notifications` | `auth.uid() = user_id` — partial unique index on `(user_id, reference_id, type)` for deduplication |

**Edge Functions:** Both `acadia-ai` and `send-push` validate the caller's JWT via `supabase.auth.getUser()` before executing. No unauthenticated access is possible.

---

## Migration History

| File | Date | Description |
|---|---|---|
| `schema.sql` | Base | Initial tables: student_profiles, semesters, courses, tasks, study_sessions, academic_deadlines, exams, mood_logs, analytics, academic_calendar |
| `2026031602` | 2026-03-16 | Add course_id FK to tasks, study_sessions, academic_deadlines, exams |
| `2026031603` | 2026-03-16 | Semester structure normalization |
| `2026031604` | 2026-03-16 | Add courses.is_active, users.academic_profile_completed |
| `2026031605` | 2026-03-16 | Foundation hardening — backfill academic_profile_completed |
| `2026031606` | 2026-03-16 | Profile split; add study_sessions.reflection_tag, reflection |
| `2026031701` | 2026-03-17 | Stability patch |
| `2026031901` | 2026-03-19 | Study session history foundation — RLS policies |
| `2026031902` | 2026-03-19 | Notifications type expansion |
| `2026031903` | 2026-03-19 | Notifications reference_id deduplication index |
| `2026033101` | 2026-03-31 | course_results table foundation |
| `2026033102` | 2026-03-31 | Add course_results.result_status |
| `2026033103` | 2026-03-31 | Add course_results.semester_id FK |
| `2026033104` | 2026-03-31 | save_course_result_with_components() RPC |
| `2026033111` | 2026-03-31 | academic_deadlines.is_completed + completed_at |
| `2026033112` | 2026-03-31 | tasks.deadline_id FK to academic_deadlines |
| `2026040501` | 2026-04-05 | Semester isolation phase 1 — add semester_id to all tables |
| `2026040502` | 2026-04-05 | Enforce semester_id NOT NULL on tasks, deadlines, sessions |
| `2026040503` | 2026-04-05 | notifications.semester_id |
| `2026040901` | 2026-04-09 | study_sessions semester_id enforcement and backfill |
| `2026040902` | 2026-04-09 | study_sessions course FK hardening |
| `2026041601` | 2026-04-16 | mood_logs rebuild: mood_level, stress_level, energy_level, source, factors, semester_id; mood_settings table |
| `2026041602` | 2026-04-16 | mood_settings.tracking_enabled |
| `2026042101` | 2026-04-21 | users.weekly_study_goal (later dropped) |
| `2026042102` | 2026-04-21 | semesters.weekly_study_goal |
| `2026042901` | 2026-04-29 | Drop users.weekly_study_goal (moved to semesters) |
| `2026050501` | 2026-05-05 | Notifications type expansion (mood_check, exam) |
| `2026050502` | 2026-05-05 | Exams module — title, course_id, exam_datetime, type, classroom, is_online, notes |
| `2026050503` | 2026-05-05 | exams.type CHECK constraint add quiz |
| `2026050504` | 2026-05-05 | exams.semester_id NOT NULL enforcement |
| `2026050505` | 2026-05-05 | notifications.type add exam |
| **`2026050601`** | **2026-05-08** | **study_sessions: add 15 structured session fields (intent, completed, is_pomodoro, mood, stress, planned/actual minutes, cycle tracking, timestamps)** |
