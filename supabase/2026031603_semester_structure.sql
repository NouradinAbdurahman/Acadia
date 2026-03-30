-- Create semesters table
create table if not exists public.semesters (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, -- e.g. "Fall 2024"
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  is_current boolean default false,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.semesters enable row level security;

-- Policies
drop policy if exists "Users can access own semesters" on public.semesters;
create policy "Users can access own semesters" on public.semesters for all using (auth.uid() = user_id);

-- Update courses table to reference semesters
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='courses' and column_name='semester_id') then
    alter table public.courses add column semester_id uuid references public.semesters(id) on delete set null;
  end if;
end $$;

-- Migrate existing courses data if possible (optional, but good for local/dev)
-- Since we are early, we can just allow it to be null for now. 
