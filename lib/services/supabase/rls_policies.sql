-- USERS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_select" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;

CREATE POLICY "users_select"
ON public.users FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "users_insert"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);


-- STUDENT PROFILES
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select" ON public.student_profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.student_profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.student_profiles;

CREATE POLICY "profiles_select"
ON public.student_profiles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "profiles_insert"
ON public.student_profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_update"
ON public.student_profiles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- SEMESTERS
ALTER TABLE public.semesters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "semesters_select" ON public.semesters;
DROP POLICY IF EXISTS "semesters_insert" ON public.semesters;
DROP POLICY IF EXISTS "semesters_update" ON public.semesters;
DROP POLICY IF EXISTS "semesters_delete" ON public.semesters;

CREATE POLICY "semesters_select"
ON public.semesters FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "semesters_insert"
ON public.semesters FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "semesters_update"
ON public.semesters FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "semesters_delete"
ON public.semesters FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- COURSES
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "courses_select" ON public.courses;
DROP POLICY IF EXISTS "courses_insert" ON public.courses;
DROP POLICY IF EXISTS "courses_update" ON public.courses;
DROP POLICY IF EXISTS "courses_delete" ON public.courses;

CREATE POLICY "courses_select"
ON public.courses FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "courses_insert"
ON public.courses FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "courses_update"
ON public.courses FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "courses_delete"
ON public.courses FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- TASKS
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tasks_select" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete" ON public.tasks;

CREATE POLICY "tasks_select"
ON public.tasks FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "tasks_insert"
ON public.tasks FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tasks_update"
ON public.tasks FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tasks_delete"
ON public.tasks FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- ACADEMIC DEADLINES (your real table)
ALTER TABLE public.academic_deadlines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "deadlines_select" ON public.academic_deadlines;
DROP POLICY IF EXISTS "deadlines_insert" ON public.academic_deadlines;
DROP POLICY IF EXISTS "deadlines_update" ON public.academic_deadlines;
DROP POLICY IF EXISTS "deadlines_delete" ON public.academic_deadlines;

CREATE POLICY "deadlines_select"
ON public.academic_deadlines FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "deadlines_insert"
ON public.academic_deadlines FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "deadlines_update"
ON public.academic_deadlines FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "deadlines_delete"
ON public.academic_deadlines FOR DELETE
TO authenticated
USING (auth.uid() = user_id);