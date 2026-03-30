-- Allow dynamic notification types for due status labels.
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (
    type IN (
      'deadline',
      'task_overdue',
      'study_goal',
      'system',
      'due_today',
      'due_tomorrow',
      'overdue'
    )
  );
