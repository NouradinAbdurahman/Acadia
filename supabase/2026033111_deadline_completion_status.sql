alter table public.academic_deadlines
add column if not exists is_completed boolean not null default false;

alter table public.academic_deadlines
add column if not exists completed_at timestamp with time zone;

create index if not exists idx_academic_deadlines_user_completed
on public.academic_deadlines(user_id, is_completed);
