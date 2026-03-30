-- Study session history foundation (raw logs only)

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  session_type text NOT NULL,
  duration_minutes integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions
  DROP CONSTRAINT IF EXISTS study_sessions_session_type_check;

ALTER TABLE public.study_sessions
  ADD CONSTRAINT study_sessions_session_type_check
  CHECK (session_type IN ('pomodoro', 'deep_work', 'review'));

CREATE INDEX IF NOT EXISTS study_sessions_user_created_at_idx
  ON public.study_sessions (user_id, created_at DESC);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can see their own sessions" ON public.study_sessions;
CREATE POLICY "Users can see their own sessions"
  ON public.study_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own sessions" ON public.study_sessions;
CREATE POLICY "Users can insert their own sessions"
  ON public.study_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own sessions" ON public.study_sessions;
CREATE POLICY "Users can update their own sessions"
  ON public.study_sessions
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own sessions" ON public.study_sessions;
CREATE POLICY "Users can delete their own sessions"
  ON public.study_sessions
  FOR DELETE
  USING (auth.uid() = user_id);
