-- Add onboarding flag to public.users (managed profile table)
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='users' and column_name='onboarding_complete') then
    alter table public.users add column onboarding_complete boolean default false;
  end if;
end $$;

-- Add is_active flag to courses
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='courses' and column_name='is_active') then
    alter table public.courses add column is_active boolean default true;
  end if;
end $$;

-- Update study sessions check constraint for types
alter table public.study_sessions drop constraint if exists study_sessions_session_type_check;
alter table public.study_sessions add constraint study_sessions_session_type_check 
  check (session_type in ('pomodoro', 'deep_work', 'review', 'practice'));

-- Create Notifications Table
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null, -- 'deadline', 'study_goal', 'task_overdue'
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- Enable RLS for Notifications
alter table public.notifications enable row level security;

-- Notification Policies
drop policy if exists "Users can access own notifications" on public.notifications;
create policy "Users can access own notifications" on public.notifications 
  for all using (auth.uid() = user_id);
