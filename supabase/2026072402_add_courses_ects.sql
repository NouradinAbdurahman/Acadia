-- Backfill migration: public.courses.ects was never created by any tracked
-- migration (same class of gap as the users table / tasks.updated_at found
-- during the original recovery audit — added directly in the dashboard on
-- the original, now-deleted database, never saved as SQL). lib/models/course.dart
-- treats `ects` as a required field and lib/screens/courses/create_course_screen.dart
-- always submits it, so every course create/select was failing with
-- PostgrestException 42703 "column courses.ects does not exist".

alter table public.courses
add column if not exists ects integer;
