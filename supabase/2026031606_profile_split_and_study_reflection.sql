-- Profile split correction + study reflection support

-- 1) Ensure study_sessions supports reflection metadata.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'study_sessions'
      AND column_name = 'reflection_tag'
  ) THEN
    ALTER TABLE public.study_sessions ADD COLUMN reflection_tag text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'study_sessions'
      AND column_name = 'reflection'
  ) THEN
    ALTER TABLE public.study_sessions ADD COLUMN reflection text;
  END IF;
END $$;

-- 2) Safety backfill for legacy/null session_type values.
UPDATE public.study_sessions
SET session_type = 'deep_work'
WHERE session_type IS NULL;

UPDATE public.study_sessions
SET session_type = 'deep_work'
WHERE session_type = 'deep_focus';

-- 3) Keep academic fields in student_profiles, not users.
UPDATE public.student_profiles sp
SET
  university_name = COALESCE(sp.university_name, u.university),
  major = COALESCE(sp.major, u.major),
  degree_type = COALESCE(sp.degree_type, u.degree_type),
  minor = COALESCE(sp.minor, u.minor),
  current_semester = COALESCE(sp.current_semester, u.semester),
  expected_graduation_year = COALESCE(sp.expected_graduation_year, u.graduation_year),
  study_hours_per_week = COALESCE(sp.study_hours_per_week, u.study_hours_week),
  preferred_study_time = COALESCE(sp.preferred_study_time, u.preferred_study_time),
  break_pattern = COALESCE(sp.break_pattern, u.break_pattern)
FROM public.users u
WHERE sp.user_id = u.id;

ALTER TABLE public.users DROP COLUMN IF EXISTS university;
ALTER TABLE public.users DROP COLUMN IF EXISTS major;
ALTER TABLE public.users DROP COLUMN IF EXISTS degree_type;
ALTER TABLE public.users DROP COLUMN IF EXISTS minor;
ALTER TABLE public.users DROP COLUMN IF EXISTS semester;
ALTER TABLE public.users DROP COLUMN IF EXISTS graduation_year;
ALTER TABLE public.users DROP COLUMN IF EXISTS study_hours_week;
ALTER TABLE public.users DROP COLUMN IF EXISTS preferred_study_time;
ALTER TABLE public.users DROP COLUMN IF EXISTS break_pattern;
