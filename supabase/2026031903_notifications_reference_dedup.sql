-- Add item reference and enforce single notification per item+state.
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS reference_id text;

-- Keep historical rows valid while enforcing uniqueness for new reference-based notifications.
CREATE UNIQUE INDEX IF NOT EXISTS notifications_reference_type_unique
  ON public.notifications (user_id, reference_id, type)
  WHERE reference_id IS NOT NULL;

-- Remove old due-state notifications that cannot be reference-deduplicated.
DELETE FROM public.notifications
WHERE type IN ('due_today', 'due_tomorrow', 'overdue')
  AND reference_id IS NULL;

-- Deduplicate existing rows by keeping the newest row per user/reference/type.
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, reference_id, type
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM public.notifications
  WHERE reference_id IS NOT NULL
)
DELETE FROM public.notifications n
USING ranked r
WHERE n.id = r.id
  AND r.rn > 1;
