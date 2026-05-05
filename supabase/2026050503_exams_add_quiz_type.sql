ALTER TABLE public.exams DROP CONSTRAINT IF EXISTS exams_type_check;

ALTER TABLE public.exams
ADD CONSTRAINT exams_type_check
CHECK (type IN ('midterm', 'final', 'quiz'));
