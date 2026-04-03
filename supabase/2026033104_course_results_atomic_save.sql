-- Atomic save for course result and its grading components.
-- This replaces multi-step client-side save logic to prevent partial writes.

CREATE OR REPLACE FUNCTION public.save_course_result_with_components(
  p_user_id uuid,
  p_course_id uuid,
  p_semester_id uuid,
  p_final_average numeric,
  p_letter_grade text,
  p_result_status text,
  p_components jsonb,
  p_result_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_result_id uuid;
BEGIN
  IF p_result_id IS NULL THEN
    INSERT INTO public.course_results (
      user_id,
      course_id,
      semester_id,
      final_average,
      letter_grade,
      result_status
    )
    VALUES (
      p_user_id,
      p_course_id,
      p_semester_id,
      p_final_average,
      p_letter_grade,
      p_result_status
    )
    RETURNING id INTO v_result_id;
  ELSE
    UPDATE public.course_results
    SET
      course_id = p_course_id,
      semester_id = p_semester_id,
      final_average = p_final_average,
      letter_grade = p_letter_grade,
      result_status = p_result_status,
      updated_at = now()
    WHERE id = p_result_id
      AND user_id = p_user_id
    RETURNING id INTO v_result_id;

    IF v_result_id IS NULL THEN
      RAISE EXCEPTION 'Course result not found or not owned by user';
    END IF;

    DELETE FROM public.course_result_components
    WHERE result_id = v_result_id;
  END IF;

  INSERT INTO public.course_result_components (result_id, title, score, percentage)
  SELECT
    v_result_id,
    component->>'title',
    (component->>'score')::numeric,
    (component->>'percentage')::numeric
  FROM jsonb_array_elements(COALESCE(p_components, '[]'::jsonb)) AS component;

  RETURN v_result_id;
END;
$$;
