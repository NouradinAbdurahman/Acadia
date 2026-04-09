-- Phase 1 Migration: Semester Scoping for Tasks, Sessions, and Deadlines
-- Date: 2026-04-05
-- Goal: Enforce semester-based isolation for core academic data.

-- 1. Extend Schema: Add semester_id columns
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS semester_id UUID REFERENCES public.semesters(id) ON DELETE CASCADE;

ALTER TABLE public.study_sessions 
ADD COLUMN IF NOT EXISTS semester_id UUID REFERENCES public.semesters(id) ON DELETE CASCADE;

ALTER TABLE public.academic_deadlines 
ADD COLUMN IF NOT EXISTS semester_id UUID REFERENCES public.semesters(id) ON DELETE CASCADE;

-- Add active_semester_id to student_profiles for global app scoping
ALTER TABLE public.student_profiles 
ADD COLUMN IF NOT EXISTS active_semester_id UUID REFERENCES public.semesters(id) ON DELETE SET NULL;

-- 2. Data Backfill: Populate semester_id based on existing course_id mapping
-- This ensures existing records stay visible under their correct semesters.

-- Backfill Tasks
UPDATE public.tasks t
SET semester_id = c.semester_id
FROM public.courses c
WHERE t.course_id = c.id
AND t.semester_id IS NULL;

-- Backfill Study Sessions
UPDATE public.study_sessions s
SET semester_id = c.semester_id
FROM public.courses c
WHERE s.course_id = c.id
AND s.semester_id IS NULL;

-- Backfill Academic Deadlines
UPDATE public.academic_deadlines d
SET semester_id = c.semester_id
FROM public.courses c
WHERE d.course_id = c.id
AND d.semester_id IS NULL;

-- 3. Orphan Handling: Assign current user semester if available
-- Safety net for tasks/sessions created without specific course associations.
UPDATE public.tasks t
SET semester_id = (
  SELECT id FROM public.semesters s 
  WHERE s.user_id = t.user_id 
  AND s.is_current = true 
  LIMIT 1
)
WHERE t.semester_id IS NULL;

UPDATE public.study_sessions s
SET semester_id = (
  SELECT id FROM public.semesters sem 
  WHERE sem.user_id = s.user_id 
  AND sem.is_current = true 
  LIMIT 1
)
WHERE s.semester_id IS NULL;

UPDATE public.academic_deadlines d
SET semester_id = (
  SELECT id FROM public.semesters sem 
  WHERE sem.user_id = d.user_id 
  AND sem.is_current = true 
  LIMIT 1
)
WHERE d.semester_id IS NULL;

-- 4. Sync Initial Application State
-- Set initial active_semester_id to the user's current semester.
UPDATE public.student_profiles sp
SET active_semester_id = (
  SELECT id FROM public.semesters sem 
  WHERE sem.user_id = sp.user_id 
  AND sem.is_current = true 
  LIMIT 1
)
WHERE sp.active_semester_id IS NULL;

-- 5. Finalize Schema (Optional manual check)
-- Once backfill is verified in Phase 2, NOT NULL constraints can be added for absolute integrity.
-- ALTER TABLE public.tasks ALTER COLUMN semester_id SET NOT NULL;
-- ALTER TABLE public.study_sessions ALTER COLUMN semester_id SET NOT NULL;
