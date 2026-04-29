-- Cleanup migration: remove legacy users.weekly_study_goal.
-- Weekly goal source of truth is semesters.weekly_study_goal.

ALTER TABLE public.users
DROP COLUMN IF EXISTS weekly_study_goal;

-- Optional (manual, after policy/consumer verification):
-- ALTER TABLE public.users
-- DROP COLUMN IF EXISTS email;
