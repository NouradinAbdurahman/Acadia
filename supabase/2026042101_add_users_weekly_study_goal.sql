-- Add users.weekly_study_goal as the single source of truth for weekly study goal.

alter table if exists public.users
add column if not exists weekly_study_goal integer default 15;

update public.users
set weekly_study_goal = 15
where weekly_study_goal is null;
