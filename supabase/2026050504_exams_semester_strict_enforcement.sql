-- Strict semester isolation for exams.
-- This migration is safe for already-deployed environments.

-- 1) Backfill semester_id for legacy rows.
UPDATE public.exams e
SET semester_id = s.id
FROM public.semesters s
WHERE e.semester_id IS NULL
  AND s.user_id = e.user_id
  AND s.is_current = true;

UPDATE public.exams e
SET semester_id = (
  SELECT s.id
  FROM public.semesters s
  WHERE s.user_id = e.user_id
  ORDER BY s.created_at DESC
  LIMIT 1
)
WHERE e.semester_id IS NULL;

-- 2) Enforce non-null semester ownership.
ALTER TABLE public.exams
  ALTER COLUMN semester_id SET NOT NULL;

-- 3) Ensure composite target for strict semester-user linkage.
ALTER TABLE public.exams
  DROP CONSTRAINT IF EXISTS exams_semester_user_fk;

ALTER TABLE public.semesters
  DROP CONSTRAINT IF EXISTS semesters_id_user_unique;

ALTER TABLE public.semesters
  ADD CONSTRAINT semesters_id_user_unique UNIQUE (id, user_id);

-- 4) Enforce exam.user_id must match semester.user_id.
ALTER TABLE public.exams
  ADD CONSTRAINT exams_semester_user_fk
  FOREIGN KEY (semester_id, user_id)
  REFERENCES public.semesters(id, user_id)
  ON DELETE CASCADE;

-- 5) Keep type constraint aligned with current app values.
ALTER TABLE public.exams
  DROP CONSTRAINT IF EXISTS exams_type_check;

ALTER TABLE public.exams
  ADD CONSTRAINT exams_type_check
  CHECK (type IN ('midterm', 'final', 'quiz'));

-- 6) Optional duplicate protection.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_exam_per_slot
ON public.exams(user_id, semester_id, exam_datetime, title);

-- 7) Strict RLS policy scoped to semester ownership.
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can access own exams" ON public.exams;
DROP POLICY IF EXISTS "Users can access own exams (strict semester)" ON public.exams;

CREATE POLICY "Users can access own exams (strict semester)"
  ON public.exams
  FOR ALL
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.semesters s
      WHERE s.id = semester_id
        AND s.user_id = auth.uid()
    )
  );
