# Acadia App Documentation

Hey there. If you're reading this, you're probably trying to understand how Acadia works under the hood — maybe you just joined the project, maybe you're coming back after a break, or maybe you're just curious. Either way, this doc is going to walk you through the entire app from start to finish. No shortcuts, no hand-waving. We're going through everything.

---

## Table of Contents

1. [What Is Acadia?](#1-what-is-acadia)
2. [Tech Stack](#2-tech-stack)
3. [How the App Starts Up](#3-how-the-app-starts-up)
4. [Routing and Auth Guards](#4-routing-and-auth-guards)
5. [The Main App Shell](#5-the-main-app-shell)
6. [Architecture Overview](#6-architecture-overview)
7. [State Management — How Providers Work](#7-state-management--how-providers-work)
8. [Models — All 23 of Them](#8-models--all-23-of-them)
9. [Services — The People Who Talk to Supabase](#9-services--the-people-who-talk-to-supabase)
10. [Repositories — The Middle Layer](#10-repositories--the-middle-layer)
11. [Providers — The Full Breakdown](#11-providers--the-full-breakdown)
12. [Domain Logic — The Pure Business Rules](#12-domain-logic--the-pure-business-rules)
13. [Screens — Every Single One](#13-screens--every-single-one)
14. [Database Schema](#14-database-schema)
15. [Supabase Edge Functions](#15-supabase-edge-functions)
16. [The Smart Notification System](#16-the-smart-notification-system)
17. [The AI Assistant](#17-the-ai-assistant)
18. [The Study Timer](#18-the-study-timer)
19. [Mood and Stress Tracking](#19-mood-and-stress-tracking)
20. [Analytics Engine](#20-analytics-engine)
21. [Risk Scoring](#21-risk-scoring)
22. [Decision Engine](#22-decision-engine)
23. [Supabase Realtime](#23-supabase-realtime)
24. [Background Processing](#24-background-processing)
25. [Localization](#25-localization)
26. [UI Component System](#26-ui-component-system)
27. [Security](#27-security)
28. [Environment Variables](#28-environment-variables)
29. [Migration History](#29-migration-history)
30. [Folder Structure](#30-folder-structure)
31. [Common Gotchas and Tips](#31-common-gotchas-and-tips)

---

## 1. What Is Acadia?

Acadia is a Flutter app built for students. The whole point is to give you one place to manage your academic life — your courses, your assignments, your study habits, your mood, everything. It's not just a to-do list. It actually tries to understand how you're doing academically and emotionally, and then gives you suggestions based on that.

Here's what it can do:

- **Sign up and log in** with email/password, verify your email with an OTP code, and reset your password if you forget it
- **Set up your academic profile** — your university, degree, major, expected graduation year
- **Manage semesters** — create them, switch between them, set a weekly study goal for each one
- **Add courses** — with ECTS credits, color coding, and course codes
- **Create tasks and deadlines** — link tasks to courses and deadlines, set priorities, estimate time
- **Use the study timer** — Pomodoro mode with 4 rounds, Deep Work mode, or Review mode. It tracks your focus time and break time separately
- **Log your mood and stress** — pick a mood level, slide the stress and energy bars, pick factors like sleep or workload, add a note if you want
- **See your analytics** — study hours per course, GPA, task completion rate, consistency, burnout risk
- **Get a study recommendation** — the app tells you which course to focus on next and for how long, based on a scoring system
- **Chat with the AI assistant** — ask it questions like "what are my upcoming deadlines?" or "how am I doing?" and it'll pull real data to answer you
- **Get smart notifications** — the app figures out when you actually need a nudge (overdue tasks, high stress, risk alerts) and sends you push notifications without being annoying about it
- **View your dashboard** — a home screen that shows you everything at a glance: mood, study heatmap, tasks, GPA, insights

Everything is scoped to your active semester. That means when you switch from "Fall 2025" to "Spring 2026", all your data views update to show that semester's stuff. It's a pretty core concept in the app.

---

## 2. Tech Stack

Here's everything we're using and why:

| What | Technology | What It Does for Us |
|---|---|---|
| UI Framework | Flutter (Dart SDK ^3.10.4) | Cross-platform app — runs on iOS, Android, web, macOS, Windows, Linux |
| State Management | flutter_riverpod | Holds all our app state, handles dependency injection, auto-rebuilds UI when data changes |
| Routing | go_router | Declarative routing with redirect guards for auth flow |
| Backend | Supabase | Gives us Auth, Postgres database, file storage, real-time subscriptions, and serverless edge functions |
| Push Notifications | Firebase Cloud Messaging | Sends push notifications to Android and iOS devices |
| Local Storage | Hive | Stores settings, theme choice, language, timer state, and burnout history locally on the device |
| Charts | fl_chart | Draws the analytics charts — study trends, GPA over time, mood graphs |
| Animations | Lottie + flutter_animate | Lottie for the onboarding illustrations, flutter_animate for transitions and micro-interactions |
| Icons | Phosphor + Heroicons | Two icon sets we use across the UI |
| Fonts | google_fonts | Custom fonts for the UI |
| Localization | flutter_localizations + intl | Supports English and Turkish, with about 500+ translated strings |
| AI | NVIDIA NIM (Llama 3.1 70B) | The LLM that powers the AI chat assistant when local intent parsing isn't enough |
| Background Work | Workmanager (Android) + BackgroundFetch (iOS) | Runs the smart notification evaluation every 30 minutes in the background |
| OTP Input | pin_code_fields | The pin code input UI for email verification and password reset |
| Image Picker | image_picker + permission_handler | Lets users pick and upload profile avatars |
| Audio | audioplayers | Plays a sound when a Pomodoro round or study session finishes |
| Haptics | haptic_feedback | Vibrates the phone on timer events |
| Shimmer Loading | shimmer | Shows skeleton loading placeholders while data is loading |
| Timezone | timezone | Needed for scheduling local notifications at the right time |

---

## 3. How the App Starts Up

When you tap the app icon, a bunch of things happen before you even see a screen. Here's the exact order, step by step:

**Step 1: Flutter binding**
```dart
WidgetsFlutterBinding.ensureInitialized();
```
This makes sure Flutter's engine is fully initialized before we do anything else. Without this, async stuff before `runApp` would crash.

**Step 2: Firebase**
```dart
await Firebase.initializeApp();
```
We need Firebase running because we use Firebase Cloud Messaging for push notifications. This has to happen early.

**Step 3: Hive**
```dart
await Hive.initFlutter();
await Hive.openBox('settings');
```
Hive is our local key-value store. We open the `settings` box which holds things like the user's theme preference, language choice, onboarding status, auth rate limit timestamps, and burnout history snapshots. This box is used a LOT throughout the app.

**Step 4: Environment variables**
```dart
await dotenv.load(fileName: ".env");
```
We load the `.env` file which contains the Supabase URL, anon key, service role key, and NVIDIA API key. These are secrets that shouldn't be hardcoded in the app.

**Step 5: Supabase**
```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
);
```
This connects to our Supabase backend — the Postgres database, the auth system, the storage buckets, and the real-time subscription engine. Everything the app does data-wise goes through Supabase.

**Step 6: Notification service**
```dart
await NotificationService.init();
```
Sets up the local notification plugin (for showing notifications in the notification shade), initializes timezone data (for scheduling notifications at specific times), requests FCM permissions, sets up the foreground message listener, and registers the background-tap handler so tapping a notification opens the right screen.

**Step 7: Background notification service**
```dart
await BackgroundNotificationService.initialize(
  supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
  supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
);
```
On mobile, this registers a periodic background task that runs every 30 minutes. On Android it uses Workmanager, on iOS it uses BackgroundFetch. This is what lets the app check for overdue tasks and send you a notification even when you're not actively using the app. The Supabase credentials are saved to SharedPreferences so the background task can connect to Supabase independently (it runs in an isolated context, not the main app).

**Step 8: Run the app**
```dart
runApp(const ProviderScope(child: MyApp()));
```
Finally, we wrap the root widget in Riverpod's `ProviderScope` so all providers are available throughout the widget tree.

---

## 4. Routing and Auth Guards

All routing is handled by `go_router` and it's all defined in `main.dart`. The router has a `redirect` function that runs every time the user tries to navigate somewhere. Think of it like a bouncer at a club — it checks if you're allowed to be where you're trying to go, and if not, it sends you somewhere else.

### The Routes

Here are all the routes in the app:

| Path | Screen | What It Shows |
|---|---|---|
| `/splash` | SplashScreen | Loading screen with the logo |
| `/language` | LanguageSelectionScreen | Pick English or Turkish |
| `/login` | LoginScreen | Email/password login form |
| `/signup` | SignupScreen | Registration form |
| `/verify-email` | VerifyEmailScreen | OTP code entry for email verification |
| `/forgot-password` | ForgotPasswordOTPScreen | Enter email for password reset |
| `/forgot-password-code` | ForgotPasswordCodeScreen | Enter OTP code for password reset |
| `/reset-password` | ResetPasswordScreen | Set new password |
| `/onboarding` | OnboardingWelcomeScreen | 4-page intro carousel |
| `/academic-onboarding` | AcademicOnboardingScreen | Academic profile setup wizard |
| `/home` | AppShell | Main app with 5 tabs |
| `/tasks` | TasksListScreen | Tasks and deadlines list |
| `/create-task` | CreateTaskScreen | New task form |
| `/task-detail` | TaskDetailScreen | Task details |
| `/edit-task` | EditTaskScreen | Edit existing task |
| `/create-deadline` | CreateDeadlineScreen | New deadline form |
| `/deadline-detail` | DeadlineDetailScreen | Deadline details |
| `/edit-deadline` | EditDeadlineScreen | Edit existing deadline |
| `/notifications` | NotificationsScreen | Notification inbox |
| `/courses` | CourseManagementScreen | Course list |
| `/semesters` | SemesterManagementScreen | Semester list |
| `/create-course` | CreateCourseScreen | New course form |
| `/course-results` | CourseResultsScreen | Grade records |
| `/course-results/edit` | CourseResultEditorScreen | Grade entry form |
| `/academic-history` | AcademicHistoryScreen | All semesters performance |
| `/profile/edit` | EditAcademicProfileScreen | Edit academic profile |
| `/profile/study-preferences` | StudyPreferencesScreen | Study preferences form |
| `/profile/change-password` | ChangePasswordScreen | Password change form |
| `/mood/log` | LogMoodScreen | Mood logging form |
| `/mood/history` | MoodHistoryScreen | Past mood logs |
| `/settings/mood-stress` | MoodSettingsScreen | Mood tracking settings |

### The Guard Logic

The redirect function checks conditions in this specific order:

**Check 1: Are settings loaded yet?**
If the locale, theme, or onboarding status haven't been read from Hive yet, the app stays on `/splash`. We can't show anything meaningful until we know what language and theme the user picked.

**Check 2: Is the user NOT logged in?**
If there's no Supabase session:
- If language hasn't been selected → redirect to `/language`
- If language is set but onboarding hasn't been completed → redirect to `/onboarding`
- If both are done but the user is trying to go somewhere other than auth screens → redirect to `/login`
- If the user is on `/splash` with no session → redirect to the next logical step in the flow

**Check 3: Is the user logged in but their profile is still loading?**
We need the `AppUser` object from the database to know if they've completed their academic profile. If it's still loading, stay on `/splash`.

**Check 4: Is the academic profile incomplete?**
If the user exists but `academicProfileCompleted` is false, they get sent to `/academic-onboarding`. The only exceptions are if they're already on that screen, or if they're resetting their password or verifying their email.

**Check 5: Is everything done?**
If the user is fully set up and they try to go to `/splash`, any auth screen, `/language`, `/onboarding`, or `/academic-onboarding`, they get redirected to `/home`. No reason to go back to those screens.

The router also listens to Supabase auth state changes through a `GoRouterRefreshStream`. So if the user logs out (session disappears) or logs in (session appears), the router automatically re-evaluates all the guards and redirects accordingly.

---

## 5. The Main App Shell

Once you pass all the guards, you land on the `AppShell` — this is the main container that holds the 5 bottom tabs. It uses an `IndexedStack`, which means all 5 screens are actually alive at the same time; you're just switching which one is visible. This way, when you switch tabs, you don't lose your scroll position or your loaded data.

The tabs are:

| Tab Index | Name | Screen | What You See |
|---|---|---|---|
| 0 | Home | HomeScreen | Dashboard with everything at a glance |
| 1 | Tasks | TasksListScreen | All your tasks and deadlines |
| 2 | Study | StudyScreen | Start a study session or view history |
| 3 | Analytics | AnalyticsScreen | Charts and insights about your performance |
| 4 | Profile | ProfileScreen | Settings, profile editing, preferences |

The bottom navigation bar is a custom widget called `LiquidGlassNavbar` that has a glassmorphism effect — it looks like frosted glass. The current tab is tracked by the `bottomNavProvider`, a simple `StateProvider<int>`.

---

## 6. Architecture Overview

The app is built in layers. Each layer has one job and doesn't try to do things it shouldn't.

```
┌─────────────────────────────────────────┐
│  UI Layer                                │
│  Screens, Widgets, Components            │
│  Only renders stuff and calls providers  │
├─────────────────────────────────────────┤
│  State Layer                             │
│  Riverpod Providers and StateNotifiers   │
│  Holds state, orchestrates operations    │
├─────────────────────────────────────────┤
│  Domain Layer                            │
│  RiskEngine, DecisionEngine, etc.        │
│  Pure business logic, no Flutter/DB     │
├─────────────────────────────────────────┤
│  Repository Layer                        │
│  Maps JSON ↔ Dart Models                │
│  Caching, rate limiting, data validation │
├─────────────────────────────────────────┤
│  Service Layer                           │
│  Raw Supabase queries, FCM, Hive ops     │
│  No models, just Maps and raw data       │
├─────────────────────────────────────────┤
│  Infrastructure                          │
│  Supabase (Postgres, Auth, Storage,      │
│  Realtime, Edge Functions), Firebase     │
└─────────────────────────────────────────┘
```

The data flows down and events flow up:

- **User taps something** → UI calls a method on a provider
- **Provider** does business logic, calls a repository
- **Repository** converts the typed model to a JSON map, calls a service
- **Service** makes the actual Supabase/FCM/Hive call
- **Result comes back** up through service → repository (converts JSON back to model) → provider (updates state) → UI (rebuilds)

The domain layer is special — it's pure Dart. No Flutter imports, no Supabase imports. Just business rules. The `RiskEngine`, `DecisionEngine`, and `PredictionEngine` all live there, and they're consumed by providers but never directly by UI code.

---

## 7. State Management — How Providers Work

We use Riverpod for everything. If you haven't used Riverpod before, the basic idea is:

- A **Provider** is something that holds a value or creates an object
- A **StateNotifierProvider** holds mutable state — you call methods on the notifier to change the state, and any widgets watching it rebuild automatically
- A **FutureProvider** wraps an async operation — it gives you loading/data/error states
- A **Provider** (plain) is for computed values or singleton objects that don't change on their own

### Provider Dependency Layers

The providers form a layered dependency graph. Here's how it stacks up:

```
Layer 1: Infrastructure
  supabaseProvider → all Services → all Repositories
  (defined in app_providers.dart — it's the service registry)

Layer 2: Auth & Identity
  authStateProvider (StreamProvider — watches Supabase auth changes)
    → currentUserProvider (the raw Supabase User object)
      → currentAppUserProvider (the AppUser from the users table)

Layer 3: Session & Profile
  semesterProvider (list of all user's semesters)
    → activeSemesterProvider (the currently selected semester ID — THE KEYSTONE)
      → studentProfileProvider (academic profile data)

Layer 4: Core Data (all scoped to activeSemesterProvider)
  courseProvider — courses for the active semester
  tasksProvider — tasks for the active semester
  deadlinesProvider — deadlines for the active semester
  studySessionsProvider — study sessions for the active semester
  courseResultsProvider — grades for the active semester
  moodLogsProvider — mood logs for the active semester

Layer 5: Analytics (depends on Layer 4 data)
  analyticsProvider — the big one, computes ~25 analytics fields
    → studyAnalyticsProvider — derived study metrics (focus score, burnout, streak)
    → trendProvider — time-series data for charts
    → riskProvider — risk score with trend

Layer 6: Intelligence (depends on analytics + core data)
  decisionProvider — study recommendations
  decisionEngineProvider (V1) — rule-based priority
  decisionEngineV2Provider — multi-factor scored priority
  predictionProvider — future performance predictions

Layer 7: UI Aggregation
  dashboardProvider — aggregates everything for the home screen
```

The most important thing to understand is that **`activeSemesterProvider` is the keystone**. When the user switches semesters, `activeSemesterProvider` changes, which causes all of Layer 4 to refetch their data for the new semester, which causes Layer 5 analytics to recompute, which cascades into Layer 6 intelligence and Layer 7 dashboard. It's a domino effect, and it all happens automatically because of how Riverpod watches dependencies.

### How Providers Watch Each Other

Providers "watch" other providers using `ref.watch()`. This means:

- When a watched provider changes, the watching provider automatically recalculates
- When a provider's value changes, any widgets watching it rebuild
- You can also use `ref.listen()` to run a side effect when a provider changes (like showing a snackbar) without rebuilding

### The Global Refresh

Sometimes you need to force-refresh everything — like after logging in, or when pulling to refresh on the home screen. That's what `globalRefreshProvider` does. It refreshes all providers in the right order:

1. Load semesters first
2. Then in parallel: courses, tasks, deadlines, study sessions, profile, course results
3. Then: analytics (needs the data from step 2)
4. Then: trends, risk, dashboard (need analytics from step 3)

If you try to refresh analytics before the sessions are loaded, you'll get stale data. That's why the order matters.

---

## 8. Models — All 23 of Them

Models are the Dart classes that represent our data. Every model has `fromJson` and `toJson` methods for converting to/from the JSON format that Supabase returns. Here's every single one:

### AppUser
The core user identity. Not the auth user from Supabase — this is our app-level user record from the `users` table.
- `id` — matches the Supabase auth user ID
- `email` — their email
- `name` — display name
- `avatarUrl` — profile picture URL
- `academicProfileCompleted` — whether they've done the academic onboarding (used by the router)
- `weeklyStudyGoal` — default weekly study goal in hours

### StudentProfile
The detailed academic profile. This is where all the stuff from the academic onboarding wizard goes.
- `fullName`, `universityName`, `degreeType`, `major` — who they are academically
- `academicYear`, `currentSemester`, `expectedGraduationYear` — where they are in their studies
- `preferredStudyTime` — "morning", "afternoon", or "night"
- `breakPattern` — "pomodoro", "deep_work", or "mixed"
- `timezone`, `country` — for scheduling notifications at the right time
- `onboardingComplete` — whether the profile is filled out
- `activeSemesterId` — which semester they're currently looking at (this is huge — it drives the whole app)

### Semester
An academic term like "Fall 2025" or "Spring 2026".
- `name` — like "Fall 2025"
- `startDate`, `endDate` — when the semester runs
- `weeklyStudyGoal` — how many hours per week they want to study (default 15)
- `isCurrent` — whether this is marked as the current semester

### Course
A course within a semester.
- `courseName`, `courseCode` — what it's called
- `semesterId` — which semester it belongs to
- `ects`, `credits` — how many credits it's worth (ECTS is the European system)
- `color` — hex color string for UI display (like "#FF5733")
- `isActive` — whether the course is currently active

### Task
An actionable thing the student needs to do.
- `title` — what it is
- `course`, `courseId` — which course it's for (both a text field and a foreign key, for legacy reasons)
- `semesterId` — which semester
- `deadline`, `deadlineId` — optional link to a deadline
- `priority` — "low", "medium", or "high"
- `estimatedTime` — how long they think it'll take
- `status` — "pending" or "completed"
- `notes` — any extra info

### Deadline
An academic due date — an assignment, exam, quiz, or project.
- `title` — what's due
- `course`, `courseId` — which course
- `semesterId` — which semester
- `deadlineDate` — when it's due
- `deadlineType` — "assignment", "exam", "quiz", or "project"
- `priority` — "low", "medium", or "high"
- `isCompleted`, `completedAt` — tracking whether it's done

### StudySession
A record of a study session. This is what the timer creates when you finish studying.
- `courseId` — what course you studied
- `semesterId` — which semester
- `sessionType` — "pomodoro", "deep_work", or "review"
- `durationMinutes` — total time spent
- `isPomodoro` — whether it was a Pomodoro session
- `totalFocusMinutes`, `totalBreakMinutes` — Pomodoro-specific breakdown
- `cyclesCompleted`, `totalCycles` — Pomodoro cycle tracking
- `completedCycles`, `skippedBreaks` — detailed Pomodoro stats
- `mood`, `stress` — mood and stress levels logged after the session
- `intent` — what they were trying to study
- `completed` — whether the session was finished normally

### MoodLog
A mood/stress/energy entry. Can be logged manually or automatically after a study session.
- `moodLevel` — 1 to 5 (very bad to very good)
- `stressLevel` — 1 to 10
- `energyLevel` — 1 to 10 (optional)
- `factors` — list of strings like ["sleep", "workload", "exams"]
- `note` — optional text note
- `source` — "manual" or "session" (where this mood log came from)
- `semesterId` — which semester it belongs to

There's also a legacy model called `MoodModel` that used a string-based mood field instead of an integer level. The `MoodLog.fromJson` includes a conversion function `_legacyMoodToLevel` that maps old string values like "very_bad" to the new 1-5 scale, so we don't lose old data.

### MoodSettings
Per-user configuration for mood tracking.
- `trackingEnabled` — whether mood tracking is on
- `reminderEnabled` — whether they want reminders
- `reminderTime` — when to send the daily reminder (like "20:00")
- `reminderType` — "daily", "session", or "both"

### CourseResult
A grade record for a course in a semester.
- `courseId`, `semesterId` — what course and semester
- `finalAverage` — numeric grade (like 85.5)
- `letterGrade` — like "AA", "BB+", "CC"
- `resultStatus` — "successful" or "failed"
- `components` — list of `CourseResultComponent` (the grading breakdown)

### CourseResultComponent
A piece of the grading breakdown — like "Midterm: 75/30%".
- `title` — "Midterm", "Final", "Homework", etc.
- `score` — the numeric score
- `percentage` — how much it counts toward the final grade

### NotificationModel
An in-app notification.
- `title`, `message` — what it says
- `type` — "deadline", "task_overdue", "study_goal", "system", "due_today", "due_tomorrow", "overdue"
- `referenceId` — points to the entity this notification is about (a task ID, deadline ID, etc.)
- `semesterId` — which semester
- `isRead` — whether the user has seen it

### AnalyticsData
This is a big one. It's a computed aggregate model — it's not stored in the database, it's calculated from raw data. It has about 25 fields:
- `studyHoursPerCourse` — map of course ID to hours studied
- `gradeDistribution` — map of letter grades to counts
- `taskCompletionRate`, `completedTasks`, `totalTasks` — task stats
- `averageGPA` — computed from course results
- `weeklyAverageStudyHours` — self-explanatory
- `totalECTS` — total credits across courses
- `riskScore` — 0-100 risk score
- `avgDailyMood`, `avgDailyStress` — from daily mood logs
- `avgSessionMood`, `avgSessionStress` — from post-session mood logs
- `consistency` — how consistently the user studies
- `studyDeficit` — how far behind the weekly study goal they are
- `stressTrend`, `isStressRising` — whether stress is going up or down
- `overdueTasks`, `upcomingTasks`, `dueSoonTasks` — task urgency counts
- `studyGoal` — the weekly study goal in hours
- `hasData` — whether there's any data at all (used to show empty states)

### AnalyticsModel
A persisted weekly analytics snapshot. This one actually gets stored in the `analytics` table.
- `performanceScore`, `workloadDensity`, `burnoutRisk` — weekly metrics
- `weekStart` — which week this snapshot covers

### TrendData
Time-series data for the analytics charts.
- `studyTrend` — map of dates to study hours
- `taskTrend` — map of dates to completed task counts
- `workloadTrend` — map of dates to tasks/deadlines created
- `gradeTrend` — list of grade points over time
- `insights` — list of `TrendInsight` objects (good, warning, or critical messages)
- `studyChangePercent`, `workloadChangePercent` — percent changes
- `taskCompletionRate`, `performanceChange` — aggregate metrics

### SemesterComparison
Compares the current semester to the previous one.
- `current`, `previous` — two `AnalyticsData` objects
- `previousSemesterName` — the name of the previous semester
- Computed deltas: `studyTimeDelta`, `focusDelta`, `completionRateDelta`, `gpaDelta`, `riskDelta`
- `isPerformanceImproving` — boolean
- `generateInsights()` — produces human-readable comparison messages

### PerformanceSummary
Lifetime academic performance across all semesters.
- `bestSemester`, `worstSemester`, `mostImprovedSemester` — `Semester` objects
- `highestGpa`, `lowestGpa`, `improvementDelta` — GPA extremes
- `totalCreditsEarned` — across all semesters
- `history` — list of `SemesterPerformance` (semester + its analytics)

### DecisionSnapshot
The output of the decision engine — what the app recommends you study.
- `nextAction` — `DecisionNextAction` (which course, how long, why, confidence level)
- `focusRecommendation` — `DecisionFocusRecommendation` (which course needs attention)
- `whatChanged` — `DecisionWhatChanged` (what's different from last week: study, task load, performance)

### HeatmapDay
A single day in the study heatmap calendar.
- `date` — which day
- `totalMinutes` — minutes studied that day
- `sessionsCount` — how many sessions
- `score` — composite score (minutes + sessions * 5)

### AiMessage
A chat message in the AI assistant.
- `text` — the message content
- `isUser` — whether it's from the user or the assistant
- `type` — "text" or other types for structured responses
- `data` — structured data payload (like a list of tasks)
- `intent` — which intent was detected
- `summaryMetadata` — metadata about summary responses
- `suggestions` — quick-action chip suggestions
- `displayedText` — mutable string used for the typing animation effect

### AiIntent
The parsed intent from a user's chat message.
- `type` — "getTasksByTimeRange", "getCompletedTasks", "getUpcomingDeadlines", "getStudySummary", "getProgress", "getRiskStatus", or "unknown"
- `filter` — `AiFilter` with optional time range, completion status, and course filter
- `originalMessage` — the raw text the user typed

### ExamModel
An exam record.
- `course` — text field for the course name
- `examDate` — when the exam is
- `weight` — how much it counts

### AcademicCalendarModel
Semester calendar boundaries.
- `semesterStart`, `semesterEnd` — when the semester runs
- `examPeriodStart`, `examPeriodEnd` — when exams are

---

## 9. Services — The People Who Talk to Supabase

Services are the lowest layer that actually makes API calls. They don't know anything about models — they just send and receive raw JSON maps. Here's every service and what it does:

### Supabase Services (in `services/supabase/`)

**AuthService** — Wraps Supabase Auth.
- `login(email, password)` — signs in with password
- `signUp(email, password)` — creates an account
- `logout()` — signs out
- `sendPasswordResetOTP(email)` — triggers a password reset email
- `verifyPasswordResetOTP(email, code)` — verifies the OTP code
- `updatePasswordAfterOTP(email, sessionToken, newPassword)` — sets the new password after OTP verification
- `verifyOTP(email, token, type)` — general OTP verification
- `resendOTP(email, type)` — resends the code
- `getUserProfile(userId)` — reads from the `users` table
- `updateWeeklyStudyGoal(userId, goal)` — updates the weekly study goal

**CourseService** — CRUD for courses.
- `getCourses(semesterId)`, `createCourse(data)`, `updateCourse(id, data)`, `deleteCourse(id)`

**CourseResultService** — Grades and components.
- `getResultsBySemester(userId, semesterId)` — fetches results with nested components and joined course data
- `getResultById(userId, resultId)` — single result
- `saveResultWithComponents(...)` — calls the Supabase RPC function `save_course_result_with_components` to atomically save a result and its grading components
- `deleteResult(userId, resultId)`

**DeadlineService** — CRUD for academic deadlines.
- `getDeadlines(userId, semesterId)`, `createDeadline(data)`, `updateDeadline(id, data)`, `deleteDeadline(id)`
- `markDeadlineCompleted(id, isCompleted)` — toggles completion and sets/clears the `completed_at` timestamp

**ExamService** — CRUD for exams.
- `getExams()`, `createExam(data)`, `updateExam(id, data)`, `deleteExam(id)`

**MoodService** — Mood logs and settings.
- `insertMood(data)` — inserts a mood log. Has a fallback for legacy databases that use string moods instead of integer levels
- `getMoodLogs(semesterId)` — fetches mood logs. Falls back to an unfiltered query if `semester_id` column doesn't exist yet
- `getMoodSettings(userId)` — reads mood settings, returns null if the table doesn't exist
- `upsertMoodSettings(data)` — creates or updates mood settings

**NotificationService (Supabase)** — In-app notification CRUD.
- `getNotifications(userId, semesterId)`, `markAsRead(id)`, `markAllAsRead(ids)`, `createNotification(payload)`

**SemesterService** — CRUD for semesters.
- `getSemesters()`, `createSemester(data)`, `updateSemester(id, data)`, `deleteSemester(id)`

**StudyService** — Study session CRUD.
- `getSessions(userId, semesterId)` — last 50 sessions with joined course data
- `createSession(data)`, `updateSession(id, data)`

**StudentProfileService** — Academic profile management.
- `getProfile()` — reads from `student_profiles`
- `createOrUpdateProfile(profile)` — upserts profile data, also syncs the name to the `users` table. Has a safety guard to prevent accidentally writing `active_semester_id` through this service
- `markOnboardingComplete()` — sets `onboarding_complete = true` in `student_profiles` and `academic_profile_completed = true` in `users`

**SemesterStateService** — Manages the active semester.
- `getActiveSemesterId()` — reads `active_semester_id` from `student_profiles`
- `updateActiveSemester(semesterId)` — writes it

**AnalyticsService** — Aggregation queries for analytics.
- `getStudySessions(userId, startDate, semesterId)` — with joined course names and colors
- `getTasks(userId, semesterId)`, `getCourses(semesterId)`, `getCourseResults(userId, semesterId)`, `getSemester(semesterId)`, `getMoodLogs(userId, startDate)`, `getUserSettings(userId)`

**TrendService** — Time-series queries for charts.
- `getStudySessions(userId, since, semesterId)`, `getCompletedTasks(userId, since, semesterId)`, `getCreatedTasks(userId, since, semesterId)`, `getCreatedDeadlines(userId, since, semesterId)`, `getCourseResults(userId, since, semesterId)`

**AiAssistantService** — Talks to the `acadia-ai` Edge Function.
- `sendMessage(history, semesterId, moodContext)` — sends the last 6 messages as conversation history, with a 30-second timeout

### Other Services

**AvatarService** (in `services/storage/`) — Handles avatar uploads.
- `uploadAvatar(file)` — uploads to the `avatars` Supabase Storage bucket, gets the public URL, and updates `avatar_url` in the `users` table

**NotificationService** (root level) — The big notification orchestrator.
- `init()` — sets up local notification channels, FCM permissions, foreground listener, background-tap handler
- `sendSmartNotification(...)` — the main send method. Runs anti-spam checks, adapts priority based on user behavior, writes to Supabase inbox, calls the `send-push` Edge Function, and shows the local notification
- `enqueueSmartNotification(...)` — higher-level entry point that also writes to the Supabase inbox first
- `scheduleCompletion(...)` — schedules a "Session Complete" notification at a future time
- `scheduleDailyMoodReminder(time)` / `cancelDailyMoodReminder()` — for the daily mood reminder
- `isNightTime()` — returns true if before 7am or after 10pm
- Has anti-spam logic: cooldown timers per notification type, daily rate limits (max 5/day, max 2 high-priority)

**NotificationConfig** — Per-type notification settings.
- Predefined configs: `risk` (6h cooldown, critical, night OK), `overdue` (4h, critical, night OK), `deadline` (12h, non-critical), `academic_summary` (24h, silent), `stress` (12h, non-critical)

**NotificationBehaviorService** — Tracks how the user interacts with notifications.
- `recordSent(type)`, `recordOpened(type)` — counters per type
- `ignoredTooMuch(type)` — true if ignored count > 3
- `userEngages(type)` — true if opened > 50% of sent
- `canSendDaily()`, `canSendHighPriority()` — rate limit checks
- All stored in SharedPreferences

**SmartNotificationEngine** — Decides what to notify about.
- `evaluate({analytics, tasks, fetchTasks})` — the main decision point
- Checks: overdue tasks, tasks due within 24h, risk score >= 70, avg stress >= 7
- If multiple items need attention, sends a batched `academic_summary` instead of spamming individual notifications

**NotificationIntelligenceService** — A facade that wraps the above.
- `evaluateForeground(...)`, `evaluateBackground(...)` — clean entry points
- `configFor(type)`, `shouldDeferDelivery()`, `isCritical(type)`, `isSilent(type)`

**BackgroundNotificationService** — Periodic background evaluation.
- On mobile: registers Workmanager (Android) and BackgroundFetch (iOS) tasks that run every 30 minutes
- `runEvaluation()` — re-initializes Supabase, fetches fresh analytics and tasks, runs the notification intelligence
- On web/desktop: no-op stub

**AiIntentParser** (in `services/ai/`) — Regex-based natural language understanding.
- `parse(message)` — detects intent type, time range, and course name from free-text user messages
- Uses regex patterns like "tasks.*today", "deadlines.*this week", "how am I doing"

**AiDataResolver** (in `services/ai/`) — Executes resolved intents.
- `resolve(intent, userId, semesterId)` — dispatches based on intent type
- For task/deadline intents, fetches real data from repositories and formats human-readable responses
- For risk status, re-runs `RiskEngine.calculate()`

---

## 10. Repositories — The Middle Layer

Repositories sit between providers and services. Their job is to convert raw JSON maps from services into typed Dart model objects, and vice versa. They also handle things like caching, rate limiting, and stripping auto-generated fields before inserts.

Here's a quick summary of all 13:

| Repository | Table(s) | What It Does Special |
|---|---|---|
| AuthRepository | `users` + Auth | Rate limiting with exponential backoff (persisted in Hive), OTP verification with user table upsert |
| CourseRepository | `courses` | Clean CRUD, nothing special |
| CourseResultRepository | `course_results` | Atomic save via RPC function, manual component decomposition |
| DeadlineRepository | `academic_deadlines` | Partial update via patch maps, completion toggle |
| ExamRepository | `exams` | Clean CRUD |
| MoodRepository | `mood_logs`, `mood_settings` | Insert + upsert settings |
| NotificationRepository | `notifications` | Read + create + mark read (no delete) |
| SemesterRepository | `semesters` | Clean CRUD |
| StudyRepository | `study_sessions` | Create + read + update (no delete) |
| TaskRepository | `tasks` | Full CRUD + by-deadline query, re-adds `deadline_id` on update |
| TrendRepository | 5 tables (read-only) | Computes time-series maps + insight messages |
| AnalyticsRepository | 7 tables (read-only) | 10-second per-semester cache, `computeFromPreloaded` avoids duplicate DB calls, parallel-fetch deduplication |
| AiAssistantRepository | Edge Function | Maps Edge Function response to `AiMessage` |

The `AnalyticsRepository` is worth talking about more because it's the most complex one. It has two code paths:

1. **`getAnalyticsData(userId, semesterId)`** — Full fetch from the database. Has a 10-second TTL cache per semester ID and deduplication of parallel fetches (if two providers ask for the same semester's analytics at the same time, only one DB call happens).

2. **`computeFromPreloaded({userId, semesterId, sessions, tasks, moodLogs})`** — This one's smart. It takes already-loaded typed Dart models (which the providers already fetched) and only hits the DB for the remaining data (courses, results, settings, semester). This avoids making duplicate queries when the data is already in memory.

Both paths produce the same `AnalyticsData` model with the same ~25 computed fields. The only difference is where the input data comes from.

---

## 11. Providers — The Full Breakdown

This is the longest section because providers are where most of the app's logic lives. There are 29 provider files. Let me go through the important ones.

### app_providers.dart — The Service Registry

This file is where all services and repositories are wired up. It defines providers for:
- The Supabase client singleton
- All 14 Supabase services (auth, course, course result, deadline, exam, mood, notification, semester, study, student profile, semester state, analytics, trend, AI assistant)
- The avatar service
- The AI intent parser and data resolver
- All 13 repositories
- The auth state stream provider
- The current user and app user providers

It's basically the dependency injection container. Everything gets created here and other providers reference these providers to get their dependencies.

### analytics_provider.dart — The Analytics Engine

This is the biggest provider file at about 1,386 lines. It contains:

- **`analyticsProvider`** — An `AsyncNotifierProvider` that computes the full `AnalyticsData` object. It has a hash-based cache so it doesn't recompute if the inputs haven't changed. It pulls data from study sessions, tasks, mood logs, deadlines, and course results, all scoped to the active semester.

- **`studyAnalyticsProvider`** — A derived provider that computes study-specific metrics:
  - `focusScore` — how focused the user's sessions are
  - `burnoutScore` / `burnoutLevel` — burnout indicator (low/medium/high/critical)
  - `currentStreak` — consecutive days with study sessions
  - `weeklyConsistency` — how consistently they study each week
  - `pomodoroStats` — Pomodoro-specific statistics
  - `studyTimeBuckets` — study time broken into time-of-day categories
  - `sessionQualityScore` — quality of study sessions
  - `studyProfile` — "consistent", "crammer", "casual", etc.
  - `weeklyDeficitHours` — how far behind the weekly goal they are

- **`burnoutHistoryProvider`** — Tracks the last 14 days of burnout snapshots, persisted in Hive. This lets us show burnout trends over time.

- **`weeklyStudyGoalHoursProvider`** — Reads the study goal from the active semester (or falls back to the user's default).

### study_sessions_provider.dart — The Timer

This one has two major parts:

**StudyTimerNotifier** — The actual timer state machine. It manages:
- `elapsed` — how many seconds have passed
- `isRunning` / `isPaused` — current state
- `sessionType` — "pomodoro", "deep_work", or "review"
- `selectedCourse` — which course is being studied
- For Pomodoro: current round number, total rounds (4), focus/break time accumulation, completed cycles, skipped breaks
- App lifecycle awareness — when the app goes to background and comes back, it calculates the elapsed time from the saved timestamp
- Hive persistence — saves the full timer state to the `timer_state` box so it survives app restarts
- Audio and haptic feedback — plays a sound and vibrates when a round completes
- When the timer finishes, it calls `saveFromTimer()` or `savePomodoroSession()` on the sessions notifier

**StudySessionsNotifier** — Manages the list of study sessions.
- `loadSessions()` — fetches from Supabase
- `saveFromTimer(...)` — creates a session from a completed standard timer
- `savePomodoroSession(...)` — creates a session from a completed Pomodoro session with all the cycle data
- After saving, it refreshes analytics and optionally queues a mood prompt (if mood tracking is enabled and this was a session-based mood)

### tasks_provider.dart — Task Management

- **`tasksProvider`** — `StateNotifierProvider` that manages the task list for the active semester
- **`taskFilterProvider`** — current filter: "all", "pending", "completed", or "overdue"
- **`filteredTasksProvider`** — derived provider that applies the filter and sorts (overdue first, then by deadline date)
- **`tasksTodayCountProvider`** — count of non-completed tasks
- After every CRUD operation, it runs `SmartNotificationEngine.evaluateTaskChanges` to check if a notification should be sent

### deadlines_provider.dart — Deadline Management

- **`deadlinesProvider`** — manages the deadline list for the active semester
- **`filteredDeadlinesProvider`** — derived provider with filtering and sorting
- Supports: create, delete, update, mark complete, toggle completion

### course_provider.dart — Course Management

- **`courseProvider`** — manages courses for the active semester
- **`activeCoursesProvider`** — derived: courses where `isActive == true`
- Includes a legacy semesterId backfill migration (for courses created before we had the `semester_id` column)

### semester_provider.dart — Semester Management

- **`semesterProvider`** — all semesters for the current user
- **`orderedSemestersProvider`** — sorted by start date, active semester first
- **`activeSemesterProvider`** — the keystone. Reads/writes the active semester ID via `SemesterStateService`. When the user switches semesters, this changes, and everything that depends on it refetches.
- **`activeSemesterFullProvider`** — the full `Semester` object (not just the ID)
- **`isSemesterSwitchingProvider`** — guard to prevent double-triggering during a semester switch

### mood_provider.dart — Mood Tracking

- **`moodLogsProvider`** — all mood logs for the active semester
- **`dailyMoodLogsProvider`** — mood logs from daily (non-session) sources
- **`sessionMoodLogsProvider`** — mood logs from post-session prompts
- **`todayMoodProvider`** — whether the user has logged a daily mood today
- **`moodSettingsProvider`** — mood tracking configuration
- **`moodActionsProvider`** — the action handler. Saves mood logs, schedules reminders, queues post-session mood prompts. After saving, it refreshes analytics, risk, and mood providers.
- **`moodPromptRequestProvider`** — a queue for mood prompts (when a study session ends and the user should log their mood)

### dashboard_provider.dart — The Home Screen

- **`dashboardProvider`** — aggregates data from a bunch of other providers into a single `DashboardData` object:
  - `pendingTasksToday`, `overdueTasksCount` — task urgency
  - `upcomingDeadlines` — deadlines coming up
  - `studyMinutesToday`, `weeklyStudyGoalMinutes`, `weeklyStudyCompletedMinutes` — study progress
  - `topCourses` — courses with the most activity
  - `focusSuggestion`, `recommendation` — rule-based suggestions
  - `streakCount`, `streakMessage` — study streak
  - `productivityInsight` — a generated insight message
  - `completedTodayCount`, `sessionsTodayCount` — today's activity

### decision_engine_provider.dart and decision_engine_provider_v2.dart

Two versions of the decision engine:

**V1** (`decisionEngineProvider`) — Rule-based priority:
- If there are overdue tasks → that course gets high priority
- If there are upcoming deadlines → medium priority
- If a course has been studied the least → low priority suggestion
- Has a burnout guard that caps the recommended session duration

**V2** (`decisionEngineV2Provider`) — Multi-factor scoring:
- Each course gets a weighted score: urgency (34%) + deficit (24%) + workload (16%) + ECTS weight (16%) + risk signal (10%)
- Higher score = more important to study
- Generates more sophisticated reason strings

**`decisionEngineActiveProvider`** — prefers V2, falls back to V1 if V2 fails.

### decision_provider.dart — Decision Domain

This one delegates to the `DecisionEngine` class in the domain layer. It takes in analytics, study analytics, mood logs, tasks, deadlines, and localized strings, and produces a `DecisionResult` with:
- Average stress level
- Weekly recommendations
- Decision cards with course-specific suggestions

### risk_provider.dart — Risk Scoring

- **`riskInputProvider`** — aggregates all the inputs needed for risk calculation: overdue tasks, upcoming tasks, total ECTS, study hours, study deficit, grade risk, stress data, consistency
- **`riskProvider`** — computes the current risk score and the previous week's risk score for trend comparison. Uses the `RiskCalculator` from the domain layer.

### trend_provider.dart — Trend Data

- **`trendProvider`** — a family provider parameterized by number of days. Fetches time-series data and computes trend maps and insight messages.

### notifications_provider.dart — Notification Management

- **`notificationsProvider`** — manages the notification list for the active semester. Auto-syncs task/deadline-based notifications via Supabase Realtime subscriptions. When a task becomes overdue, a notification is automatically created. When a deadline is due today or tomorrow, a notification is generated.
- **`unreadNotificationsCountProvider`** — count of unread notifications

### realtime_provider.dart — Supabase Realtime

This is a side-effect-only provider — it doesn't expose any data. It subscribes to Supabase Realtime for 5 tables:
- `tasks` → invalidates `tasksProvider`
- `academic_deadlines` → invalidates `deadlinesProvider`
- `study_sessions` → invalidates `studySessionsProvider`
- `course_results` → invalidates `courseResultsProvider`
- `courses` → invalidates `courseProvider` (also triggers risk recalculation if ECTS changes)

Changes are debounced 250ms to avoid rapid re-computation cascades. Without debouncing, a batch of 10 task updates would trigger 10 analytics recomputations in quick succession.

### Other Notable Providers

- **`localeProvider`** — current locale, persisted in Hive
- **`themeProvider`** — current theme mode (light/dark/system), persisted in Hive
- **`onboardingProvider`** — whether onboarding has been completed, persisted in Hive
- **`bottomNavProvider`** — current tab index
- **`globalRefreshProvider`** — callable that refreshes all data in the correct order
- **`performanceSummaryProvider`** — lifetime performance across all semesters
- **`semesterComparisonProvider`** — current vs. previous semester comparison
- **`predictionProvider`** — delegates to `PredictionEngine` in the domain layer
- **`courseResultsProvider`** — grade records per semester
- **`studentProfileProvider`** — academic profile data

---

## 12. Domain Logic — The Pure Business Rules

The domain layer (`lib/domain/` and `lib/core/services/`) contains pure Dart business logic. No Flutter imports, no Supabase imports. Just algorithms and rules.

### RiskEngine (in `core/services/`)

Calculates a risk score from 0 to 100 based on:
- Overdue task count and severity
- Study deficit (how far behind the weekly study goal)
- Grade risk (bad grades increase risk, good grades decrease it)
  - FF: +15, DD: +8, DC: +5 (penalty)
  - BA: -3, AA: -5 (relief)
- Stress level (higher stress = higher risk)
- Consistency (more consistent study = lower risk)
- Overdue deadline penalty
- Linked task completion relief (if a deadline has completed tasks, risk goes down)
- Recently completed deadline adjustment (if a deadline was just completed, it reduces risk)

The output is a `RiskResult` with:
- `score` — 0-100
- `level` — "low", "moderate", or "high"
- `factors` — list of human-readable risk factor descriptions

### DecisionEngine (in `domain/decision/`)

Evaluates what the student should focus on next. Takes in:
- Analytics data (study hours, consistency, burnout score)
- Study analytics (focus score, deficit, streak)
- Mood logs (daily and session-based)
- Tasks and deadlines
- Localized strings

Outputs a `DecisionResult` with:
- Average stress level
- Weekly recommendations
- Decision cards per course

### PredictionEngine (in `domain/prediction/`)

Generates predictions about future performance. Takes in:
- Analytics data
- Decision result
- Study analytics
- Tasks and deadlines

Outputs a `PredictionResult` with projected outcomes.

### RiskCalculator (in `domain/risk/`)

Used by `risk_provider.dart`. Takes a `RiskInput` and produces a `RiskState` with current risk, previous risk, and trend delta.

### AcademicDeadlineTask (in `domain/`)

Validates relationships between tasks and deadlines — like making sure a task linked to a deadline actually belongs to the same course.

---

## 13. Screens — Every Single One

Here's every screen in the app, grouped by feature area:

### Splash
- **SplashScreen** — Just shows the logo and "Acadia" text. The router redirect handles moving the user to the right next screen.

### Language
- **LanguageSelectionScreen** — Two options: English or Turkish, with flags and check marks. When you pick one, it's saved to Hive and the locale provider updates. After that, you go to onboarding.

### Auth (6 screens)
- **LoginScreen** — Email and password fields, a "remember me" checkbox (Hive-persisted), and a rate-limit countdown if you've tried too many times. On success, goes to `/home`.
- **SignupScreen** — Name, email, password, and confirm password. Has password strength indicator. On success, goes to `/verify-email`.
- **VerifyEmailScreen** — 6-digit OTP code entry with `pin_code_fields`. Has a resend button with a countdown timer. On success, goes to `/academic-onboarding`.
- **ForgotPasswordOTPScreen** — Enter your email to request a password reset. Goes to `/forgot-password-code`.
- **ForgotPasswordCodeScreen** — Enter the OTP code that was sent to your email. Goes to `/reset-password` with the email and session token.
- **ResetPasswordScreen** — Enter a new password and confirm it. Goes to `/login` on success.

### Onboarding (2 screens)
- **OnboardingWelcomeScreen** — A 4-page carousel with Lottie animations explaining the app. You can skip or go through all pages. Marks onboarding as complete in Hive.
- **AcademicOnboardingScreen** — Multi-step wizard: name, university, degree type (Bachelor/Master/PhD), major, expected graduation year, current semester number, and then you create your first semester and courses. On completion, marks `academic_profile_completed = true` and goes to `/home`.

### Home
- **HomeScreen** — The dashboard. Shows: greeting with avatar, mood card (or prompt to log mood), study heatmap, active session card (if timer is running), pending/overdue tasks preview, GPA and course cards, semester comparison, smart insights, and a quick-menu FAB button.
- **QuickMenuScreen** — A modal bottom sheet with quick-action buttons: manage courses, course results, semesters, create course/task/deadline, log mood, start studying, view analytics.

### Tasks (6 screens)
- **TasksListScreen** — Segmented control at the top (Tasks / Deadlines / All), filter chips (All / Pending / Completed / Overdue), and a list of task/deadline cards. Swipe to complete or delete.
- **TaskDetailScreen** — Shows all task details, with edit and delete buttons, and a completion toggle.
- **CreateTaskScreen** — Form with: title, course picker, deadline picker, priority, estimated hours, notes. Can be pre-populated with a deadline ID (when creating a task from a deadline detail screen).
- **EditTaskScreen** — Same form as create, pre-filled with existing data.
- **CreateDeadlineScreen** — Form with: title, course picker, date, type (assignment/exam/quiz/project), priority, notes.
- **EditDeadlineScreen** — Same form as create, pre-filled.
- **DeadlineDetailScreen** — Shows deadline details plus a list of linked tasks. You can create a new task directly from this screen (it auto-links to this deadline). Delete and edit buttons.

### Study (3 screens)
- **StudyScreen** — Two states: if no session is active, shows the setup (pick course, session type, duration) and decision engine suggestions. If a session is active, shows the timer with elapsed time, round info (for Pomodoro), and pause/stop buttons.
- **StudyHistoryScreen** — List of past study sessions filtered by course, grouped by date (Today, Yesterday, This Week, Older).
- **SessionDetailScreen** — Shows a single session's details: focus time, break time, session type, mood logged after, and study analytics insights.

### Analytics (2 screens)
- **AnalyticsScreen** — 4 tabs:
  - **Overview** — GPA card, risk level indicator, task completion rate, study consistency, burnout level
  - **GPA** — GPA chart over time, grade distribution, course results summary
  - **Trends** — Study time trend, workload trend, grade trend, with insight messages
  - **Mood** — Mood and stress trend charts, mood distribution
- **AcademicHistoryScreen** — Lists all semesters with their performance summaries.

### Courses (5 screens + 1)
- **CourseManagementScreen** — Lists courses for the active semester with sort options (by semester, alphabetical, or by study time). Swipe to delete.
- **CreateCourseScreen** — Form: name, code, credits, ECTS, color picker, semester picker. Also used for editing.
- **SemesterManagementScreen** — Lists all semesters. Tap to set as active. Swipe to delete.
- **CreateSemesterScreen** — Form: name, season (Fall/Spring/Summer), academic year, start and end dates. Also used for editing.
- **CourseResultsScreen** — Lists course results grouped by semester, with grade summary.
- **CourseResultEditorScreen** — Form: semester picker, course picker, letter grade, final average, grade type (successful/failed), and grading components (add/remove rows for midterm, final, homework, etc.).

### Mood (2 screens)
- **LogMoodScreen** — Swipeable emoji mood selector (5 levels), stress slider (1-10), energy slider (1-10), factor chips (sleep, workload, health, motivation, social, exams), optional note. When opened from a post-session prompt, it pre-fills the last mood values.
- **MoodHistoryScreen** — Lists mood logs grouped by date, with source filter tabs (All / Daily Baseline / Study Sessions). Tap for a detail bottom sheet.

### Notifications
- **NotificationsScreen** — Lists notifications grouped by time (Today / Tomorrow / Earlier), with category filter chips (All / Tasks / Deadlines / Mood / Academic). Tap to mark as read and navigate to the relevant item (task detail, deadline detail, etc.). Pull to refresh.

### Profile (4 screens)
- **ProfileScreen** — The settings hub. Shows avatar (tap to upload), name, email. Sections: Academic (edit profile, manage courses), Preferences (study preferences, mood settings, language picker, theme toggle), Account (AI assistant, change password, logout).
- **EditAcademicProfileScreen** — Full academic profile edit: name, university, degree, major, graduation year, current semester, weekly study hours slider (5-40), preferred study time, break pattern.
- **StudyPreferencesScreen** — Focused study preferences: weekly study hours, preferred study time, break pattern.
- **ChangePasswordScreen** — Current password, new password with strength indicator, confirm password. Uses Supabase auth directly.

### Settings
- **MoodSettingsScreen** — Enable/disable mood tracking, enable/disable reminders, reminder time picker (24h format), reminder type (daily/session/both), link to mood history.

### AI
- **AIChatScreen** — Chat interface with the AI assistant. Shows message bubbles with typing animation. Quick-action chips at the bottom for common questions.

---

## 14. Database Schema

We have 14 user-facing tables in Postgres, plus the built-in `auth.users` from Supabase. Here's the full breakdown:

### auth.users (Supabase built-in)
The root identity. Every other table references this.

### users
A lightweight app-level user table. Not the auth table — this is our own.
- `id` — matches auth.users ID
- `email`, `name` — basic info
- `avatar_url` — profile picture
- `academic_profile_completed` — whether academic onboarding is done (drives routing)
- `weekly_study_goal` — default study goal

### student_profiles
The detailed academic profile.
- `user_id` — 1:1 with users
- `full_name`, `university_name`, `degree_type`, `major`, `minor` — academic identity
- `academic_year`, `current_semester`, `expected_graduation_year` — progress
- `study_hours_per_week`, `preferred_study_time`, `break_pattern` — study preferences
- `timezone`, `country` — for notification scheduling
- `onboarding_complete` — whether the profile is filled out
- `active_semester_id` — THE KEYSTONE FIELD. This is what determines which semester the app shows data for.
- Auto-updated `updated_at` via trigger

### semesters
- `user_id`, `name`, `start_date`, `end_date`, `is_current`
- `weekly_study_goal` — per-semester study goal (default 15)

### courses
- `user_id`, `semester_id` — ownership and scoping
- `course_name`, `course_code`, `professor` — identity
- `ects`, `credits` — credit hours
- `color` — hex color for UI
- `is_active` — whether the course is currently active
- Has a legacy `semester` integer field (pre-FK era)

### tasks
- `user_id`, `semester_id` — ownership and scoping
- `course_id` — FK to courses (nullable, for when a course is deleted)
- `deadline_id` — FK to academic_deadlines (nullable, for standalone tasks)
- `title`, `course` (legacy text), `deadline` (datetime), `priority`, `estimated_time`, `status`, `notes`
- Status defaults to 'pending', can be 'completed'
- Index on `(user_id, deadline_id)` for deadline-linked task queries

### study_sessions
- `user_id`, `semester_id`, `course_id` — all required
- `session_type` — must be 'pomodoro', 'deep_work', or 'review' (CHECK constraint)
- `duration_minutes` — total duration
- `reflection_tag`, `reflection` — post-session reflection (added later)
- Indexes on `(user_id, created_at DESC)` and `(semester_id)` for fast queries

### academic_deadlines
- `user_id`, `semester_id` — required
- `course_id` — nullable FK to courses
- `title`, `course` (legacy text), `deadline_date`, `deadline_type` (must be assignment/exam/quiz/project), `priority` (must be low/medium/high)
- `is_completed`, `completed_at` — completion tracking
- Index on `(user_id, is_completed)` for filtering

### mood_logs
- `user_id`, `semester_id` — required
- `mood_level` — 1-5 (CHECK constraint)
- `stress_level` — 1-10 (CHECK constraint)
- `energy_level` — optional
- `note`, `factors` (text array), `source` (must be 'manual' or 'session')
- Has a legacy `mood` text field for backward compatibility
- Indexes on `user_id`, `semester_id`, and `created_at`

### mood_settings
- `user_id` — primary key (1:1 with users)
- `tracking_enabled`, `reminder_enabled` — booleans
- `reminder_time` — time of day
- `reminder_type` — must be 'daily', 'session', or 'both'

### notifications
- `user_id`, `semester_id` — required
- `title`, `message`, `type` — content
- `type` — must be one of: 'deadline', 'task_overdue', 'study_goal', 'system', 'due_today', 'due_tomorrow', 'overdue'
- `reference_id` — for deduplication (points to the entity the notification is about)
- `is_read` — boolean
- Partial unique index on `(user_id, reference_id, type) WHERE reference_id IS NOT NULL` — prevents duplicate notifications for the same event

### course_results
- `user_id`, `course_id`, `semester_id` — required
- `letter_grade` — required (like "AA", "BB+")
- `final_average` — numeric grade
- `result_status` — "successful" or "failed" (nullable)
- `semester` — legacy text field
- Auto-updated `updated_at` via trigger

### course_result_components
- `result_id` — FK to course_results (CASCADE delete)
- `title`, `score`, `percentage` — the grading breakdown

### exams
- `user_id`, `course_id` — course link
- `course` (legacy text), `exam_date`, `weight`

### academic_calendar
- `user_id` — ownership
- `semester` (integer), `semester_start`, `semester_end`, `exam_period_start`, `exam_period_end` — all dates

### analytics
- `user_id` — ownership
- `performance_score`, `workload_density`, `burnout_risk` — weekly metrics
- `week_start` — which week

### Foreign Key Relationships Summary

```
auth.users(id)
  ├──< student_profiles.user_id (1:1, CASCADE)
  ├──< semesters.user_id (1:N, CASCADE)
  │     ├──< courses.semester_id (1:N, SET NULL)
  │     ├──< tasks.semester_id (1:N, CASCADE)
  │     ├──< study_sessions.semester_id (1:N, CASCADE)
  │     ├──< academic_deadlines.semester_id (1:N, CASCADE)
  │     ├──< mood_logs.semester_id (1:N, CASCADE)
  │     ├──< notifications.semester_id (1:N, CASCADE)
  │     └──< course_results.semester_id (1:N, CASCADE)
  ├──< courses.user_id (1:N, CASCADE)
  ├──< tasks.user_id (1:N, CASCADE)
  ├──< study_sessions.user_id (1:N, CASCADE)
  ├──< academic_deadlines.user_id (1:N, CASCADE)
  ├──< exams.user_id (1:N, CASCADE)
  ├──< mood_logs.user_id (1:N, CASCADE)
  ├──< mood_settings.user_id (1:1, CASCADE)
  ├──< notifications.user_id (1:N, CASCADE)
  ├──< course_results.user_id (1:N, CASCADE)
  ├──< academic_calendar.user_id (1:N, CASCADE)
  └──< analytics.user_id (1:N, CASCADE)

courses(id)
  ├──< tasks.course_id (1:N, SET NULL)
  ├──< study_sessions.course_id (1:N, CASCADE)
  ├──< academic_deadlines.course_id (1:N, SET NULL)
  ├──< exams.course_id (1:N, SET NULL)
  └──< course_results.course_id (1:N, CASCADE)

academic_deadlines(id)
  └──< tasks.deadline_id (1:N, SET NULL)

course_results(id)
  └──< course_result_components.result_id (1:N, CASCADE)

student_profiles.active_semester_id → semesters(id) (SET NULL)
```

### Row Level Security

Every single table has RLS enabled. Every policy is `auth.uid() = user_id`. Users can only see and modify their own data. The only exception is `course_result_components`, which doesn't have a `user_id` column — its RLS policy uses an EXISTS subquery to check ownership through the parent `course_results` table.

---

## 15. Supabase Edge Functions

We have two Edge Functions, both written in TypeScript/Deno.

### acadia-ai — AI Academic Assistant

This is the more complex one. It handles AI chat messages from the app.

**How it works:**
1. Receives the request with an Authorization Bearer token
2. Validates the user via `supabase.auth.getUser()`
3. Reads the `semesterId` from the request body (or falls back to `student_profiles.active_semester_id`)
4. Receives the last 6 chat messages as conversation history

**Intent routing (3-layer system):**
1. **Hard routing** — keywords like "summary" or "focus now" are mapped directly to handlers
2. **AI-based intent detection** — sends the message to NVIDIA NIM (Llama 3.1 70B) with a prompt that asks it to classify the intent
3. **Fallback keyword matcher** — if the AI fails, regex patterns pick up the slack

**Supported intents:**
| Intent | What Happens |
|---|---|
| `get_tasks` | Queries the `tasks` table, categorizes into urgent/pending/completed |
| `get_deadlines` | Queries `academic_deadlines` for upcoming items |
| `get_summary` | Summarizes task completion progress |
| `get_focus` | Returns the single most urgent task |
| `email_tasks` | Sends a styled HTML email via Resend with the task breakdown |
| `get_profile` | Returns full student profile data |
| `get_courses` | Queries courses for the current semester |
| `get_details` | Returns the last context data in detail |
| `summarize_last` | Uses the LLM to summarize the last fetched data |
| `ai` | Falls back to general LLM chat with an academic system prompt |

**Environment variables it needs:**
- `NVIDIA_API_KEY` — for the LLM API
- `NVIDIA_MODEL` — which model to use
- `RESEND_API_KEY` — for sending emails
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — for database access

### send-push — FCM Push Notification Sender

This one's simpler. It receives a push notification request and sends it via Firebase Cloud Messaging.

**How it works:**
1. Receives the request with a device FCM token, title, body, and optional data
2. Creates a JWT using the Firebase service account
3. Gets an OAuth access token from Google
4. POSTs to the FCM HTTP v1 API to deliver the notification

**Environment variables it needs:**
- `FIREBASE_SERVICE_ACCOUNT` — JSON service account key

---

## 16. The Smart Notification System

This is one of the more sophisticated parts of the app. It's a 3-layer system designed to send you helpful notifications without being annoying.

### Layer 1: When to Notify (SmartNotificationEngine)

This is the brain. It evaluates your current academic situation and decides if you need a nudge:

- **Overdue tasks** — If you have tasks that are past their deadline, it sends an `overdue` notification
- **Due within 24 hours** — If something's due today or tomorrow, it sends a `deadline` notification
- **Multiple items** — If there are several things going on, it batches them into an `academic_summary` instead of sending 5 separate notifications
- **High risk** — If your risk score is >= 70, it sends a `risk` alert
- **Moderate risk** — If risk score is >= 50, it sends a lower-priority `risk` notification
- **High stress** — If your average stress is >= 7, it sends a `stress` notification

### Layer 2: How to Deliver (NotificationService)

This handles the actual delivery with anti-spam protections:

- **Cooldown per type** — Each notification type has a cooldown (4h for overdue, 6h for risk, 12h for deadline/stress, 24h for academic_summary). If you already got an "overdue" notification 2 hours ago, you won't get another one for 2 more hours.
- **Daily rate limit** — Max 5 notifications per day total, max 2 high-priority ones. This prevents notification spam on busy days.
- **Night-time suppression** — No notifications between 10pm and 7am (except critical ones like risk alerts). You can sleep in peace.
- **Behavior adaptation** — The `NotificationBehaviorService` tracks how you interact with notifications:
  - If you ignore more than 3 of a certain type, the cooldown doubles. The app learns that you don't care about that type and backs off.
  - If you open more than 50% of a certain type, the priority gets boosted. The app learns that you find those helpful and makes them more visible.
- **Delivery flow**: Write to Supabase inbox → check cooldown/rate limits → adapt priority → call `send-push` Edge Function for FCM → show local notification

### Layer 3: Background Evaluation (BackgroundNotificationService)

This runs every 30 minutes even when you're not using the app:
- On Android: uses `Workmanager` to register a periodic task
- On iOS: uses `BackgroundFetch` to register a periodic fetch
- Each run: re-initializes Supabase (isolated context) → fetches current user and active semester → loads tasks and analytics → evaluates via `NotificationIntelligenceService.evaluateBackground()` → sends if conditions are met

The background task runs in an isolated context, not the main app. That's why it needs to re-initialize Supabase from scratch using credentials saved in SharedPreferences.

### Notification Deduplication

The `notifications` table has a partial unique index on `(user_id, reference_id, type) WHERE reference_id IS NOT NULL`. This means you can't have two "overdue" notifications for the same task. When the system tries to create a duplicate, it silently fails (the insert is ignored). This is important because the background worker and the foreground evaluator could both try to notify about the same overdue task at the same time.

---

## 17. The AI Assistant

The AI assistant has two ways of answering your questions:

### Path 1: Local Intent Resolution (Fast and Free)

When you type something in the chat, it first goes through the `AiIntentParser`:

1. **Intent detection** — regex patterns check for keywords:
   - "tasks" + time words → `getTasksByTimeRange`
   - "completed" or "done" → `getCompletedTasks`
   - "deadline" or "due" → `getUpcomingDeadlines`
   - "study" + "summary" or "hours" → `getStudySummary`
   - "progress" or "how am I" → `getProgress`
   - "risk" or "danger" → `getRiskStatus`

2. **Time range detection** — "today", "this week", "last week", "last 2 weeks"

3. **Course detection** — trailing "for/in/about [course name]" patterns

If an intent is detected, the `AiDataResolver` takes over. It fetches real data from the repositories, formats it into a human-readable response, and returns it as an `AiMessage` with a structured data payload. This happens entirely on-device (well, the data comes from Supabase, but there's no LLM call).

### Path 2: LLM Fallback (Cloud and Paid)

If the intent parser can't figure out what you're asking (returns `unknown`), the app falls back to the `acadia-ai` Edge Function. This sends your message plus the last 6 messages of conversation history to NVIDIA NIM (Llama 3.1 70B), which generates a response. This costs money per API call, which is why we try the local path first.

The Edge Function also supports special intents that the local path doesn't:
- **email_tasks** — sends you an email with your task breakdown
- **get_focus** — tells you the single most urgent thing to work on
- **get_profile** — returns your academic profile
- **get_courses** — lists your courses
- **summarize_last** — summarizes the last data that was fetched

### Typing Animation

The `AiMessage` model has a `displayedText` field and a `key` (GlobalKey). When an AI response comes in, the app starts a typing animation that reveals the text character by character, similar to how ChatGPT does it. This is handled in the chat screen using a timer that appends characters to `displayedText` over time.

---

## 18. The Study Timer

The study timer is implemented as a `StudyTimerNotifier` — a Riverpod `StateNotifier` that manages the full lifecycle of a study session. It's one of the most complex providers in the app.

### State Machine

```
IDLE → RUNNING ↔ PAUSED → COMPLETED
         ↕ (Pomodoro cycles)
```

- **IDLE** — No session in progress. The study screen shows the setup form.
- **RUNNING** — Timer is ticking. Shows the elapsed time and session controls.
- **PAUSED** — Timer is paused. Can be resumed or stopped.
- **COMPLETED** — Session finished. Data is saved to Supabase.

### Session Types

1. **Pomodoro** — 4 focus rounds with 5-minute breaks in between. The timer tracks:
   - Current round number (1-4)
   - Focus time per round (typically 25 minutes)
   - Break time between rounds (typically 5 minutes)
   - Total focus minutes and total break minutes
   - Completed cycles and skipped breaks

2. **Deep Work** — One long continuous session. No rounds or breaks.

3. **Review** — A shorter session for reviewing material.

### Persistence

The timer state is saved to Hive (box name: `timer_state`) every time it changes. This means:
- If the app crashes during a session, the state is preserved
- If you restart the app, the timer picks up where it left off
- The saved state includes: start time, elapsed seconds, session type, selected course, current round, and pause state

### App Lifecycle Awareness

The notifier uses `WidgetsBindingObserver` to detect when the app goes to the background and when it comes back:

- **Going to background** — saves the current timestamp to Hive
- **Coming back to foreground** — calculates the elapsed time since the saved timestamp and updates the timer accordingly. So if you were at 15 minutes when you left, and you come back 10 minutes later, the timer shows 25 minutes.

### Audio and Haptic Feedback

When a Pomodoro round completes or a study session finishes:
- A sound is played using `audioplayers` (the sound file is in `assets/sounds/`)
- The phone vibrates using `haptic_feedback`

### Session Saving

When the timer is stopped or a Pomodoro cycle completes:
1. The notifier calls `saveFromTimer()` or `savePomodoroSession()` on the `StudySessionsNotifier`
2. The session is inserted into the `study_sessions` Supabase table
3. Analytics providers are refreshed
4. If mood tracking is enabled and this is a session type that supports it, a mood prompt is queued

---

## 19. Mood and Stress Tracking

Mood tracking is integrated throughout the app, not just as a standalone feature.

### Two Sources of Mood Data

1. **Daily (manual)** — The user opens the mood logging screen, picks their mood, adjusts stress and energy, picks factors, and saves. This is their "baseline" daily mood.

2. **Session (post-study)** — After finishing a study session, the app prompts the user to log how they feel. This mood log has `source = 'session'` and is linked to the study session that just ended.

### The Mood Logging Flow

1. User opens `/mood/log` (or gets redirected there after a study session)
2. They swipe through the 5-level mood selector (very bad → very good, represented by emojis)
3. They adjust the stress slider (1-10)
4. They adjust the energy slider (1-10, optional)
5. They pick factors: sleep, workload, health, motivation, social, exams
6. They can add an optional text note
7. They tap save

On save, the `moodActionsProvider` handles everything:
- Inserts the mood log into Supabase
- Refreshes analytics (mood affects risk score and analytics)
- Refreshes risk provider
- Refreshes mood log providers

### Mood Reminders

If the user has mood reminders enabled:
- A daily local notification is scheduled at the configured time (e.g., "8:00 PM")
- The reminder type can be "daily" (only daily baseline reminders), "session" (only post-study reminders), or "both"
- Reminders are scheduled and cancelled through `NotificationService.scheduleDailyMoodReminder()`

### Mood Settings

The `MoodSettingsScreen` lets the user:
- Enable/disable mood tracking entirely
- Enable/disable reminders
- Set the reminder time (24h format)
- Set the reminder type (daily/session/both)
- Navigate to mood history

### Legacy Mood Handling

We used to store moods as strings ("very_bad", "bad", "neutral", "good", "very_good"). At some point we switched to integers (1-5). The `MoodLog.fromJson` method has a `_legacyMoodToLevel` converter that maps old strings to new integers, so old data still works. The `MoodService.insertMood` method also has a fallback that converts integer levels back to strings if the database still has the old schema.

---

## 20. Analytics Engine

The analytics engine is the heart of the app's intelligence. It's what powers the dashboard, the risk score, the decision engine, and the trend charts.

### How Analytics Are Computed

The `AnalyticsNotifier` does the following:

1. **Collects raw data** from multiple sources (all scoped to the active semester):
   - Study sessions (from `studySessionsProvider`)
   - Tasks (from `tasksProvider`)
   - Mood logs (from `moodLogsProvider`)
   - Deadlines (from `deadlinesProvider`)
   - Course results, courses, semester settings, user settings (fetched from DB)

2. **Computes study metrics:**
   - Study hours per course (total duration grouped by course)
   - Weekly average study hours
   - Study consistency (how evenly distributed study sessions are across days)
   - Study deficit (weekly goal - actual hours)
   - Previous week study hours (for trend comparison)

3. **Computes task metrics:**
   - Task completion rate (completed / total)
   - Overdue task count
   - Upcoming task count (due within 7 days)
   - Due soon task count (due within 24 hours)

4. **Computes grade metrics:**
   - Average GPA (letter grades mapped to 4.0 scale: AA=4.0, BA=3.5, BB=3.0, CB=2.5, CC=2.0, DC=1.5, DD=1.0, FF=0.0)
   - Grade distribution (how many of each letter grade)
   - Total ECTS

5. **Computes mood/stress metrics:**
   - Average daily mood and stress (from manual mood logs)
   - Average session mood and stress (from post-session logs)
   - Stress trend (is it going up or down?)
   - Mood log count

6. **Computes risk score** using `RiskEngine.calculate()`

7. **Assembles everything** into an `AnalyticsData` object with ~25 fields

### Caching

The `AnalyticsRepository` has a 10-second TTL cache per semester ID. If you switch tabs and come back within 10 seconds, you get the cached result instead of re-fetching everything. There's also deduplication of parallel fetches — if two providers ask for the same semester's analytics at the same time, only one DB call happens.

### Study Analytics

The `studyAnalyticsProvider` takes the raw analytics and computes study-specific derived metrics:

- **Focus score** — based on session type and duration (longer sessions = more focused)
- **Burnout score/level** — based on study volume, consistency, stress, and break patterns
  - Levels: "low" (0-25), "moderate" (26-50), "high" (51-75), "critical" (76+)
- **Current streak** — consecutive days with at least one study session
- **Weekly consistency** — how evenly study time is distributed across the week (0-100%)
- **Pomodoro stats** — total cycles, average focus per cycle, break patterns
- **Study time buckets** — morning/afternoon/evening/night study distribution
- **Session quality score** — based on duration, type, and post-session mood
- **Study profile** — categorization: "consistent" (regular daily study), "crammer" (lots of sessions near deadlines), "casual" (irregular study), etc.
- **Weekly deficit hours** — how far behind the weekly study goal

---

## 21. Risk Scoring

The risk score tries to quantify how likely a student is to have academic problems. It's a number from 0 to 100.

### How It's Calculated

The `RiskEngine.calculate()` method takes a `RiskInput` and computes the score:

1. **Base risk** starts at a neutral value
2. **Overdue task adjustment** — each overdue task adds points (more if the linked deadline is high priority)
3. **Study deficit adjustment** — being behind the weekly study goal adds points proportionally
4. **Grade risk adjustment** —
   - FF: +15, DD: +8, DC: +5 (bad grades increase risk)
   - BA: -3, AA: -5 (good grades decrease risk)
5. **Stress adjustment** — higher average stress adds points
6. **Consistency adjustment** — lower study consistency adds points
7. **Overdue deadline penalty** — additional points for each uncompleted past deadline
8. **Linked task completion relief** — if a deadline has completed tasks, the deadline's risk contribution is reduced
9. **Recently completed deadline adjustment** — if a deadline was completed recently, it reduces risk

The final score is clamped to 0-100 and categorized as:
- **Low** (0-33)
- **Moderate** (34-66)
- **High** (67-100)

### Risk Trend

The `riskProvider` computes the risk score twice: once for the current period and once for the previous week. The difference between them is the trend delta — positive means risk is increasing, negative means it's decreasing. This is shown in the analytics and dashboard as an arrow indicator.

---

## 22. Decision Engine

The decision engine tells you what you should study next and for how long. There are two versions.

### V1 — Rule-Based Priority

Simple rules in order of priority:
1. If you have overdue tasks → study the course with the most overdue items
2. If you have upcoming deadlines within a week → study the course with the nearest deadline
3. If nothing is urgent → study the course you've spent the least time on
4. Has a burnout guard that caps the recommended session at a reasonable duration

### V2 — Multi-Factor Scoring

Each course gets a composite score from 5 factors:

| Factor | Weight | What It Measures |
|---|---|---|
| Urgency | 34% | Overdue tasks + upcoming deadlines for this course |
| Deficit | 24% | How far behind you are on studying this course compared to others |
| Workload | 16% | How many tasks/deadlines this course has |
| ECTS Weight | 16% | How many credits this course is worth (more credits = more important) |
| Risk Signal | 10% | Overall risk score adjustment |

The course with the highest composite score gets the recommendation. The engine generates:
- **Next action** — which course to study, for how many minutes, and why (with a confidence level: high/medium/low)
- **Focus recommendation** — which course needs the most attention overall
- **What changed** — brief description of what's different from last week (study trends, task load, performance)

### Active Decision

The `decisionEngineActiveProvider` prefers V2 but falls back to V1 if V2 fails for any reason. This way, you always get a recommendation even if the scoring algorithm hits an edge case.

---

## 23. Supabase Realtime

The `realtimeProvider` subscribes to Postgres Change events on 5 tables. When data changes on the server (from another device, or from a background process), the app automatically updates.

### What's Subscribed

| Table | What Happens on Change |
|---|---|
| `tasks` | Invalidates `tasksProvider` → triggers analytics, risk, dashboard recomputation |
| `academic_deadlines` | Invalidates `deadlinesProvider` → triggers recomputation cascade |
| `study_sessions` | Invalidates `studySessionsProvider` → triggers analytics, study analytics recomputation |
| `course_results` | Invalidates `courseResultsProvider` → triggers analytics recomputation |
| `courses` | Invalidates `courseProvider`. If ECTS changed, also invalidates `riskProvider` |

### Debouncing

All changes are debounced with a 250ms delay. This means if 10 tasks are updated in rapid succession (like during a batch sync), the providers are only invalidated once after the last change, not 10 times. Without this, each change would trigger a separate analytics recomputation, which would be extremely wasteful.

### How It Works

The realtime provider uses `ref.listen()` internally to watch the auth state. When the user logs in, it sets up the subscriptions. When they log out, it cleans them up. The subscriptions are filtered by user ID, so you only get events for your own data.

---

## 24. Background Processing

The app runs background tasks to evaluate whether you need notifications, even when you're not using it.

### Android — Workmanager

- Registers a periodic task with `Workmanager` that runs approximately every 30 minutes
- The task is taggedged with a unique identifier so it can be updated or cancelled
- The callback dispatcher is annotated with `@pragma('vm:entry-point')` because it runs in an isolated Dart context

### iOS — BackgroundFetch

- Registers a periodic fetch task with `BackgroundFetch` that runs approximately every 30 minutes
- iOS gives no guarantees about exact timing — it depends on battery level, network conditions, and how often the user opens the app
- The headless task is also annotated with `@pragma('vm:entry-point')`

### What the Background Task Does

1. Re-initializes Supabase from saved credentials in SharedPreferences (the background context doesn't share state with the main app)
2. Initializes the `NotificationService` (for local notification capabilities)
3. Gets the current user and active semester
4. Fetches fresh tasks from `TaskRepository`
5. Fetches fresh analytics from `AnalyticsRepository`
6. Calls `NotificationIntelligenceService.evaluateBackground()` with the fresh data
7. If the evaluation says a notification should be sent, it sends it through the normal `NotificationService` pipeline (with all the anti-spam checks)

### Web/Desktop — No-op

On web and desktop platforms, the background service is a no-op stub. Background fetch isn't supported on these platforms, so we just skip it.

---

## 25. Localization

The app supports two languages: English and Turkish.

### How It Works

- **Source files**: `lib/l10n/app_en.arb` (English, template) and `lib/l10n/app_tr.arb` (Turkish)
- **Config**: `l10n.yaml` tells Flutter where to find the ARB files and what the output file name is
- **Generated code**: Running `flutter gen-l10n` generates `AppLocalizations` class with typed getters for every string
- **Runtime**: The `localeProvider` reads the saved locale from Hive and provides it to `MaterialApp.router`. When the user changes the language, the provider updates, and the entire app rebuilds with the new locale.

### The Provider Chain

- `localeLoadedProvider` — whether the locale has been loaded from Hive yet (used by router guard)
- `languageSelectedProvider` — whether the user has explicitly picked a language (used by router guard for first-launch flow)
- `localeProvider` — the current `Locale` object
- `appLocalizationsProvider` — provides the `AppLocalizations` instance for the current locale, so providers can use localized strings in computed outputs

### Adding a New String

1. Add the string to `app_en.arb` with a key and English value
2. Add the translation to `app_tr.arb`
3. Run `flutter gen-l10n`
4. Use `AppLocalizations.of(context)!.yourNewKey` in widgets, or `ref.read(appLocalizationsProvider).yourNewKey` in providers

---

## 26. UI Component System

We have a layered UI component system:

### Design Primitives (in `components/`)

These are the building blocks used across the entire app:

- **AppButton** — styled button with variants (primary, secondary, danger)
- **AppTextField** — styled text input with label, hint, error text, and optional prefix/suffix icons
- **AppGlassCard** — glassmorphism-styled card with blur effect and semi-transparent background
- **AppBackButton** — consistent back navigation button
- **AppSectionTitle** — section header with title and optional action button
- **AppBottomSheetPicker** — bottom sheet with selectable options (used for course pickers, semester pickers, etc.)

### Feature Widgets (in `widgets/`)

These are more specialized widgets used in specific feature areas:

- **analytics/** — analytics cards, GPA chart widgets, trend chart widgets, decision recommendation cards
- **mood/** — mood selector, stress slider, energy slider, factor chips, mood history item
- **risk/** — risk level indicator, risk trend arrow
- **semester/** — semester card, semester switcher, semester comparison chart
- **settings/** — settings tile, theme toggle, language picker
- **common/** — shared widgets used across features
- **auth/** — password strength indicator, OTP input decorator

### Design Tokens (in `core/design/`)

These define the visual constants:

- **AppSpacing** — padding and margin values (xs, sm, md, lg, xl)
- **AppRadius** — border radius values
- **AppBlur** — blur effect values for glassmorphism
- **AppDurations** — animation duration values
- **AppShadows** — shadow definitions for cards and elevated elements
- **AppIcons** — icon size constants

### Theme System (in `core/theme/` and `theme/`)

- **AppTheme** — defines `lightTheme` and `darkTheme` as complete `ThemeData` objects with custom colors, typography, component themes, and card/appbar/button styles
- **AppColors** — context-aware color accessors that automatically pick the right color based on the current theme brightness

---

## 27. Security

### Row Level Security (RLS)

Every table has RLS enabled with policies that enforce `auth.uid() = user_id`. This means:
- Users can only read their own data
- Users can only insert rows with their own user_id
- Users can only update/delete their own rows
- The `course_result_components` table uses an EXISTS subquery to check ownership through the parent `course_results` table

### Auth Rate Limiting

The `AuthRepository` implements rate limiting for login and signup attempts:
- Exponential backoff: 60s * attempt count, capped at 300 seconds
- Rate limit state is persisted in Hive (box: `settings`)
- Separate counters for auth attempts and email sends
- Signup cooldown: 3 minutes between successful signups

### Secret Management

- All secrets are in the `.env` file, which is gitignored
- Environment variables: Supabase URL, anon key, service role key, NVIDIA API key, NVIDIA model name
- Edge Function secrets are set via `supabase functions secrets set` (not in code)

### Edge Function Authentication

Both Edge Functions validate the Authorization header:
- `acadia-ai` calls `supabase.auth.getUser()` with the Bearer token
- `send-push` doesn't have its own auth (it's called by the app's NotificationService which already authenticated the user)

### Background Worker Isolation

The background notification service runs in a completely isolated Dart context. It doesn't share any state with the main app. It re-initializes Supabase from credentials saved in SharedPreferences. This means:
- No memory leaks from the main app
- No dependency on the main app being alive
- Safe to run even if the main app crashed

---

## 28. Environment Variables

The `.env` file (copied from `.env.example`) contains:

| Variable | What It's For | Required For |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | App startup |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | App startup |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (bypasses RLS) | Edge Functions |
| `NVIDIA_API_KEY` | NVIDIA NIM API key | AI assistant |
| `NVIDIA_MODEL` | Which LLM model to use | AI assistant |
| `APP_ENV` | "development" or "production" | Optional |
| `API_TIMEOUT` | Request timeout in milliseconds | Optional (default 10000) |

Edge Functions also need these secrets (set via `supabase functions secrets set`):
- `NVIDIA_API_KEY`, `NVIDIA_MODEL`, `RESEND_API_KEY` (for acadia-ai)
- `FIREBASE_SERVICE_ACCOUNT` (for send-push)
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (for both)

---

## 29. Migration History

We've gone through 23 database migrations so far. Here's what each one did:

| # | Migration | What It Did |
|---|---|---|
| 1 | `schema.sql` | Base schema — created all initial tables |
| 2 | `2026031602_academic_structure_updates` | Added `course_id` foreign keys to tasks, deadlines, exams |
| 3 | `2026031603_semester_structure` | Added `semester_id` foreign keys to courses |
| 4 | `2026031604_foundation_updates` | Added `is_active` to courses, various constraint fixes |
| 5 | `2026031605_foundation_hardening` | Hardened RLS policies, fixed policy gaps |
| 6 | `2026031606_profile_split_and_study_reflection` | Moved academic profile fields from `users` to `student_profiles`, added reflection fields to `study_sessions` |
| 7 | `2026031701_stability_patch` | Bug fixes for the profile split migration |
| 8 | `2026031901_study_session_history_foundation` | Added study session history tracking |
| 9 | `2026031902_notifications_dynamic_types` | Added more notification type options |
| 10 | `2026031903_notifications_reference_dedup` | Added `reference_id` to notifications with deduplication unique index |
| 11 | `2026033101_course_results_foundation` | Created `course_results` and `course_result_components` tables |
| 12 | `2026033102_course_results_outcome_status` | Added `result_status` column with CHECK constraint |
| 13 | `2026033103_course_results_semester_fk` | Added `semester_id` foreign key to course_results |
| 14 | `2026033104_course_results_atomic_save` | Created the `save_course_result_with_components` RPC function |
| 15 | `2026033111_deadline_completion_status` | Added `is_completed` and `completed_at` to academic_deadlines |
| 16 | `2026033112_tasks_deadline_fk` | Added `deadline_id` foreign key to tasks |
| 17 | `2026040501_semester_isolation_phase1` | Phase 1 of semester isolation — started making `semester_id` required |
| 18 | `2026040502_enforce_semester_not_null` | Made `semester_id` NOT NULL on tasks, deadlines, study sessions, mood_logs |
| 19 | `2026040503_notifications_semester_scope` | Added `semester_id` to notifications |
| 20 | `2026040901_study_sessions_only_fix` | Fixed study sessions to only track study-related data |
| 21 | `2026040902_ensure_study_sessions_course_fk` | Ensured study_sessions.course_id foreign key was properly enforced |
| 22 | `2026041601_mood_stress_foundation` | Created `mood_logs` table with proper structure (mood_level, stress_level, factors, source) |
| 23 | `2026041602_mood_settings_tracking_enabled` | Added `tracking_enabled` to mood_settings |
| 24 | `2026042101_add_users_weekly_study_goal` | Added `weekly_study_goal` to users table |
| 25 | `2026042102_semesters_weekly_study_goal` | Added `weekly_study_goal` to semesters table |

The key theme across migrations is **semester isolation** — we progressively made `semester_id` a required NOT NULL foreign key on almost every table. Early versions of the app didn't have semester scoping, so a lot of data was just floating around without a semester context. The migrations fixed that.

---

## 30. Folder Structure

```
acadia/
├── .env                          # Secrets (gitignored)
├── .env.example                  # Template for secrets
├── .gitignore                    # Git ignore rules
├── analysis_options.yaml         # Dart linter config
├── l10n.yaml                     # Localization config
├── pubspec.yaml                  # Flutter dependencies
├── pubspec.lock                  # Locked dependency versions
├── README.md                     # Quick project overview
├── documentation.md              # This file — full project documentation
│
├── lib/
│   ├── main.dart                 # App entry point, router, guards
│   │
│   ├── components/               # Design primitives (6 files)
│   │   ├── app_back_button.dart
│   │   ├── app_bottom_sheet_picker.dart
│   │   ├── app_button.dart
│   │   ├── app_glass_card.dart
│   │   ├── app_section_title.dart
│   │   └── app_text_field.dart
│   │
│   ├── core/
│   │   ├── design/               # Design tokens (6 files)
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_radius.dart
│   │   │   ├── app_blur.dart
│   │   │   ├── app_durations.dart
│   │   │   ├── app_shadows.dart
│   │   │   └── app_icons.dart
│   │   ├── services/             # Domain services (1 file)
│   │   │   └── risk_engine.dart
│   │   ├── theme/                # Theme definitions (2 files)
│   │   │   └── app_theme.dart
│   │   └── utils/                # Shared utilities
│   │
│   ├── domain/                   # Pure business logic (12 files)
│   │   ├── academic_deadline_task.dart
│   │   ├── decision/
│   │   │   └── decision_engine.dart
│   │   ├── prediction/
│   │   │   └── prediction_engine.dart
│   │   ├── risk/
│   │   │   └── risk_calculator.dart
│   │   └── tasks/
│   │       └── task_validation.dart
│   │
│   ├── l10n/                     # Localization (ARB + generated)
│   │   ├── app_en.arb
│   │   └── app_tr.arb
│   │
│   ├── models/                   # Domain models (23 files)
│   │   ├── academic_calendar.dart
│   │   ├── ai_intent.dart
│   │   ├── ai_message.dart
│   │   ├── analytics.dart
│   │   ├── analytics_data.dart
│   │   ├── app_user.dart
│   │   ├── course.dart
│   │   ├── course_result.dart
│   │   ├── deadline.dart
│   │   ├── decision_snapshot.dart
│   │   ├── exam.dart
│   │   ├── heatmap_day.dart
│   │   ├── mood.dart
│   │   ├── mood_log.dart
│   │   ├── mood_settings.dart
│   │   ├── notification.dart
│   │   ├── performance_summary.dart
│   │   ├── semester.dart
│   │   ├── semester_comparison.dart
│   │   ├── student_profile.dart
│   │   ├── study_session.dart
│   │   ├── task.dart
│   │   └── trend_data.dart
│   │
│   ├── providers/                # Riverpod providers (29 files + supabase/)
│   │   ├── ai_assistant_provider.dart
│   │   ├── analytics_provider.dart
│   │   ├── app_providers.dart
│   │   ├── bottom_nav_provider.dart
│   │   ├── course_provider.dart
│   │   ├── course_results_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── deadlines_provider.dart
│   │   ├── decision_engine_provider.dart
│   │   ├── decision_engine_provider_v2.dart
│   │   ├── decision_provider.dart
│   │   ├── global_refresh_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── mood_provider.dart
│   │   ├── notifications_provider.dart
│   │   ├── onboarding_provider.dart
│   │   ├── performance_summary_provider.dart
│   │   ├── prediction_provider.dart
│   │   ├── realtime_provider.dart
│   │   ├── risk_provider.dart
│   │   ├── semester_comparison_provider.dart
│   │   ├── semester_goal_refresh_provider.dart
│   │   ├── semester_provider.dart
│   │   ├── student_profile_provider.dart
│   │   ├── study_heatmap_provider.dart
│   │   ├── study_sessions_provider.dart
│   │   ├── supabase/             # (empty — providers defined in app_providers.dart)
│   │   ├── tasks_provider.dart
│   │   ├── theme_provider.dart
│   │   └── trend_provider.dart
│   │
│   ├── repositories/             # Data access layer (13 files)
│   │   ├── ai_assistant_repository.dart
│   │   ├── analytics_repository.dart
│   │   ├── auth_repository.dart
│   │   ├── course_repository.dart
│   │   ├── course_result_repository.dart
│   │   ├── deadline_repository.dart
│   │   ├── exam_repository.dart
│   │   ├── mood_repository.dart
│   │   ├── notification_repository.dart
│   │   ├── semester_repository.dart
│   │   ├── study_repository.dart
│   │   ├── task_repository.dart
│   │   └── trend_repository.dart
│   │
│   ├── screens/                  # Feature screens (40 screens across 15 areas)
│   │   ├── ai/
│   │   │   └── ai_chat_screen.dart
│   │   ├── analytics/
│   │   │   ├── analytics_screen.dart
│   │   │   └── academic_history_screen.dart
│   │   ├── app/
│   │   │   ├── app_shell.dart
│   │   │   └── liquid_glass_navbar.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── verify_email_screen.dart
│   │   │   ├── forgot_password_otp_screen.dart
│   │   │   ├── forgot_password_code_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   └── password_validation.dart
│   │   ├── courses/
│   │   │   ├── course_management_screen.dart
│   │   │   ├── create_course_screen.dart
│   │   │   ├── semester_management_screen.dart
│   │   │   ├── create_semester_screen.dart
│   │   │   ├── course_results_screen.dart
│   │   │   └── course_result_editor_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── quick_menu_screen.dart
│   │   │   └── widgets/
│   │   │       ├── study_heatmap.dart
│   │   │       ├── home_skeleton_screen.dart
│   │   │       └── live_study_session_card.dart
│   │   ├── language/
│   │   │   └── language_selection_screen.dart
│   │   ├── mood/
│   │   │   ├── log_mood_screen.dart
│   │   │   └── mood_history_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_welcome_screen.dart
│   │   │   └── academic_onboarding_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_academic_profile_screen.dart
│   │   │   ├── study_preferences_screen.dart
│   │   │   ├── change_password_screen.dart
│   │   │   └── settings_tile.dart
│   │   ├── settings/
│   │   │   └── mood_settings_screen.dart
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── study/
│   │   │   ├── study_screen.dart
│   │   │   ├── study_history_screen.dart
│   │   │   ├── session_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── active_session_view.dart
│   │   │       └── study_session_dialogs.dart
│   │   └── tasks/
│   │       ├── tasks_list_screen.dart
│   │       ├── create_task_screen.dart
│   │       ├── task_detail_screen.dart
│   │       ├── edit_task_screen.dart
│   │       ├── create_deadline_screen.dart
│   │       ├── deadline_detail_screen.dart
│   │       └── edit_deadline_screen.dart
│   │
│   ├── services/                 # Backend communication (27 files)
│   │   ├── ai/
│   │   │   ├── intent_parser.dart
│   │   │   └── data_resolver.dart
│   │   ├── storage/
│   │   │   └── avatar_service.dart
│   │   ├── supabase/
│   │   │   ├── auth_service.dart
│   │   │   ├── course_service.dart
│   │   │   ├── course_result_service.dart
│   │   │   ├── deadline_service.dart
│   │   │   ├── exam_service.dart
│   │   │   ├── mood_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── semester_service.dart
│   │   │   ├── study_service.dart
│   │   │   ├── student_profile_service.dart
│   │   │   ├── semester_state_service.dart
│   │   │   ├── analytics_service.dart
│   │   │   ├── trend_service.dart
│   │   │   └── ai_assistant_service.dart
│   │   ├── notification_service.dart
│   │   ├── notification_config.dart
│   │   ├── notification_behavior_service.dart
│   │   ├── smart_notification_engine.dart
│   │   ├── notification_intelligence_service.dart
│   │   ├── background_notification_service.dart
│   │   ├── background_notification_service_mobile.dart
│   │   └── background_notification_service_stub.dart
│   │
│   ├── theme/                    # Context-aware colors
│   │   └── app_colors.dart
│   │
│   ├── utils/                    # Utilities
│   │   └── go_router_refresh_stream.dart
│   │
│   └── widgets/                  # Feature widgets (13 files)
│       ├── analytics/
│       ├── auth/
│       ├── common/
│       ├── mood/
│       ├── risk/
│       ├── semester/
│       └── settings/
│
├── assets/
│   ├── images/
│   ├── onboarding/
│   ├── sounds/
│   ├── app_logo.png
│   └── logo.png
│
├── supabase/
│   ├── schema.sql                # Base database schema
│   ├── 2026031602_*.sql          # Migrations (23 files)
│   ├── ...
│   └── functions/
│       ├── acadia-ai/
│       │   └── index.ts
│       └── send-push/
│           └── index.ts
│
├── test/                         # Test directory
├── android/                      # Android platform runner
├── ios/                          # iOS platform runner
├── macos/                        # macOS platform runner
├── web/                          # Web platform runner
├── linux/                        # Linux platform runner
└── windows/                      # Windows platform runner
```

---

## 31. Common Gotchas and Tips

Things that might trip you up if you're working on this codebase:

### 1. Active Semester Is Everything
If something seems broken or showing wrong data, check if the active semester is set correctly. Almost every data query is scoped to `activeSemesterProvider`. If the active semester is null or wrong, you'll get empty or incorrect results everywhere.

### 2. Provider Dependencies Cascade
Changing `activeSemesterProvider` triggers a cascade: all core data providers refetch → analytics recomputes → risk recalculates → decision engine re-evaluates → dashboard updates. This is by design, but it means you need to be careful about triggering unnecessary semester switches (like in `initState`).

### 3. Hive Box Names
We use multiple Hive boxes:
- `settings` — theme, locale, onboarding status, auth rate limits, burnout history
- `timer_state` — study timer state
If you're looking for persisted data and can't find it, check which box it's in.

### 4. Legacy Fields in Models and DB
Several models have dual fields: a legacy text field and a new FK field. For example, `Task` has both `course` (String) and `courseId` (String?). The DB has the same thing. The legacy fields are kept for backward compatibility with old data. When creating new records, always use the FK fields.

### 5. MoodLog vs MoodModel
There are two mood models. `MoodModel` is the old one with string-based mood values. `MoodLog` is the new one with integer levels. Use `MoodLog` for everything new. The old model is only kept for backward compatibility during JSON parsing.

### 6. Timer State Can Get Stale
The study timer state is persisted in Hive. If you modify the timer logic (like changing round counts or durations), old saved state might be incompatible. Call `StudyTimerNotifier.reset()` or manually clear the `timer_state` Hive box to fix this.

### 7. Notification Deduplication
The notifications table has a partial unique index on `(user_id, reference_id, type)`. When creating notifications, always include a `referenceId` that uniquely identifies the event (like the task ID or deadline ID). Without it, you can get duplicate notifications.

### 8. The Router Redirect Runs on Every Navigation
Any time you call `context.go()` or `context.push()`, the redirect function in `main.dart` runs. If you're adding a new route, make sure the redirect logic handles it correctly. Otherwise, users might get unexpectedly redirected.

### 9. Supabase Realtime Events Are Debounced
If you're testing realtime functionality and wondering why providers don't update immediately — they update 250ms after the last change. This is intentional to prevent rapid recomputation cascades.

### 10. Background Tasks Run in Isolation
The background notification service runs in a separate Dart isolate. It can't access any Riverpod providers, Hive boxes, or in-memory state from the main app. It has to re-initialize Supabase from scratch. If you're adding background functionality, keep this in mind.

### 11. Analytics Caching
The `AnalyticsRepository` caches results for 10 seconds per semester. If you're testing analytics and the numbers seem stale, wait 10 seconds or call `analyticsProvider.invalidate()` to force a refresh.

### 12. RLS Policies Are Strict
Every table has RLS enabled. If you're adding a new table or a new query, make sure the RLS policy allows the operation. Using the service role key bypasses RLS, but the app should never use it (only Edge Functions use it).

### 13. The Global Refresh Order Matters
`globalRefreshProvider` refreshes providers in a specific order (semesters first, then core data, then analytics). If you're adding a new provider that depends on other providers, make sure it's refreshed after its dependencies.

### 14. Edge Function Timeouts
The `acadia-ai` Edge Function has a 30-second timeout. The LLM can sometimes take a while to respond, especially for complex queries. If the timeout is too short, you'll get errors. If it's too long, the user will be waiting forever.

### 15. Course Color Is a Hex String
The `Course.color` field is stored as a hex string like "#FF5733". The `Course.uiColor` getter converts it to a Flutter `Color` object. If you're setting a course color, make sure it's in hex format.

---

And that's the entire Acadia app, from A to Z. If you made it this far, you should have a pretty solid understanding of how everything fits together. The app is big, but the architecture is consistent — once you understand the provider/service/repository pattern, you can navigate any feature area. Good luck out there.
