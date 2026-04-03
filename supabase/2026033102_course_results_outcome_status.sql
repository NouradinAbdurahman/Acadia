-- Add manual outcome status for course results (successful/failed).

ALTER TABLE public.course_results
  ADD COLUMN IF NOT EXISTS result_status text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'course_results_result_status_check'
  ) THEN
    ALTER TABLE public.course_results
      ADD CONSTRAINT course_results_result_status_check
      CHECK (result_status IS NULL OR result_status IN ('successful', 'failed'));
  END IF;
END $$;

