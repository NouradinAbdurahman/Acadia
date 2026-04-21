-- Ensure study_sessions.course_id relation to courses exists for reliable joins.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema = kcu.table_schema
    WHERE tc.table_schema = 'public'
      AND tc.table_name = 'study_sessions'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND kcu.column_name = 'course_id'
  ) THEN
    ALTER TABLE public.study_sessions
      ADD CONSTRAINT fk_course
      FOREIGN KEY (course_id)
      REFERENCES public.courses(id)
      ON DELETE CASCADE;
  END IF;
END $$;