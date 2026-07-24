-- Backfill public.users.email from auth.users for rows missing it.
--
-- Root cause: AuthRepository.verifyOTP() (the email/password signup
-- confirmation path) upserted into public.users with only `id` and
-- `academic_profile_completed`, never `email`. AppUser.fromJson assigned
-- json['email'] directly to a non-nullable String field, so any account
-- created this way made currentAppUserProvider throw on every fetch —
-- which the router's redirect logic treats identically to "no profile yet",
-- permanently trapping the account on /academic-onboarding regardless of
-- what was submitted. Fixed at the source in auth_repository.dart (both
-- verifyOTP's upsert and ensurePublicUserRowIfMissing's backfill branch)
-- and defensively in AppUser.fromJson. This statement repairs rows already
-- affected before that fix landed.

update public.users u
set email = au.email
from auth.users au
where u.id = au.id
  and u.email is null;
