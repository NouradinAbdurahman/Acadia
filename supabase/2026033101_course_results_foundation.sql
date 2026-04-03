-- Foundation for manual course exam/result tracking.
-- This module stores official values entered by the user exactly as provided.

CREATE TABLE IF NOT EXISTS public.course_results (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  semester text NOT NULL,
  final_average numeric,
  letter_grade text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.course_result_components (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  result_id uuid NOT NULL REFERENCES public.course_results(id) ON DELETE CASCADE,
  title text NOT NULL,
  score numeric NOT NULL,
  percentage numeric NOT NULL
);

CREATE INDEX IF NOT EXISTS course_results_user_semester_idx
  ON public.course_results (user_id, semester);

CREATE INDEX IF NOT EXISTS course_results_course_idx
  ON public.course_results (course_id);

CREATE INDEX IF NOT EXISTS course_result_components_result_idx
  ON public.course_result_components (result_id);

ALTER TABLE public.course_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_result_components ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'course_results'
      AND policyname = 'Users manage own course results'
  ) THEN
    CREATE POLICY "Users manage own course results"
      ON public.course_results
      FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'course_result_components'
      AND policyname = 'Users manage own result components'
  ) THEN
    CREATE POLICY "Users manage own result components"
      ON public.course_result_components
      FOR ALL
      USING (
        EXISTS (
          SELECT 1
          FROM public.course_results r
          WHERE r.id = course_result_components.result_id
            AND r.user_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.course_results r
          WHERE r.id = course_result_components.result_id
            AND r.user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'update_course_results_updated_at'
  ) THEN
    CREATE TRIGGER update_course_results_updated_at
    BEFORE UPDATE ON public.course_results
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
  END IF;
END $$;

