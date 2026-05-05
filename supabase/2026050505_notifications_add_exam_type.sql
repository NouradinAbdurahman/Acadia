-- Allow exam notifications to be persisted in public.notifications.
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (
    type IN (
      'deadline',
      'deadline_batch',
      'task_overdue',
      'overdue',
      'overdue_batch',
      'study_goal',
      'system',
      'due_today',
      'due_tomorrow',
      'risk',
      'stress',
      'academic_summary',
      'mood',
      'mood_check',
      'exam'
    )
  );
