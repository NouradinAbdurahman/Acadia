-- Foundation hardening migration

-- 1) One-time academic onboarding flag on users table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'academic_profile_completed'
  ) THEN
    ALTER TABLE public.users
      ADD COLUMN academic_profile_completed boolean DEFAULT false;
  END IF;
END $$;

-- Backfill from legacy onboarding flag when available.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'onboarding_complete'
  ) THEN
    UPDATE public.users
    SET academic_profile_completed = true
    WHERE onboarding_complete = true;
  END IF;
END $$;

-- 2) Ensure users table includes editable academic profile fields.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'university') THEN
    ALTER TABLE public.users ADD COLUMN university text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'degree_type') THEN
    ALTER TABLE public.users ADD COLUMN degree_type text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'major') THEN
    ALTER TABLE public.users ADD COLUMN major text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'minor') THEN
    ALTER TABLE public.users ADD COLUMN minor text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'semester') THEN
    ALTER TABLE public.users ADD COLUMN semester integer;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'graduation_year') THEN
    ALTER TABLE public.users ADD COLUMN graduation_year integer;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'study_hours_week') THEN
    ALTER TABLE public.users ADD COLUMN study_hours_week integer;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'preferred_study_time') THEN
    ALTER TABLE public.users ADD COLUMN preferred_study_time text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'break_pattern') THEN
    ALTER TABLE public.users ADD COLUMN break_pattern text;
  END IF;
END $$;

-- 3) Notifications table with strict type checks.
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  is_read boolean DEFAULT false
);

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('deadline', 'task_overdue', 'study_goal', 'system'));

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can access own notifications" ON public.notifications;
CREATE POLICY "Users can access own notifications"
  ON public.notifications
  FOR ALL
  USING (auth.uid() = user_id);

-- 4) Ensure study_sessions has canonical session_type values.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'study_sessions'
      AND column_name = 'session_type'
  ) THEN
    ALTER TABLE public.study_sessions ADD COLUMN session_type text;
  END IF;
END $$;

UPDATE public.study_sessions
SET session_type = 'deep_work'
WHERE session_type IS NULL OR session_type = 'deep_focus';

ALTER TABLE public.study_sessions DROP CONSTRAINT IF EXISTS study_sessions_session_type_check;
ALTER TABLE public.study_sessions
  ADD CONSTRAINT study_sessions_session_type_check
  CHECK (session_type IN ('pomodoro', 'deep_work', 'review', 'practice'));
