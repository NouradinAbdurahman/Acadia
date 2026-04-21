-- Mood & Stress foundation: semester-scoped mood logs and reminder settings
-- Date: 2026-04-16

-- Ensure mood_logs has the required structure without destructive changes.
create table if not exists public.mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  semester_id uuid not null,
  mood_level int not null check (mood_level between 1 and 5),
  stress_level int not null check (stress_level between 1 and 10),
  energy_level int,
  note text,
  factors text[],
  source text not null default 'manual',
  created_at timestamp with time zone default now()
);

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'semester_id'
  ) then
    alter table public.mood_logs add column semester_id uuid;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'mood_level'
  ) then
    alter table public.mood_logs add column mood_level int;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'energy_level'
  ) then
    alter table public.mood_logs add column energy_level int;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'factors'
  ) then
    alter table public.mood_logs add column factors text[];
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'source'
  ) then
    alter table public.mood_logs add column source text default 'manual';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'mood_logs' and column_name = 'created_at'
  ) then
    alter table public.mood_logs add column created_at timestamp with time zone default now();
  end if;
end $$;

-- Backfill mood_level from legacy mood text when available.
update public.mood_logs
set mood_level = case lower(coalesce(mood, ''))
  when 'very_bad' then 1
  when 'bad' then 2
  when 'neutral' then 3
  when 'good' then 4
  when 'very_good' then 5
  else null
end
where mood_level is null;

-- Backfill source default for legacy rows.
update public.mood_logs
set source = 'manual'
where source is null;

-- Backfill semester_id using user current semester where possible.
update public.mood_logs m
set semester_id = (
  select s.id
  from public.semesters s
  where s.user_id = m.user_id and s.is_current = true
  limit 1
)
where m.semester_id is null;

-- Strengthen constraints once backfill is done.
do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_logs' and constraint_name = 'mood_logs_mood_level_check'
  ) then
    alter table public.mood_logs
      add constraint mood_logs_mood_level_check
      check (mood_level between 1 and 5);
  end if;

  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_logs' and constraint_name = 'mood_logs_stress_level_check'
  ) then
    alter table public.mood_logs
      add constraint mood_logs_stress_level_check
      check (stress_level between 1 and 10);
  end if;

  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_logs' and constraint_name = 'mood_logs_source_check'
  ) then
    alter table public.mood_logs
      add constraint mood_logs_source_check
      check (source in ('manual', 'session'));
  end if;

  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_logs' and constraint_name = 'fk_mood_user'
  ) then
    alter table public.mood_logs
      add constraint fk_mood_user
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;

  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_logs' and constraint_name = 'fk_mood_semester'
  ) then
    alter table public.mood_logs
      add constraint fk_mood_semester
      foreign key (semester_id) references public.semesters(id) on delete cascade;
  end if;
end $$;

-- Enforce not-null after safe backfill.
alter table public.mood_logs alter column mood_level set not null;
alter table public.mood_logs alter column stress_level set not null;
alter table public.mood_logs alter column semester_id set not null;
alter table public.mood_logs alter column source set not null;

create index if not exists idx_mood_user on public.mood_logs(user_id);
create index if not exists idx_mood_semester on public.mood_logs(semester_id);
create index if not exists idx_mood_created_at on public.mood_logs(created_at);

alter table public.mood_logs enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public' and tablename = 'mood_logs' and policyname = 'Users can access own mood logs'
  ) then
    create policy "Users can access own mood logs"
      on public.mood_logs for all
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- Per-user reminder preferences.
create table if not exists public.mood_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reminder_enabled boolean default true,
  reminder_time time,
  reminder_type text default 'both'
);

alter table public.mood_settings enable row level security;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'mood_settings' and constraint_name = 'mood_settings_reminder_type_check'
  ) then
    alter table public.mood_settings
      add constraint mood_settings_reminder_type_check
      check (reminder_type in ('daily', 'session', 'both'));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public' and tablename = 'mood_settings' and policyname = 'Users can access own mood settings'
  ) then
    create policy "Users can access own mood settings"
      on public.mood_settings for all
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;
