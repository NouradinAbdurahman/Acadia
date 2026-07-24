# Acadia Supabase Recovery Audit

Produced before any SQL was executed against the new project. Sources: every file in
`supabase/` (31 numbered migrations + `schema.sql`), `supabase/functions/**`, `git log`
history of `supabase/`, and every Dart file under `lib/` (`repositories/`, `services/`,
`providers/`, `models/`).

## 1. What `schema.sql` actually is

**Conclusion: a hand-maintained, partial "rolling baseline" snapshot — not a bootstrap,
not a `pg_dump`, and not the final schema.** Evidence:

- `git log --follow -- supabase/schema.sql` shows only 3 commits ever touched it:
  the repo's `first commit` (created it, 168 lines), `chore: apply all current project
  changes` (+8 lines), and `Finalize semester-integrity updates...` (+66 lines). No
  commits after that ever touched it again, while **15 more numbered migrations**
  (`2026040901` → `2026050601`) were added afterward without any corresponding update.
- Its style is hand-written (`-- Courses Table` comments, `do $$ if not exists $$`
  guards) — identical authorial style to the numbered migrations, not the output of
  `supabase db dump`, which would include `SET`/`OWNER TO`/sequence-ownership
  boilerplate.
- It creates `student_profiles`, never `users` — yet the very first git commit that
  created `schema.sql` *also* added `2026031604_foundation_updates.sql`, which already
  `ALTER TABLE public.users`. So `public.users` existed in production *before this repo's
  history begins*, and `schema.sql`'s author either didn't know about it or chose not to
  track it there.
- Every later patch to `schema.sql` duplicates content that an existing numbered
  migration already covered (e.g. the `a7130f0` patch re-adds `semesters` and
  `courses.semester_id`, both already created by `2026031603` in the same first commit).

**Is "schema.sql then all 31 migrations" safe?** Yes — but only because every block in
every file (verified by reading all 32 files start to finish) uses idempotent guards:
`create table if not exists`, `add column if not exists`, `drop constraint/policy if
exists` + recreate, or a `do $$ if not exists $$` check. Applying `schema.sql`'s stale,
partial content first and then replaying all 31 migrations in order is safe *specifically
because* nothing in either source assumes exclusive authorship — later, more-refined
definitions always win over earlier ones for constraints and policies (drop-then-add
pattern), and column adds simply no-op if already present. If schema.sql actually
represented final state, replaying migrations after it would still be safe for the same
reason — the idempotent-guard convention makes ordering forgiving as long as the 31
migrations keep their own relative chronological order.

## 2–3. Full object inventory (recovered vs. reconstructed)

### Tables (12 created by schema.sql + 5 by migrations = 17 confirmed, 1 reconstructed)

| Table | Created by | Status |
|---|---|---|
| `student_profiles` | schema.sql | confirmed |
| `semesters` | schema.sql / `2026031603` | confirmed |
| `courses` | schema.sql / `2026031602` | confirmed |
| `academic_calendar` | schema.sql | confirmed, **but unreferenced by any current Dart code** — legacy/orphaned |
| `tasks` | schema.sql | confirmed (missing `updated_at`, see below) |
| `study_sessions` | schema.sql / `2026031901` | confirmed |
| `academic_deadlines` | schema.sql | confirmed |
| `exams` | schema.sql / `2026050502` (rebuilt) | confirmed |
| `mood_logs` | schema.sql / `2026041601` (rebuilt) | confirmed |
| `analytics` | schema.sql | confirmed, **but unreferenced by any current Dart code** — legacy/orphaned |
| `notifications` | `2026031604`/`2026031605` | confirmed |
| `mood_settings` | `2026041601` | confirmed |
| `course_results` | `2026033101` | confirmed |
| `course_result_components` | `2026033101` | confirmed |
| `users` | **nowhere** | **MISSING — reconstructed, see §4** |

No `seed.sql`, no `supabase/migrations/` directory, no `config.toml` exist in this repo.

### Columns — every gap found

| Table.column | Evidence it's required | Confidence |
|---|---|---|
| `public.users` (whole table) | 6 migrations `ALTER` it; `auth_repository.dart` inserts into it; `student_profile_service.dart`, `avatar_service.dart`, `notification_service.dart` read/write it | **Reconstructed — high confidence** (see §4) |
| `public.users.fcm_token` | `lib/services/notification_service.dart:94,362,546,550` reads/writes it; no migration ever adds it | **Reconstructed — high confidence** |
| `public.tasks.updated_at` | `lib/models/task.dart` `fromJson`/`toJson`; `lib/services/supabase/task_service.dart` `completeAllTasksForDeadline` writes it directly | **Reconstructed — high confidence** |

No other column gaps found after cross-referencing every model's `toJson`/`fromJson`
against every `CREATE`/`ALTER TABLE` statement, and every `.insert()`/`.update()`/
`.upsert()` call site in `lib/services/supabase/*.dart`.

### Foreign keys, indexes, constraints — recovered inventory

All present in the 31 migrations + schema.sql, reconstructed nowhere (all confirmed):

- **Composite FK**: `exams(semester_id, user_id) → semesters(id, user_id)` backed by
  `semesters_id_user_unique UNIQUE(id, user_id)` — enforces an exam's semester actually
  belongs to the same user (`2026050502`, reinforced `2026050504`).
- **Unique indexes**: `notifications_reference_type_unique (user_id, reference_id, type)
  WHERE reference_id IS NOT NULL` (`2026031903`); `uniq_exam_per_slot (user_id,
  semester_id, exam_datetime, title)` (`2026050502`).
- **Plain indexes**: `study_sessions_user_created_at_idx`, `idx_study_sessions_semester_id`,
  `idx_academic_deadlines_user_completed`, `idx_tasks_user_deadline` (partial, `WHERE
  deadline_id IS NOT NULL`), `idx_notifications_user_semester_created`,
  `course_results_user_semester_idx`, `course_results_course_idx`,
  `course_result_components_result_idx`, `course_results_user_semester_id_idx`,
  `idx_exams_user_semester_datetime`, `idx_mood_user`, `idx_mood_semester`,
  `idx_mood_created_at`.
- **Check constraints (final state after all migrations replay in order)**:
  `study_sessions.session_type IN ('pomodoro','deep_work','review')`,
  `mood_logs.mood_level BETWEEN 1 AND 5`, `mood_logs.stress_level BETWEEN 1 AND 10`,
  `mood_logs.source IN ('manual','session')`, `mood_settings.reminder_type IN
  ('daily','session','both')`, `course_results.result_status IN ('successful','failed')
  OR NULL`, `exams.type IN ('midterm','final','quiz')`, `notifications.type` — 15-value
  final set (`deadline`, `deadline_batch`, `task_overdue`, `overdue`, `overdue_batch`,
  `study_goal`, `system`, `due_today`, `due_tomorrow`, `risk`, `stress`,
  `academic_summary`, `mood`, `mood_check`, `exam`) — **matches CLAUDE.md's documented
  notification contract exactly**, good corroboration that migration-order replay is
  trustworthy.
- **`tasks`/`study_sessions`/`academic_deadlines`/`exams`.`semester_id`**: all `NOT NULL`
  in final state (`2026040502`, `2026040901`, `2026050502`).

⚠️ **One real discrepancy found, deliberately not "fixed":** CLAUDE.md's Environment
section lists `practice` as a 4th valid `study_sessions.session_type` value. Replaying the
migrations in filename order produces a **3-value** constraint (`pomodoro`, `deep_work`,
`review`) — `2026031901` (dated after `2026031605`/`2026031701`, which had added
`practice`) drops and recreates the constraint *without* it. I checked whether the app
actually needs `practice`: `lib/screens/study/study_screen.dart:1627` hard-codes the
session-type picker to `[StudyType.pomodoro, StudyType.deepWork, StudyType.review]` —
`practice` has an l10n string (`app_en.arb`/`app_tr.arb`) but is never selectable or
written by the app today. Since nothing writes that value, this is functionally
inconsequential either way, so I did **not** generate a corrective migration — flagging
it here instead of guessing which of the two conflicting sources is "true." If you want
`practice` allowed anyway (e.g. future-proofing), say so and I'll add it.

### Triggers & functions (both confirmed, in schema.sql / migrations — none reconstructed)

- `update_updated_at_column()` (schema.sql) → trigger `update_student_profiles_updated_at`
  BEFORE UPDATE on `student_profiles`.
- Same function reused by trigger `update_course_results_updated_at` BEFORE UPDATE on
  `course_results` (`2026033101`).
- `save_course_result_with_components(...)` RPC function (`2026033104`) — **confirmed
  called** from `lib/services/supabase/course_result_service.dart:42-43`.
- `public.tasks.updated_at` has **no trigger** anywhere in evidence — it's written
  manually by app code, not auto-maintained. The reconstructed column (§ above) does not
  add one, to match that evidence exactly.

### Views: none found anywhere.

### RLS policies — full recovered final state per table

| Table | Final policy state |
|---|---|
| `student_profiles` | 3 separate policies: SELECT/UPDATE/INSERT own row. **No DELETE policy** (matches schema.sql exactly — deletion only happens via `auth.users` cascade). |
| `semesters`, `courses`, `tasks`, `academic_deadlines`, `notifications` | 1 policy each, `FOR ALL USING (auth.uid() = user_id)`. |
| `academic_calendar` | RLS enabled + 1 `FOR ALL` policy, but table is orphaned (unused by app). |
| `study_sessions` | schema.sql's `FOR ALL` policy **plus** 4 granular SELECT/INSERT/UPDATE/DELETE policies added by `2026031901` — neither ever drops the other, so final state has **5 overlapping policies** (redundant, not conflicting — Postgres OR's permissive policies together). |
| `exams` | Rebuilt twice (`2026050502`, `2026050504`); final policy is `"Users can access own exams (strict semester)"` — `auth.uid() = user_id` **and** an `EXISTS` check that the exam's `semester_id` belongs to a semester owned by that same user. |
| `mood_logs` | schema.sql's basic policy created first; `2026041601`'s more explicit `WITH CHECK` version is guarded by an `IF NOT EXISTS (SELECT ... pg_policies)` check and never actually applies (name collision) — functionally identical either way since Postgres reuses `USING` as `WITH CHECK` when a `FOR ALL` policy omits it. |
| `mood_settings`, `course_results`, `course_result_components` | 1 policy each, as defined in `2026041601` / `2026033101`. |
| `users` | **No policy exists anywhere** (table itself was never tracked) — reconstructed as `FOR ALL USING (auth.uid() = id)`, matching the pattern used by every other table in this codebase. **Inferred, high confidence.** |

## 5. Auth integration (`handle_new_user` / triggers)

**Confirmed: no `handle_new_user()`, no `on_auth_user_created`, no trigger on
`auth.users` anywhere** — in SQL, in either edge function, or referenced by name
anywhere in the repo. This is not a gap: `lib/repositories/auth_repository.dart`'s
`ensurePublicUserRowIfMissing()` does the `public.users` row creation **client-side**,
called after signup/login, with a `maybeSingle()` existence check before inserting. The
reconstructed `users` table (§4) needs no auto-creation trigger to match this
architecture — the app manages it.

## 6. Storage

**One bucket: `avatars`**, used only by `lib/services/storage/avatar_service.dart`.
- **Public**: confirmed — the code calls `getPublicUrl()` directly with no signed-URL
  flow, which only functions on a public bucket.
- **Policies**: not recoverable (bucket was never created via tracked SQL, same gap
  class as `public.users`). Reconstructed with medium confidence: public SELECT for
  everyone, INSERT/UPDATE/DELETE restricted to files prefixed with the caller's own
  `auth.uid()` (matches the app's own naming convention `${user.id}_${timestamp}.$ext`
  exactly, but the *original* policies could have differed — verify before relying on
  this for anything security-sensitive).

No other Storage buckets referenced anywhere in `lib/` or the edge functions.

## 7. Edge Functions

| Function | Exists locally | Notes |
|---|---|---|
| `acadia-ai` (`index.ts`, `unified_analytics.ts`, `academic_insights.ts`) | ✅ | Reads `semesters`, `study_sessions`, `tasks`, `academic_deadlines`, `mood_logs`, `courses`, `student_profiles` — all already accounted for in the table inventory, no new gaps. |
| `send-push` | ✅ | Stateless — receives the FCM token in the request body (the caller reads it from `users.fcm_token` client-side first) and calls Firebase directly. No DB access, no new gaps. |

Both functions referenced in CLAUDE.md are present. No missing Edge Functions found.
No `pg_net`/webhook triggers invoke either function from inside Postgres.

## 8. Extensions

Only `uuid-ossp` is explicitly created (`schema.sql`, `create extension if not exists
"uuid-ossp"`). `mood_logs`/`mood_settings`/`avatars`-adjacent code paths use
`gen_random_uuid()`, which ships built into every Supabase Postgres project by default
(via `pgcrypto`, pre-installed) — no explicit `CREATE EXTENSION pgcrypto` needed or
found anywhere, consistent with that default.

## 9. What could not be recovered

- The **exact original DDL** for `public.users` and the `avatars` bucket/policies — no
  tracked source contains them; both are reconstructed from indirect evidence only.
  If either had columns/policies the app doesn't currently touch, those are lost for good.
  This is the one category of true, unrecoverable data loss from this audit.
- Any **data** that lived in the old project (user accounts, tasks, semesters, etc.) —
  out of scope for a schema recovery; SQL migrations only rebuild structure, not rows.
- Whatever the *actual original* `mood_logs`/`study_sessions` RLS policy text was where
  two policies of the same functional effect but different literal SQL coexist (§ RLS
  table above) — functionally inert, but if you had custom tooling asserting on exact
  policy names/text, note the duplication.
