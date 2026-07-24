-- Backfill migration: public.course_results.semester (legacy text column,
-- superseded by semester_id per 2026033103_course_results_semester_fk.sql)
-- is NOT NULL with no default. The only INSERT path into this table —
-- the save_course_result_with_components RPC (2026033104) — never sets
-- `semester`, only `semester_id`. Every attempt to save a new course result
-- would fail with a not-null constraint violation on `semester`. Found via
-- proactive audit while fixing the courses.ects gap (same root cause: the
-- original database evolved past what the tracked migration history
-- captured).

alter table public.course_results
alter column semester drop not null;
