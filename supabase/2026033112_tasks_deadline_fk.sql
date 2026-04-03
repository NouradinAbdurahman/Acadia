-- Link tasks to academic deadlines (optional). Existing rows get NULL deadline_id.
alter table public.tasks
add column if not exists deadline_id uuid references public.academic_deadlines(id) on delete set null;

create index if not exists idx_tasks_user_deadline
on public.tasks(user_id, deadline_id)
where deadline_id is not null;
