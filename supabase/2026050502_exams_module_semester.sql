-- Exams module (semester-scoped) with richer exam fields.

-- Ensure table exists (legacy schema may already exist).
CREATE TABLE IF NOT EXISTS public.exams (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT now()
);

-- Add/upgrade columns for the new module.
ALTER TABLE public.exams
  ADD COLUMN IF NOT EXISTS semester_id uuid REFERENCES public.semesters(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS title text,
  ADD COLUMN IF NOT EXISTS course_id uuid REFERENCES public.courses(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS exam_datetime timestamp with time zone,
  ADD COLUMN IF NOT EXISTS classroom text,
  ADD COLUMN IF NOT EXISTS is_online boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS instructor_name text,
  ADD COLUMN IF NOT EXISTS type text,
  ADD COLUMN IF NOT EXISTS notes text;

-- Backfill from legacy columns if present.
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

UPDATE public.exams
SET title = COALESCE(title, course, 'Exam')
WHERE title IS NULL;

UPDATE public.exams
SET exam_datetime = COALESCE(exam_datetime, exam_date)
WHERE exam_datetime IS NULL;

UPDATE public.exams
SET type = COALESCE(type, 'midterm')
WHERE type IS NULL;

UPDATE public.exams
SET is_online = COALESCE(is_online, false)
WHERE is_online IS NULL;

-- Constrain exam type to supported values.
ALTER TABLE public.exams
  DROP CONSTRAINT IF EXISTS exams_type_check;

ALTER TABLE public.exams
  ADD CONSTRAINT exams_type_check
  CHECK (type IN ('midterm', 'final', 'quiz'));

-- Enforce strict semester scoping at schema level.
ALTER TABLE public.exams
  ALTER COLUMN semester_id SET NOT NULL;

ALTER TABLE public.exams
  DROP CONSTRAINT IF EXISTS exams_semester_user_fk;

ALTER TABLE public.semesters
  DROP CONSTRAINT IF EXISTS semesters_id_user_unique;

ALTER TABLE public.semesters
  ADD CONSTRAINT semesters_id_user_unique UNIQUE (id, user_id);

ALTER TABLE public.exams
  ADD CONSTRAINT exams_semester_user_fk
  FOREIGN KEY (semester_id, user_id)
  REFERENCES public.semesters(id, user_id)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_exams_user_semester_datetime
ON public.exams(user_id, semester_id, exam_datetime);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_exam_per_slot
ON public.exams(user_id, semester_id, exam_datetime, title);

-- Keep RLS enabled and policy present.
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
