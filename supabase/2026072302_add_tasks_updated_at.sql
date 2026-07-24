-- Backfill migration: public.tasks.updated_at is read and written by the app
-- (lib/models/task.dart fromJson/toJson, lib/services/supabase/task_service.dart
-- completeAllTasksForDeadline) but no migration or schema.sql ever adds it.
-- CONFIRMED gap: direct read + write evidence in app code, column absent from
-- every tracked CREATE/ALTER TABLE public.tasks statement.
--
-- Order-independent: no other migration touches this column, so this file can
-- run any time after schema.sql creates public.tasks.

alter table public.tasks
add column if not exists updated_at timestamp with time zone default now();
