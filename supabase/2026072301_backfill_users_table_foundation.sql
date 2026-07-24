-- Backfill migration: public.users was originally created outside the tracked
-- migration history (before this repo's "save every SQL change" convention),
-- so no CREATE TABLE for it exists anywhere in supabase/. Reconstructed here
-- from every ALTER TABLE public.users statement across the migration history
-- plus current app usage (lib/repositories/auth_repository.dart,
-- lib/services/storage/avatar_service.dart, lib/services/notification_service.dart).
--
-- IMPORTANT: when rebuilding a database from scratch, this file must run
-- BEFORE 2026031604_foundation_updates.sql (the first migration that ALTERs
-- this table), even though its filename timestamp sorts after the earlier
-- migrations. Apply order: schema.sql -> this file -> all numbered
-- migrations in filename order.

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  avatar_url text,
  academic_profile_completed boolean not null default false,
  onboarding_complete boolean not null default false,
  fcm_token text,
  created_at timestamp with time zone not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can access own row" on public.users;
create policy "Users can access own row" on public.users for all using (auth.uid() = id);
