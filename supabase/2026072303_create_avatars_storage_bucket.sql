-- Backfill migration: the 'avatars' Storage bucket is used by
-- lib/services/storage/avatar_service.dart (upload + getPublicUrl) but was
-- never created via a tracked migration -- like public.users, it was almost
-- certainly created by hand in the Supabase dashboard.
--
-- CONFIRMED from code: bucket name 'avatars', public (getPublicUrl() is called
-- directly with no signed-URL/token flow, which only works on a public bucket).
-- INFERRED (medium confidence): the exact object policies below. The app only
-- ever uploads to a path prefixed with the user's own auth id
-- ('${user.id}_${timestamp}.$ext'), so policies are scoped to that prefix.
-- The original policies (if any existed beyond Supabase's default) could not
-- be recovered -- verify these match your intent before relying on them.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] is null
    and name like auth.uid()::text || '_%'
  );

drop policy if exists "Users can update their own avatar" on storage.objects;
create policy "Users can update their own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and name like auth.uid()::text || '_%');

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (bucket_id = 'avatars' and name like auth.uid()::text || '_%');
