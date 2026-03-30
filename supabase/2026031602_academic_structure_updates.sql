-- Create courses table if not exists (redundancy check)
create table if not exists public.courses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_name text not null,
  course_code text,
  semester integer,
  credits integer,
  color text,
  created_at timestamp with time zone default now()
);

-- Enable RLS for courses
alter table public.courses enable row level security;

-- Course Policies
drop policy if exists "Users can access own courses" on public.courses;
create policy "Users can access own courses" on public.courses for all using (auth.uid() = user_id);

-- Update Tasks Table
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='tasks' and column_name='course_id') then
    alter table public.tasks add column course_id uuid references public.courses(id) on delete set null;
  end if;
end $$;

-- Update Study Sessions Table
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='study_sessions' and column_name='course_id') then
    alter table public.study_sessions add column course_id uuid references public.courses(id) on delete set null;
  end if;
end $$;

-- Update Academic Deadlines Table
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='academic_deadlines' and column_name='course_id') then
    alter table public.academic_deadlines add column course_id uuid references public.courses(id) on delete set null;
  end if;
end $$;

-- Update Exams Table (for completeness)
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='exams' and column_name='course_id') then
    alter table public.exams add column course_id uuid references public.courses(id) on delete set null;
  end if;
end $$;
