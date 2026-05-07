-- Add all structured session fields to study_sessions.
-- These fields are referenced by StudySession.toJson() and the study service
-- SELECT list but were never added via migration, causing PGRST204 on insert.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'intent') THEN
    ALTER TABLE public.study_sessions ADD COLUMN intent text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'completed') THEN
    ALTER TABLE public.study_sessions ADD COLUMN completed boolean NOT NULL DEFAULT true;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'completed_cycles') THEN
    ALTER TABLE public.study_sessions ADD COLUMN completed_cycles integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'skipped_breaks') THEN
    ALTER TABLE public.study_sessions ADD COLUMN skipped_breaks integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'is_pomodoro') THEN
    ALTER TABLE public.study_sessions ADD COLUMN is_pomodoro boolean NOT NULL DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'total_focus_minutes') THEN
    ALTER TABLE public.study_sessions ADD COLUMN total_focus_minutes integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'total_break_minutes') THEN
    ALTER TABLE public.study_sessions ADD COLUMN total_break_minutes integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'cycles_completed') THEN
    ALTER TABLE public.study_sessions ADD COLUMN cycles_completed integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'total_cycles') THEN
    ALTER TABLE public.study_sessions ADD COLUMN total_cycles integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'mood') THEN
    ALTER TABLE public.study_sessions ADD COLUMN mood double precision;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'stress') THEN
    ALTER TABLE public.study_sessions ADD COLUMN stress double precision;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'planned_minutes') THEN
    ALTER TABLE public.study_sessions ADD COLUMN planned_minutes integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'actual_minutes') THEN
    ALTER TABLE public.study_sessions ADD COLUMN actual_minutes integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'started_at') THEN
    ALTER TABLE public.study_sessions ADD COLUMN started_at timestamp with time zone;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'study_sessions' AND column_name = 'ended_at') THEN
    ALTER TABLE public.study_sessions ADD COLUMN ended_at timestamp with time zone;
  END IF;
END $$;
