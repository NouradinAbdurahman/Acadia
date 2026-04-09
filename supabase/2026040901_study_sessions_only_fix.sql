-- Study sessions only migration
-- Use this after the base schema has already been applied.

-- 1. Ensure study_sessions has semester_id
ALTER TABLE public.study_sessions
ADD COLUMN IF NOT EXISTS semester_id uuid;

-- 2. Backfill existing study sessions from their course semester
UPDATE public.study_sessions s
SET semester_id = c.semester_id
FROM public.courses c
WHERE s.course_id = c.id
  AND s.semester_id IS NULL;

-- 3. Fallback to the user's current semester when course mapping is missing
UPDATE public.study_sessions s
SET semester_id = (
  SELECT sem.id
  FROM public.semesters sem
  WHERE sem.user_id = s.user_id
    AND sem.is_current = true
  LIMIT 1
)
WHERE s.semester_id IS NULL;

-- 4. Enforce the relationship to semesters
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'study_sessions'
      AND constraint_name = 'fk_study_sessions_semester'
  ) THEN
    ALTER TABLE public.study_sessions
      ADD CONSTRAINT fk_study_sessions_semester
      FOREIGN KEY (semester_id)
      REFERENCES public.semesters(id)
      ON DELETE CASCADE;
  END IF;
END $$;

-- 5. Add index for semester-scoped queries
CREATE INDEX IF NOT EXISTS idx_study_sessions_semester_id
ON public.study_sessions(semester_id);

-- 6. Lock the column once data is backfilled
ALTER TABLE public.study_sessions
ALTER COLUMN semester_id SET NOT NULL;