-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Student Profiles Table (Core Academic Identity)
create table if not exists public.student_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  full_name text,
  university_name text,
  degree_type text,
  major text,
  minor text,
  academic_year integer,
  current_semester integer,
  expected_graduation_year integer,
  study_hours_per_week integer,
  preferred_study_time text,
  break_pattern text,
  timezone text,
  country text,
  onboarding_complete boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Courses Table
create table if not exists public.courses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_name text not null,
  course_code text,
  professor text,
  semester integer,
  credits integer,
  color text,
  created_at timestamp with time zone default now()
);

-- Academic Calendar Table
create table if not exists public.academic_calendar (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  semester integer,
  semester_start date not null,
  semester_end date not null,
  exam_period_start date,
  exam_period_end date,
  created_at timestamp with time zone default now()
);

-- Tasks table (Updated with course_id)
create table if not exists public.tasks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid references public.courses(id) on delete set null,
  title text not null,
  course text, -- Legacy field for string-based courses
  deadline timestamp with time zone,
  priority text,
  estimated_time integer,
  status text default 'pending',
  notes text,
  created_at timestamp with time zone default now()
);

-- Ensure course_id exists if table was already created
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='tasks' and column_name='course_id') then
    alter table public.tasks add column course_id uuid references public.courses(id) on delete set null;
  end if;
end $$;

-- Study Sessions
create table if not exists public.study_sessions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  session_type text not null check (session_type in ('pomodoro','deep_work','review')),
  duration_minutes integer not null,
  created_at timestamp with time zone default now()
);

-- Academic Deadlines
create table if not exists public.academic_deadlines (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  course text not null,
  deadline_date timestamp with time zone not null,
  deadline_type text not null check (
    deadline_type in ('assignment','exam','quiz','project')
  ),
  priority text not null check (
    priority in ('low','medium','high')
  ),
  notes text,
  created_at timestamp with time zone default now()
);

-- Link tasks (work units) to academic deadlines (targets), optional
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'tasks' and column_name = 'deadline_id') then
    alter table public.tasks add column deadline_id uuid references public.academic_deadlines(id) on delete set null;
  end if;
end $$;

-- Exams
create table if not exists public.exams (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course text,
  exam_date timestamp with time zone,
  weight integer,
  created_at timestamp with time zone default now()
);

-- Mood and Stress Logs
create table if not exists public.mood_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mood text,
  stress_level integer check (stress_level >= 1 and stress_level <= 10),
  note text,
  created_at timestamp with time zone default now()
);

-- Analytics Table
create table if not exists public.analytics (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  performance_score integer,
  workload_density integer,
  burnout_risk integer,
  week_start date,
  created_at timestamp with time zone default now()
);

-- Row Level Security (RLS) Setup
alter table public.student_profiles enable row level security;
alter table public.courses enable row level security;
alter table public.academic_calendar enable row level security;
alter table public.tasks enable row level security;
alter table public.study_sessions enable row level security;
alter table public.academic_deadlines enable row level security;
alter table public.exams enable row level security;
alter table public.mood_logs enable row level security;
alter table public.analytics enable row level security;

-- RLS Policies
create policy "Users can view own profile" on public.student_profiles for select using (auth.uid() = user_id);
create policy "Users can update own profile" on public.student_profiles for update using (auth.uid() = user_id);
create policy "Users can insert own profile" on public.student_profiles for insert with check (auth.uid() = user_id);

create policy "Users can access own courses" on public.courses for all using (auth.uid() = user_id);
create policy "Users can access own calendar" on public.academic_calendar for all using (auth.uid() = user_id);
create policy "Users can access own tasks" on public.tasks for all using (auth.uid() = user_id);
create policy "Users can access own sessions" on public.study_sessions for all using (auth.uid() = user_id);
create policy "Users can access own deadlines" on public.academic_deadlines for all using (auth.uid() = user_id);
create policy "Users can access own exams" on public.exams for all using (auth.uid() = user_id);
create policy "Users can access own mood logs" on public.mood_logs for all using (auth.uid() = user_id);
create policy "Users can access own analytics" on public.analytics for all using (auth.uid() = user_id);

-- Updated at Trigger Function
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language 'plpgsql';

create trigger update_student_profiles_updated_at
before update on public.student_profiles
for each row execute procedure update_updated_at_column();
