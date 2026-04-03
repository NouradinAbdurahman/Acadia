-- Add relational semester reference for course results.
-- Keep legacy `semester` text column for backward compatibility during transition.

ALTER TABLE public.course_results
  ADD COLUMN IF NOT EXISTS semester_id uuid REFERENCES public.semesters(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS course_results_user_semester_id_idx
  ON public.course_results (user_id, semester_id);

-- Optional safe backfill (uncomment if semester names match exactly)
-- UPDATE public.course_results cr
-- SET semester_id = s.id
-- FROM public.semesters s
-- WHERE cr.semester = s.name
--   AND cr.user_id = s.user_id
--   AND cr.semester_id IS NULL;
