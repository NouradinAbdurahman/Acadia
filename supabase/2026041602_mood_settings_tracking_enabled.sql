-- Add tracking_enabled toggle to mood_settings for UI control persistence.
-- Date: 2026-04-16

alter table if exists public.mood_settings
add column if not exists tracking_enabled boolean default true;

update public.mood_settings
set tracking_enabled = true
where tracking_enabled is null;
