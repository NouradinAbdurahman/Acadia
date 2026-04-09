-- Add optional semester scoping to notifications for consistent global semester filtering.

ALTER TABLE public.notifications
ADD COLUMN IF NOT EXISTS semester_id UUID REFERENCES public.semesters(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_notifications_user_semester_created
ON public.notifications(user_id, semester_id, created_at DESC);
