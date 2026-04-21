-- Add per-semester weekly study goal as the authoritative planning target.

alter table if exists public.semesters
add column if not exists weekly_study_goal integer default 15;

update public.semesters
set weekly_study_goal = 15
where weekly_study_goal is null;
