# Acadia

Acadia is a Flutter-based academic productivity app that helps students plan coursework, track deadlines, log study sessions, and monitor learning habits.

It combines:
- A modern cross-platform Flutter client
- Supabase Auth + Postgres backend
- Riverpod state management
- Hive local persistence for app settings

## Core Features

- Authentication with email/password and OTP verification flows
- Multi-step onboarding (language, welcome, academic profile)
- Course and semester management
- Task and deadline planning
- Study timer with session logging
- Dashboard insights built from real activity data
- Profile settings, avatar upload, localization, and theming

## Tech Stack

- Flutter (Dart SDK ^3.10.4)
- flutter_riverpod (state management + dependency injection)
- go_router (navigation and route guards)
- supabase_flutter (auth, database, storage)
- hive + hive_flutter (local key-value persistence)
- flutter_localizations + intl (i18n)
- google_fonts, lottie, flutter_animate (UI/UX)

## Project Architecture

The app follows a layered architecture:

1. UI layer: screens, widgets, reusable components
2. State layer: Riverpod providers and state notifiers
3. Domain/data layer: repositories and models
4. Infrastructure layer: Supabase services + local storage

Data flow:

UI -> Provider/Notifier -> Repository -> Service -> Supabase

## Folder Structure

```text
lib/
	main.dart                  # App bootstrap and routing
	components/                # Reusable UI elements
	core/                      # Design tokens and theme
	l10n/                      # Localization ARB and generated classes
	models/                    # Domain models
	providers/                 # Riverpod providers and notifiers
	repositories/              # Data access abstractions
	screens/                   # Feature screens (auth, home, tasks, etc.)
	services/                  # Supabase and storage services
	utils/                     # Utility classes

assets/                      # Images and Lottie animation files
supabase/                    # SQL schema and migration scripts
android/ ios/ macos/ web/    # Platform runners
linux/ windows/              # Desktop runners
```

## Environment Variables

Create a `.env` file in the project root.

You can copy from `.env.example`:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
APP_ENV=development
API_TIMEOUT=10000
```

Required for startup:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Getting Started

### 1. Install Flutter and dependencies

Make sure Flutter is installed and on your PATH.

```bash
flutter --version
```

Then fetch packages:

```bash
flutter pub get
```

### 2. Configure environment

Create `.env` from `.env.example` and set your Supabase project values.

### 3. Configure Supabase database

Run the SQL files in the Supabase dashboard SQL editor (or your migration workflow), in this order:

1. `supabase/schema.sql`
2. `supabase/2026031602_academic_structure_updates.sql`
3. `supabase/2026031603_semester_structure.sql`
4. `supabase/2026031604_foundation_updates.sql`
5. `supabase/2026031605_foundation_hardening.sql`

These scripts create/update tables, constraints, and row-level security policies.

### 4. Run the app

```bash
flutter run
```

Run on a specific platform:

```bash
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

## Localization

Localization config is in `l10n.yaml`.

Supported locales currently include:
- English (`en`)
- Turkish (`tr`)

To regenerate localization files:

```bash
flutter gen-l10n
```

## State and Routing Notes

- Routing is centralized in `main.dart` using `go_router`.
- Route guards enforce:
	- settings preload
	- auth state
	- language selection
	- onboarding completion
	- academic profile completion
- Riverpod providers are composed in `providers/app_providers.dart`.

## Common Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter build ios
flutter build web
```

## Development Tips

- Keep business logic in providers/repositories, not UI widgets.
- Keep Supabase calls in `services/supabase/`.
- Update model mappings when schema fields change.
- If you change onboarding/auth flow, review route redirect logic in `main.dart`.

## Security and Data Access

- Database access relies on Supabase Row Level Security (RLS).
- Most tables are user-scoped by `auth.uid() = user_id` policies.
- Ensure any new table has both RLS enabled and policies defined.

## Current Status

The app is functionally structured and ready for iterative feature development. The previous placeholder README has been replaced with contributor-focused project documentation.
