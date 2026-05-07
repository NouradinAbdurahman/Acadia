# Acadia — A-to-Z Documentation

---

## Section 1: Project Overview

### 1.1 What Is Acadia?

Acadia is a Flutter mobile application built for university students. It serves as a single place to manage the entire academic life — courses, assignments, study habits, deadlines, exams, mood, stress, and analytics. Beyond a simple task manager, Acadia actively monitors the student's academic and emotional state, computes risk scores, detects burnout signals, and provides adaptive recommendations via a deterministic decision engine and an AI assistant.

### 1.2 Core Capabilities

- **Authentication**: Email+password with OTP verification, password reset via OTP, Google and Apple OAuth via Supabase PKCE, rate limiting with exponential backoff
- **Semester Management**: All data is semester-scoped; the user selects an active semester and every query, widget, and provider filters by it
- **Courses**: CRUD with ECTS credits, color coding, active/inactive toggle, linked to semesters
- **Tasks & Deadlines**: Separate models; tasks can be linked to deadlines; deadlines can have sub-tasks; auto-completion cascades
- **Exams**: Midterm/final/quiz with countdown, notification scheduling, and classroom/online metadata
- **Study Timer**: Pomodoro, deep work, review, and practice modes; Hive-persisted state survives app kills; structured Pomodoro saves with focus/break/cycle tracking; mood+stress capture after each session
- **Mood & Stress Tracking**: 1–5 mood level, 1–10 stress level, energy level, factors, two sources (daily manual + post-session); configurable reminders
- **Analytics**: Aggregated per-semester analytics computed from sessions, tasks, deadlines, moods, course results; split daily vs. session mood views; burnout score calculation
- **Risk Engine**: 0–100 score from 5 weighted factors (overdue 30, dueSoon 15, deficit 25, stress 15, consistency 15); trend delta tracking; stress > deficit override rule
- **Decision Engine**: V1 (priority-based) and V2 (weighted scoring: urgency 34%, deficit 24%, workload 16%, ECTS 13%, stress 8%, consistency 5%); adaptive session length recommendations
- **Prediction Engine**: Forecasts future stress, performance risk, lagging courses; builds a 3-day study plan
- **AI Assistant**: Client-side intent parsing → deterministic local response or LLM fallback (OpenAI via NVIDIA on Supabase Edge Function); academic insight appendix attached to every response
- **Smart Notifications**: Dual-channel (local `flutter_local_notifications` + remote FCM via `send-push` Edge Function); per-type cooldown, daily limits (5 total, 2 high-priority), behavior tracking (open/ignore stats), night-time deferral
- **Background Processing**: `workmanager` + `background_fetch` for periodic analytics evaluation and notification triggering
- **Realtime**: Supabase Realtime subscriptions on tasks, deadlines, sessions, course_results, courses with debounced provider invalidation
- **Localization**: English and Turkish via ARB files; zero hardcoded UI strings
- **Theming**: Light/dark with glassmorphism design language, Google Fonts (Inter), HeroIcons primary + Phosphor fallback

### 1.3 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10.4+, Dart |
| State Management | flutter_riverpod 2.5.1 |
| Routing | go_router 14.1.4 |
| Backend | Supabase (Auth, Postgres, Realtime, Edge Functions) |
| Push Notifications | Firebase Core + Firebase Messaging |
| Local Storage | Hive 2.2.3 (preferences, timer state), SharedPreferences (notification behavior) |
| Charts | fl_chart 0.68.0 |
| Icons | heroicons 0.10.0, phosphor_flutter 2.1.0 |
| Fonts | google_fonts 6.2.1 (Inter) |
| Animation | flutter_animate 4.5.0, lottie 3.1.2, shimmer 3.0.0 |
| AI (server) | OpenAI API via NVIDIA endpoint (Edge Function) |
| Email (server) | Resend API (Edge Function) |
| Calendar | table_calendar 3.0.9 |
| Background | workmanager 0.7.0, background_fetch 1.3.8 |
| Auth Helpers | google_sign_in 7.2.0, sign_in_with_apple 7.0.1 |
| Other | image_picker, permission_handler, audioplayers, pin_code_fields, haptic_feedback, flutter_timezone, timezone |

### 1.4 Architecture Pattern

Strict layered architecture enforced by project rules:

```
UI Screen / Widget
    ↓ watches/reads
Riverpod Provider / StateNotifier
    ↓ calls
Repository (lib/repositories/)
    ↓ calls
Service (lib/services/supabase/)
    ↓ calls
Supabase (Postgres tables)
```

- Screens NEVER import Services or call Supabase directly
- Repositories NEVER import other Repositories
- Services take SupabaseClient via constructor (injected by `app_providers.dart`)
- Repositories return typed domain models, NEVER raw `Map<String, dynamic>`
- Providers are the ONLY place that holds and mutates state

### 1.5 Folder Structure

```
lib/
  main.dart                    # App entry, GoRouter config, auth guards
  models/                      # 23+ data models (pure data, fromJson/toJson)
  services/
    supabase/                  # 16 thin Supabase query wrappers
    ai/                        # Intent parser, data resolver, insight layer, data guard
    storage/                   # Avatar service
    notification_*.dart        # Notification infra (config, behavior, intelligence, smart engine)
    background_*.dart          # Background notification scheduling
  repositories/                # 13 repositories (Service → Model transformation)
  providers/                   # 31 providers (DI hub + state notifiers + computed)
  domain/
    risk/                      # RiskInput, RiskResult, RiskState, RiskCalculator
    decision/                  # DecisionRules, DecisionEngine, DecisionResult, DecisionInsights
    adaptive/                  # AdaptiveProfile, AdaptiveEngine
    prediction/                # PredictionEngine, PredictionResult
    tasks/                     # Task-deadline validation
    academic_deadline_task.dart # Deadline-task progress helpers
  screens/                     # 57 screens across 16 subdirectories
  widgets/                     # 23 reusable widgets across 8 subdirectories
  components/                  # 8 shared UI building blocks
  core/
    theme/                     # AppColors, AppGradients, AppTheme
    design/                    # AppSpacing, AppDurations, AppRadius, AppBlur, AppIcons, AppShadows
    config/                    # OAuth env helpers, env validation
    navigation/                # Root navigator key
    services/                  # RiskEngine (single source of truth for Dart risk calc)
    utils/                     # TrendLocalizer
  utils/                       # Exam UI utils, GoRouter refresh stream
  l10n/                        # ARB files + generated localizations + l10n extension

supabase/
  schema.sql                   # Base schema
  migrations/                  # 29 migration SQL files (chronological)
  functions/
    acadia-ai/                 # AI chat Edge Function (OpenAI + analytics + email)
    send-push/                 # FCM push notification relay

test/                          # 4 test files (decision engine v1/v2, risk, semester ownership)
Rules/rules.txt                # 20 non-negotiable project rules
.env / .env.example            # Environment variables
```

---

## Section 2: File-by-File Explanation

### 2.1 Entry Point: `lib/main.dart`

The app entry point. Responsibilities:
- Loads `.env` via `flutter_dotenv`
- Validates required env vars (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OAUTH_REDIRECT_URL`, `PASSWORD_RESET_REDIRECT_URL`)
- Initializes Supabase, Firebase, Hive, notifications
- Defines the `routerProvider` (GoRouter) with:
  - Auth-dependent redirect logic (splash → login/signup → onboarding → home)
  - Refresh stream listener on Supabase auth state
  - Named routes: `/`, `/login`, `/signup`, `/verify-email`, `/forgot-password`, `/reset-password`, `/onboarding`, `/home`, `/courses`, `/tasks`, `/create-task`, `/create-deadline`, `/exams`, `/create-exam`, `/study`, `/analytics`, `/mood`, `/notifications`, `/profile`, `/profile/edit`, `/profile/study-preferences`, `/settings`, `/language`, `/ai-chat`
- Wraps `MaterialApp.router` with `ProviderScope`, theme provider, locale provider
- App shell (`AppShell`) renders bottom navigation with 5 tabs: Home, Study, Analytics, AI Chat, Profile

### 2.2 Models (`lib/models/`) — 23 Files

Every model implements `fromJson` + `toJson` with snake_case keys matching Supabase columns.

| File | Class | Key Fields |
|---|---|---|
| `academic_calendar.dart` | `AcademicCalendarModel` | userId, semester, semesterStart/End, examPeriodStart/End |
| `ai_intent.dart` | `AiIntent`, `AiFilter`, `AiIntentType` (enum) | type, filter (timeRange, isCompleted, course, dateRange), originalMessage |
| `ai_message.dart` | `AiMessage` | text, isUser, type, data, intent, suggestions, displayedText (typing animation) |
| `analytics.dart` | `AnalyticsModel` | DB-persisted analytics row (performanceScore, workloadDensity, burnoutRisk) |
| `analytics_data.dart` | `AnalyticsData` | The main computed analytics object: studyHoursPerCourse, gradeDistribution, taskCompletionRate, averageGPA, cumulativeGPA, riskScore, consistency, studyDeficit, overdueTasks, dueSoonTasks, avgDailyMood/Stress, avgSessionMood/Stress, burnoutScore, etc. |
| `app_user.dart` | `AppUser` | id, email, name, avatarUrl, academicProfileCompleted |
| `course.dart` | `Course` | courseName, courseCode, academicSemester, semesterId, credits, ects, color, isActive |
| `course_result.dart` | `CourseResult`, `CourseResultComponent` | courseId, semesterId, letterGrade, finalAverage, resultStatus, components[] |
| `deadline.dart` | `Deadline` | title, course, courseId, deadlineDate, deadlineType, priority, isCompleted, completedAt |
| `decision_snapshot.dart` | `DecisionSnapshot`, `DecisionNextAction`, `DecisionFocusRecommendation` | nextAction (courseId, durationMinutes, reason, confidence), focusRecommendation, whatChanged |
| `exam.dart` | `ExamModel`, `ExamType` (enum) | title, courseId, examDateTime, classroom, isOnline, type (midterm/final/quiz) |
| `heatmap_day.dart` | `HeatmapDay` | date, totalMinutes, sessionsCount, score |
| `mood.dart` | `MoodModel` | Legacy mood model (mood string, stressLevel) |
| `mood_log.dart` | `MoodLog` | moodLevel (1–5), stressLevel (1–10), energyLevel, factors[], source ('manual'/'session') |
| `mood_settings.dart` | `MoodSettings` | trackingEnabled, reminderEnabled, reminderTime, reminderType |
| `notification.dart` | `NotificationModel` | title, message, type, referenceId, isRead |
| `performance_summary.dart` | `PerformanceSummary`, `SemesterPerformance` | bestSemester, worstSemester, mostImprovedSemester, totalCreditsEarned |
| `semester.dart` | `Semester` | name, startDate, endDate, weeklyStudyGoal, isCurrent |
| `semester_comparison.dart` | `SemesterComparison` | current vs. previous AnalyticsData with computed deltas (studyTime, focus, completion, GPA, risk) |
| `student_profile.dart` | `StudentProfile` | fullName, universityName, degreeType, major, academicYear, currentSemester, expectedGraduationYear, preferredStudyTime, breakPattern, timezone, country, onboardingComplete |
| `study_session.dart` | `StudySession` | courseId, sessionType, durationMinutes, isPomodoro, totalFocusMinutes, totalBreakMinutes, cyclesCompleted, totalCycles, mood, stress, plannedMinutes, actualMinutes, startedAt, endedAt |
| `task.dart` | `Task` | title, courseId, deadlineId, deadline (DateTime), priority, status, estimatedTime, isCompleted |
| `trend_data.dart` | `TrendData`, `TrendInsight`, `GradePoint` | studyTrend (day→hours), taskTrend (day→count), workloadTrend, gradeTrend, insights[], studyChangePercent |

### 2.3 Services (`lib/services/`) — 29 Files

#### Supabase Services (`lib/services/supabase/`) — 16 Files

Thin wrappers around `SupabaseClient` queries. Each takes `SupabaseClient` via constructor.

| File | Class | Purpose |
|---|---|---|
| `auth_service.dart` | `AuthService` | Wraps `supabase.auth` (signIn, signOut, state stream, user profile fetch) |
| `student_profile_service.dart` | `StudentProfileServiceBase`/`StudentProfileService` | Upsert initial profile, update profile, mark onboarding complete |
| `semester_service.dart` | `SemesterService` | CRUD semesters, update active semester |
| `semester_state_service.dart` | `SemesterStateService` | Reads/writes `active_semester_id` on `student_profiles` |
| `course_service.dart` | `CourseService` | CRUD courses, scoped by semester_id |
| `course_result_service.dart` | `CourseResultService` | CRUD course results with course join |
| `task_service.dart` | `TaskService` | CRUD tasks, complete-all-for-deadline |
| `deadline_service.dart` | `DeadlineService` | CRUD deadlines |
| `exam_service.dart` | `ExamService` | CRUD exams |
| `study_service.dart` | `StudyService` | Insert/load study sessions |
| `mood_service.dart` | `MoodService` | CRUD mood logs, load mood settings, save mood settings |
| `analytics_service.dart` | `AnalyticsService` | Raw queries for sessions, tasks, results, courses, moods, semester data |
| `trend_service.dart` | `TrendService` | Raw queries for trend data (sessions, completed/created tasks, deadlines, results by date range) |
| `notification_service.dart` | `NotificationService` (supabase) | Insert/read notifications from DB |
| `ai_assistant_service.dart` | `AiAssistantService` | HTTP call to `acadia-ai` Edge Function |

#### AI Services (`lib/services/ai/`) — 5 Files

| File | Class | Purpose |
|---|---|---|
| `intent_parser.dart` | `AiIntentParser` | Client-side NLU: regex/keyword classification of user messages into `AiIntentType` (planWeek, planToday, rankTasks, focusNow, getTasks, getCompletedTasks, getUpcomingDeadlines, getStudySummary, getProgress, getRiskStatus, unknown) |
| `data_resolver.dart` | `AiDataResolver` | Resolves deterministic data for each intent type. Fetches tasks/deadlines from repositories, computes priority scores, builds focus session recommendations, weekly plans, daily plans, study summaries, progress reports, risk status — all with academic insight appendix |
| `academic_insight_layer.dart` | `AcademicInsightInput` | Single deterministic insight brain: takes AnalyticsData + risk + adaptive profile + burnout → produces `parts.insight` + `parts.recommendation` + `buildAppendix()`. Shared across Home nudge, AI chat, Analytics screen. Mirrors the TypeScript version in Edge Function |
| `academic_data_guard.dart` | `hasAcademicData()`, `hasEnoughSignal()` | Boolean guards: checks if tasks/sessions exist for meaningful insights |
| `ai_consistency_debug.dart` | (debug utility) | Logs consistency between Dart and TypeScript insight outputs |

#### Notification Services — 5 Files

| File | Class | Purpose |
|---|---|---|
| `notification_config.dart` | `NotificationConfig`, `NotificationTypeConfig` | 14 notification types with per-type config (isCritical, isSilent, cooldown, allowNightDelivery). Critical types (risk, overdue, task_overdue) have 4–6h cooldown and night delivery; informational types (study_goal, mood, academic_summary) have 12–24h cooldown |
| `notification_behavior_service.dart` | `NotificationBehaviorService` | SharedPreferences-backed open/ignore/sent tracking per type + per day. `canSendDaily()` (≤5/day), `canSendHighPriority()` (≤2/day), `ignoredTooMuch()` (>3 ignored), `userEngages()` (>50% open rate) |
| `notification_service.dart` | `NotificationService` | Full notification infra: local `flutter_local_notifications` + remote FCM via `send-push` Edge Function. Handles init, permissions, channel setup, scheduling, immediate delivery, cooldown enforcement, daily limits, night-time check (22:00–08:00), tap routing (deep link to relevant screen), cancel/clear |
| `notification_intelligence_service.dart` | `NotificationIntelligenceService` | Facade over SmartNotificationEngine + NotificationService + NotificationConfig. Entry point for foreground/background evaluation, config resolution, delivery deferral |
| `smart_notification_engine.dart` | `SmartNotificationEngine` | Rule-based evaluator: checks analytics (risk score, overdue, deficit, stress, consistency) and triggers contextual notifications (risk_alert, overdue_batch, study_goal_reminder, stress_warning, etc.) with proper type, cooldown, and priority |

#### Other Services

| File | Class | Purpose |
|---|---|---|
| `background_notification_service.dart` | (interface) | Abstract background notification scheduling |
| `background_notification_service_mobile.dart` | (mobile impl) | Uses `workmanager` + `background_fetch` to periodically call `NotificationIntelligenceService.evaluateBackground()` |
| `background_notification_service_stub.dart` | (stub) | No-op for unsupported platforms |
| `storage/avatar_service.dart` | `AvatarService` | Upload/delete profile avatar via Supabase Storage |

### 2.4 Repositories (`lib/repositories/`) — 13 Files

Transform raw Supabase maps into typed models. Each takes its corresponding Service via constructor.

| File | Class | Key Logic |
|---|---|---|
| `auth_repository.dart` | `AuthRepository` | Login, signUp, verifyOTP, resendOTP, OAuth, password reset, ensurePublicUserRowIfMissing (creates `users` + `student_profiles` rows on first OAuth sign-in), rate limiting with exponential backoff (60s→300s), Hive-persisted rate limit state |
| `analytics_repository.dart` | `AnalyticsRepository` | Two computation paths: (1) `getAnalyticsData` — fetches raw maps from DB, computes analytics; (2) `computeFromPreloaded` — takes already-fetched typed models, avoids duplicate queries. Computes: study hours per course, weekly average, task completion, GPA (latest retake wins), risk snapshot, burnout score, mood split (daily vs. session), consistency. 10-second per-semester cache with dedup |
| `task_repository.dart` | `TaskRepository` | CRUD, completeAllTasksForDeadline |
| `deadline_repository.dart` | `DeadlineRepository` | CRUD, markComplete (with auto-complete linked tasks) |
| `exam_repository.dart` | `ExamRepository` | CRUD exams |
| `course_repository.dart` | `CourseRepository` | CRUD courses |
| `course_result_repository.dart` | `CourseResultRepository` | CRUD course results |
| `semester_repository.dart` | `SemesterRepository` | CRUD semesters |
| `mood_repository.dart` | `MoodRepository` | CRUD mood logs, load/save mood settings |
| `study_repository.dart` | `StudyRepository` | Insert/load study sessions |
| `notification_repository.dart` | `NotificationRepository` | Read/insert/mark-read notifications |
| `trend_repository.dart` | `TrendRepository` | Computes `TrendData` from raw queries: study trend (hours/day), task trend (completed/day), workload trend (created tasks+deadlines/day), grade trend, insights (study increased/declined, workload rising, performance stable/declining/improving), percent changes. Stricter rule: performance cannot be "improving" if study dropped significantly |
| `ai_assistant_repository.dart` | `AiAssistantRepository` | Sends HTTP POST to `acadia-ai` Edge Function with auth header, message, semesterId |

### 2.5 Providers (`lib/providers/`) — 31 Files

All state management lives here. Registered in `app_providers.dart`.

| File | Provider(s) | Key Logic |
|---|---|---|
| `app_providers.dart` | `supabaseProvider`, all service providers, all repository providers, `authStateProvider`, `currentUserProvider`, `currentAppUserProvider` | Central DI hub. Wires every Service → Repository → Provider dependency |
| `semester_provider.dart` | `semestersProvider`, `activeSemesterProvider`, `orderedSemestersProvider` | CRUD semesters. ActiveSemesterNotifier: explicit selection persisted to `student_profiles.active_semester_id`, timeout guard (3s) for slow DB writes |
| `course_provider.dart` | `coursesProvider`, `activeCoursesProvider` | CRUD courses with semester scoping, legacy semester→semester_id migration |
| `tasks_provider.dart` | `tasksProvider`, `filteredTasksProvider`, `tasksTodayCountProvider` | CRUD tasks, deadline validation via domain helper, smart notification triggers on overdue/creation |
| `deadlines_provider.dart` | `deadlinesProvider`, `filteredDeadlinesProvider` | CRUD deadlines, markComplete with linked task auto-completion |
| `study_sessions_provider.dart` | `studySessionsProvider`, `studyTimerProvider` | StudyTimerNotifier: full timer state machine (idle→running→paused→completed), supports pomodoro/deep_work/review/practice, Hive-persisted timer state, app lifecycle handling (pause/resume), structured Pomodoro saves (focus/break/cycle tracking), mood attachment after session. StudySessionsNotifier: load/save/refresh |
| `exams_provider.dart` | `examsProvider`, `nextUpcomingExamProvider`, `upcomingExamsProvider`, `examUrgencyProvider` | CRUD exams, notification scheduling/canceling on create/delete |
| `mood_provider.dart` | `moodLogsProvider`, `dailyMoodLogsProvider`, `sessionMoodLogsProvider`, `moodSettingsProvider`, `moodTrackingOffSnackbarProvider` | Load moods (split by source), MoodSettingsNotifier (tracking/reminders), MoodActions (save log, session mood prompt, reminder scheduling). `moodTrackingOffSnackbarProvider` is a `StateProvider<bool>` that fires `true` when a session ends but tracking is off — the study screen listens via `ref.listenManual` and shows a one-shot SnackBar |
| `analytics_provider.dart` | `analyticsProvider`, `studyAnalyticsProvider`, `burnoutHistoryProvider`, `weeklyStudyGoalHoursProvider` | AnalyticsNotifier: cached per-semester with hash-based invalidation, readiness gate. `StudyAnalytics` class: extensive computed properties (focusScore, burnoutLevel, Pomodoro analytics, study profile, weekly trends, streaks, mood-study correlation, behavior analysis, time inconsistency, irregular patterns, excessive study detection). **Critical**: `trackingEnabled` does NOT gate mood reads in `build()` or `refreshSilently()` — the full historical mood list is always passed to `AnalyticsData`. Tracking state only controls new data collection |
| `risk_provider.dart` | `riskInputProvider`, `riskProvider` | riskInputProvider: aggregates from tasks/sessions/moods/deadlines/courses/results into `RiskInput`. riskProvider: calls `RiskCalculator.calculate()`, computes trend delta (current vs. previous snapshot) |
| `dashboard_provider.dart` | `dashboardProvider` | Aggregates: pending tasks, overdue, upcoming deadlines, study minutes, weekly goal, course stats, streak, rule-based recommendations, productivity insights. Cache to avoid blank flash |
| `decision_provider.dart` | `decisionProvider` | Orchestrates `DecisionEngine.evaluate()` with analytics, moods, tasks, deadlines, sessions |
| `decision_engine_provider.dart` | `buildDecisionSnapshotV1()` | V1: overdue priority → deadline urgency → least-studied fallback, burnout guard, focus course picker |
| `decision_engine_provider_v2.dart` | `buildDecisionSnapshotV2()` | V2: weighted scoring (urgency 34%, deficit 24%, workload 16%, weight 16%, riskSignal 10%), multi-factor course priority ranking |
| `prediction_provider.dart` | `predictionProvider` | Orchestrates `PredictionEngine.evaluate()` |
| `ai_assistant_provider.dart` | `AiAssistantNotifier` | Per-semester chat: intent parsing → local deterministic response → LLM fallback, typing animation, cancel support |
| `notifications_provider.dart` | `NotificationsNotifier` | Supabase Realtime subscriptions, triggered notification sync for tasks/deadlines/mood/study goals, legacy cleanup, dedup, optimistic mark-as-read. Tracks `_pendingLocaleReload` flag to prevent the locale-change reload from being silently dropped if an initial load is already in flight — the pending reload is retried in the `finally` block after the in-flight load completes |
| `course_results_provider.dart` | `courseResultsProvider` | Load/save/delete course results per semester |
| `student_profile_provider.dart` | `StudentProfileNotifier` | Load/update profile, onboarding completion, active_semester_id write guard |
| `adaptive_provider.dart` | `adaptiveProfileProvider` | Builds `AdaptiveProfile` from sessions + consistency |
| `trend_provider.dart` | `trendProvider` | Family with days parameter, fetches `TrendData` from repository |
| `semester_comparison_provider.dart` | `semesterComparisonProvider` | Compares current vs. previous semester analytics + risk |
| `performance_summary_provider.dart` | `performanceSummaryProvider` | Lifetime best/worst/most-improved semester identification |
| `onboarding_provider.dart` | `OnboardingNotifier` | Reads/writes Hive flag for onboarding completion |
| `locale_provider.dart` | `LocaleNotifier`, `appLocalizationsProvider` | Hive-persisted locale (en/tr) |
| `theme_provider.dart` | `ThemeNotifier` | Hive-persisted theme mode (light/dark/system) |
| `bottom_nav_provider.dart` | `bottomNavProvider` | Simple `StateProvider<int>` for current tab index |
| `global_refresh_provider.dart` | `globalRefreshProvider` | Function to refresh all providers in coordinated order |
| `semester_goal_refresh_provider.dart` | `semesterGoalRefreshProvider` | Invalidates `weeklyStudyGoalHours` when active semester changes |
| `realtime_provider.dart` | `realtimeProvider` | Supabase Realtime channel for tasks/deadlines/sessions/course_results/courses with debounced invalidation |
| `study_heatmap_provider.dart` | `studyHeatmapProvider` | Computes yearly heatmap data (days, session counts, scores) |

### 2.6 Domain Logic (`lib/domain/`) — 13 Files

Pure business rules, no Flutter or Supabase dependencies.

#### Risk (`lib/domain/risk/`) — 4 Files

| File | Class | Purpose |
|---|---|---|
| `risk_input.dart` | `RiskInput` | Aggregated inputs: overdueTasks, upcomingTasks, totalECTS, studyHours, studyGoal, studyDeficit, avgDailyStress, avgSessionStress, isStressRising, consistency, hasStressData, hasAcademicContent |
| `risk_result.dart` | `RiskResult` | Output: 6 contribution scores + totalScore + riskLevel ('low'/'medium'/'high') |
| `risk_calculator.dart` | `RiskCalculator` | Stateless wrapper over `core.RiskEngine`. Maps `RiskInput` → `RiskResult` |
| `risk_state.dart` | `RiskState` | Combines RiskInput + RiskResult + isLoading + hasData + trendDelta. Provides `getInterpretation()`, `getRiskExplanation()`, `getReasons()` with localized strings and stress > deficit override |

#### Decision (`lib/domain/decision/`) — 4 Files

| File | Class | Purpose |
|---|---|---|
| `decision_rules.dart` | `DecisionRules` | Static rules: `getRecommendedSessionMinutes` (consistency<0.5→30, stress≥6→25, else 45), `getAdaptiveMinutes` (adjusts base by completion ratio, completion rate, burnout), `isHighStress` (≥7), `isMediumStress` (5–6.9), `isLowStress` (<5), `lowMood` (<2.5), `highMood` (>4) |
| `decision_engine.dart` | `DecisionEngine` | Evaluates analytics + moods + tasks + deadlines + sessions → `DecisionResult`. Priority: stress override > deficit > low consistency > rising stress > strong state. Then: burnout guard, trend detection, deadline+stress combo, weekday pattern, factor analysis, consistency check, time-of-day context |
| `decision_result.dart` | `DecisionResult`, `DecisionItem` | items[] (warning/recommendation/insight with priority), suggestedSessionMinutes, confidence (0.3/0.6/0.9 based on data volume), emotionalStatusKey, signals[] |
| `decision_insights.dart` | `DecisionInsights` | Trend detection: `isStressTrendIncreasing` (last 3 vs. prev 3 mood logs, delta ≥1.0), `isMoodTrendDeclining` (delta ≥0.6), `worstMoodWeekday`, `mostFrequentFactor` |

#### Adaptive (`lib/domain/adaptive/`) — 2 Files

| File | Class | Purpose |
|---|---|---|
| `adaptive_profile.dart` | `AdaptiveProfile` | completionRate, avgCompletionRatio, avgActualMinutes, consistency |
| `adaptive_engine.dart` | `AdaptiveEngine` | Builds AdaptiveProfile from recent sessions: computes completion rate (actual/planned ≥0.7), average completion ratio, average actual minutes |

#### Prediction (`lib/domain/prediction/`) — 2 Files

| File | Class | Purpose |
|---|---|---|
| `prediction_result.dart` | `PredictionResult`, `StudyPlanItem`, `PredictionLevel` | predictedStress, stressLevel, stressReasons[], explanationKeys[], performanceRiskScore, performanceRiskLevel, laggingCourses[], recommendedPlan[] (3-day), confidence |
| `prediction_engine.dart` | `PredictionEngine` | Forecasts stress (daily + trend×2 + workload impact), performance risk (via RiskEngine), lagging courses (incomplete task count by course), 3-day study plan (adapts to stress/mood/deadlines/burnout), confidence (adjusted by behavior memory and recommended-duration adherence) |

#### Other Domain Files

| File | Purpose |
|---|---|
| `tasks/task_deadline_validation.dart` | Validates that a task's deadlineId references a deadline owned by the same user and aligned with the task's course |
| `academic_deadline_task.dart` | `DeadlineTaskProgress`, `tasksForDeadline()`, `deadlineStatus()` (completed/overdue/pending) |

### 2.7 Core Engine: `lib/core/services/risk_engine.dart`

The single source of truth for academic risk calculation in Dart. Pure static function:

```
RiskEngine.calculate():
  1. Overdue tasks:    min(overdueTasks × 10, 30)    → 0–30 points
  2. Due soon tasks:   min(dueSoonTasks × 5, 15)     → 0–15 points
  3. Study deficit:    min(deficitHours/24 × 25, 25)  → 0–25 points
  4. Stress:           min(stressLevel/10 × 15, 15)   → 0–15 points (0 if no stress data)
  5. Consistency:      (1-consistency) × 15           → 0–15 points

  Total = sum, clamped 0–100
  Level: <30 = low, 30–59 = moderate, ≥60 = high
```

This engine is mirrored in TypeScript in `supabase/functions/acadia-ai/unified_analytics.ts` — both must stay in sync.

### 2.8 Core Design Tokens (`lib/core/design/`) — 6 Files

| File | Tokens |
|---|---|
| `app_spacing.dart` | xs=4, sm=8, md=16, lg=16, xl=32, xxl=48, xxxl=64 |
| `app_durations.dart` | micro=50ms, fast=150ms, normal=300ms, medium=400ms, slow=500ms, verySlow=800ms |
| `app_radius.dart` | sm=8, md=16, lg=24, xl=28, pill=999 + BorderRadius getters |
| `app_blur.dart` | soft=10, glass=20, strongGlass=30 |
| `app_icons.dart` | `AppIcon` widget wrapping `HeroIcons` with size/color/solid props. ALWAYS use this, never raw `HeroIcon` |
| `app_shadows.dart` | soft (primary 25% opacity, blur 20), subtle (shadowSoft, blur 10), primaryGlow (primary 30%, blur 16) |

### 2.9 Core Theme (`lib/core/theme/`) — 3 Files

| File | Purpose |
|---|---|
| `app_colors.dart` | Full palette: primary=#3B82F6, secondary=#6366F1, dark backgrounds (#0F172A→#020617), light background (#F8FAFC), glass surfaces/borders (opacity-based), text colors (primary/secondary/tertiary for light+dark), mood colors (awful=red→great=green), stress/energy accents, mood source accents |
| `app_gradients.dart` | darkBackground (radial), lightBackground (radial), primaryAction (linear), primaryActionDisabled |
| `app_theme.dart` | Complete `ThemeData` for light+dark: Google Fonts Inter, transparent AppBar, zero-elevation buttons with 12px radius, ColorScheme.light/dark mapping |

### 2.10 Core Config (`lib/core/config/`) — 2 Files

| File | Purpose |
|---|---|
| `oauth_env.dart` | Reads `OAUTH_REDIRECT_URL` and `PASSWORD_RESET_REDIRECT_URL` from `.env`. Platform-aware: mobile uses deep link, web uses current origin or `WEB_OAUTH_REDIRECT_URL` |
| `env_validation.dart` | `validateRequiredEnv()` — throws `StateError` if SUPABASE_URL, SUPABASE_ANON_KEY, OAUTH_REDIRECT_URL, or PASSWORD_RESET_REDIRECT_URL are missing/empty |

### 2.11 Components (`lib/components/`) — 8 Files

| File | Widget | Purpose |
|---|---|---|
| `app_back_button.dart` | `AppBackButton` | GoRouter pop + haptic feedback |
| `app_button.dart` | `AppButton` | Primary / secondary / text button with scale animation + haptics |
| `app_text_field.dart` | `AppTextField` | Styled text field with optional obscure-text toggle |
| `app_glass_card.dart` | `AppGlassCard` | Glassmorphism card (border-only or filled variants) |
| `app_bottom_sheet_picker.dart` | `AppBottomSheetPicker` | Generic bottom-sheet picker with `AppPickerOption<T>` model |
| `app_section_title.dart` | `AppSectionTitle` | Centered title + subtitle column |
| `app_swipe_back.dart` | `AppSwipeBack` | Edge-swipe back gesture handler (left-edge + right-edge) |
| `destructive_confirmation_dialog.dart` | `DestructiveConfirmationDialog` | Destructive action confirmation dialog |

### 2.12 Widgets (`lib/widgets/`) — 23 Files

Organized into subdirectories by feature:

#### `mood/`
- `mood_daily_list.dart` — Horizontal list of mood emoji circles per day (scrollable or fixed Row). Tap opens `MoodDetailsBottomSheet`
- `mood_details_bottom_sheet.dart` — Detail view for a single MoodLog

#### `risk/`
- `risk_widgets.dart` — `RiskScoreCard` (big score display with trend badge), `RiskBreakdownCard` (5-row breakdown with contribution bars), `BurnoutStatusCard` (burnout level + reasons + soft interventions)

#### `ai/`
- `academic_assistant_insight_block.dart` — Deterministic insight + recommendation cards, same `AcademicInsightInput` as AI chat. Full or compact variant
- `passive_ai_home_nudge.dart` — Subtle home-row nudge when overdue/deficit/low-consistency thresholds crossed
- `passive_ai_constants.dart` — Threshold constants for nudge visibility
- `insight_card.dart` — Glass card for insight text
- `recommendation_card.dart` — Glass card for recommendation text with action button
- `insight_display_variant.dart` — `InsightDisplayVariant` enum (full/compact)
- `recommendation_action_utils.dart` — `inferRecommendationActionKind()` + `invokeRecommendationAction()` — maps recommendation text to navigation action (goToTasks, goToStudy, goToAnalytics)

#### `semester/`
- `performance_summary_widget.dart` — Horizontal scroll of best/most-improved/worst semester cards

### 2.13 Screens (`lib/screens/`) — 57 Files

Organized into 16 subdirectories:

| Directory | Files | Key Screens |
|---|---|---|
| `auth/` | 7 | LoginScreen, SignupScreen, VerifyEmailScreen, ForgotPasswordScreen, ResetPasswordScreen, OAuth callback handling |
| `home/` | 2 | HomeScreen (dashboard with risk card, insight block, nudge, upcoming items, streak) |
| `tasks/` | 7 | TasksListScreen, CreateTaskScreen, EditTaskScreen, TaskDetailScreen |
| `exams/` | 5 | ExamsListScreen, CreateExamScreen, EditExamScreen, ExamDetailScreen |
| `study/` | 4+ | StudyScreen (timer UI with Pomodoro controls, course picker, session type), StudyHistoryScreen |
| `analytics/` | 2 | AnalyticsScreen (study hours chart, task completion, GPA, mood tabs, risk breakdown, burnout card, trends, semester comparison) |
| `mood/` | 3 | MoodTrackerScreen (log mood/stress/energy/factors), MoodHistoryScreen, MoodSettingsScreen |
| `courses/` | 3 | CoursesListScreen, CreateCourseScreen, EditCourseScreen |
| `profile/` | 3 | ProfileScreen, EditProfileScreen, StudyPreferencesScreen |
| `settings/` | 2 | SettingsScreen, LanguageScreen |
| `notifications/` | 1 | NotificationsScreen — notification cards translated dynamically at UI layer using `_localizedTitle()`, `_localizedMessage()`, `_localizedContext()` helpers; watches `localeProvider`, `tasksProvider`, `deadlinesProvider` to build live reference maps so cards update instantly on locale change without a DB roundtrip |
| `onboarding/` | 2 | OnboardingWelcomeScreen, AcademicProfileSetupScreen |
| `language/` | 1 | LanguageSelectionScreen |
| `splash/` | 1 | SplashScreen |
| `app/` | 1 | AppShell (bottom nav with 5 tabs) |
| `ai/` | 2+ | AIChatScreen (chat UI with suggestions, intent-based responses, LLM fallback, insight block) |

### 2.14 Localization (`lib/l10n/`) — 6 Files

| File | Purpose |
|---|---|
| `app_en.arb` | English ARB source strings (hundreds of keys) |
| `app_tr.arb` | Turkish translations (must stay in sync) |
| `app_localizations.dart` | Base class with abstract getters for every key |
| `app_localizations_en.dart` | English implementation (concrete `@override String get` for every key) |
| `app_localizations_tr.dart` | Turkish implementation (concrete `@override String get` for every key) |
| `l10n_extension.dart` | `LocalizationHelper` extension with `get(key, params)` switch for dynamic key resolution |

**Note**: Generated files are maintained manually in this project. When adding new keys to both ARB files, also add the abstract getter to `app_localizations.dart` and concrete implementations to both `app_localizations_en.dart` and `app_localizations_tr.dart`.

**10 keys added for mood tracking disabled UX** (May 2026):
`moodTrackingOffBanner`, `moodTrackingOffBannerSubtitle`, `moodTrackingOffGoToSettings`, `moodTrackingStatusOff`, `moodTrackingStatusActive`, `moodTrackingNowEnabled`, `moodTrackingNowDisabled`, `moodTrackingHistoricalOnly`, `moodTrackingOffSessionSnackbar`, `moodTrackingOffBadge`

### 2.15 Utils (`lib/utils/`) — 2 Files

| File | Purpose |
|---|---|
| `exam_ui_utils.dart` | `getCountdownText()` (human-readable "in 2d 3h"), `getExamTypeColor()` |
| `go_router_refresh_stream.dart` | `GoRouterRefreshStream` — Listens to auth state stream and notifies GoRouter to re-evaluate redirects |

### 2.16 Supabase Backend

#### Schema (`supabase/schema.sql`)

Base tables with RLS on every table (`auth.uid() = user_id`):

- `users` — id (references auth.users), email, name, avatar_url, academic_profile_completed
- `student_profiles` — user_id, full_name, university_name, degree_type, major, academic_year, current_semester, expected_graduation_year, preferred_study_time, break_pattern, timezone, country, onboarding_complete, active_semester_id
- `semesters` — user_id, name, start_date, end_date, weekly_study_goal, is_current
- `courses` — user_id, course_name, course_code, semester, semester_id, credits, ects, color, is_active
- `tasks` — user_id, course_id, semester_id, deadline_id, title, description, priority, status, deadline, estimated_time, is_completed, completed_at
- `academic_deadlines` — user_id, course_id, semester_id, title, course, deadline_date, deadline_type, priority, notes, is_completed, completed_at
- `exams` — user_id, semester_id, course_id, title, exam_datetime, classroom, is_online, instructor_name, type, notes
- `study_sessions` — user_id, course_id, semester_id, session_type, duration_minutes, intent, completed, completed_cycles, skipped_breaks, is_pomodoro, total_focus_minutes, total_break_minutes, cycles_completed, total_cycles, mood, stress, planned_minutes, actual_minutes, started_at, ended_at
- `mood_logs` — user_id, semester_id, mood_level, stress_level, energy_level, note, factors, source
- `mood_settings` — user_id, tracking_enabled, reminder_enabled, reminder_time, reminder_type
- `course_results` — user_id, course_id, semester_id, letter_grade, final_average, result_status
- `course_result_components` — result_id, title, score, percentage
- `notifications` — user_id, reference_id, title, message, type, semester_id, is_read
- `academic_calendar` — user_id, semester, semester_start, semester_end, exam_period_start, exam_period_end

#### Migrations (`supabase/migrations/`) — 29 Files

Chronological evolution: from base schema through risk scoring, semester isolation, session_type constraints, mood settings, notification enhancements, pomodoro structured sessions, burnout tracking, and more. All use `IF NOT EXISTS` / `DO $$ ... END $$` blocks for idempotency.

#### Edge Functions

**`acadia-ai/index.ts`** — Main AI Edge Function:
- Receives: message, semesterId, auth header
- Resolves user context from Supabase DB
- Routes through OpenAI (NVIDIA endpoint) for LLM chat
- Fetches academic data (sessions, tasks, deadlines, courses, results, moods)
- Computes risk score (mirrors Dart `RiskEngine`)
- Generates academic insights (mirrors Dart `AcademicInsightInput`)
- Appends deterministic insight appendix to LLM response
- Optional: sends email digest via Resend API

**`send-push/index.ts`** — FCM relay:
- Receives: userId, title, body, data
- Fetches FCM tokens from `fcm_tokens` table
- Sends push via Firebase Cloud Messaging

### 2.17 Tests (`test/`) — 4 Files

| File | Tests |
|---|---|
| `providers/decision_engine_provider_test.dart` | V1: deadline in 2 days picks correct course (90 min), no deadlines picks least-studied, overdue overrides everything, burnout reduces duration, single course fallback |
| `providers/decision_engine_provider_v2_test.dart` | V2: deadline urgency beats least-studied, deficit weighting, multi-factor scoring |
| `providers/active_semester_ownership_test.dart` | Semester ownership validation |
| `domain/risk/risk_calculator_test.dart` | Risk score calculation with various inputs |

---

## Section 3: Integration and Interaction Among Files

### 3.1 Data Flow: End-to-End Example (Task Creation)

```
CreateTaskScreen (UI)
  → calls ref.read(tasksProvider.notifier).createTask(task)
    → TasksNotifier.createTask()
      → TaskRepository.createTask(task)
        → TaskService.createTask(data) — Supabase INSERT
          → Supabase Postgres (tasks table, RLS-enforced)
      → State update: state = AsyncValue.data([...updatedList])
      → Smart notification check: if overdue risk, trigger notification
      → ref.invalidate(analyticsProvider) — refresh analytics
      → ref.invalidate(riskProvider) — refresh risk score
```

### 3.2 Data Flow: Study Session Completion

```
StudyTimerNotifier.completeSession()
  → Saves session via StudyRepository
  → Persists mood via MoodRepository (if post-session mood captured)
  → ref.invalidate(studySessionsProvider) — refresh session list
  → ref.invalidate(analyticsProvider) — recalculate study hours/deficit
  → ref.invalidate(riskProvider) — recalculate risk (deficit/consistency changed)
  → ref.invalidate(studyAnalyticsProvider) — refresh burnout/focus
  → ref.invalidate(dashboardProvider) — refresh dashboard
  → NotificationIntelligenceService.evaluateForeground() — check if smart notification warranted
```

### 3.3 Data Flow: AI Chat

```
AIChatScreen (user types message)
  → AiAssistantNotifier.sendMessage(text)
    → AiIntentParser.parse(text) — client-side NLU
    → If recognized intent:
      → AiDataResolver.resolve(intent, userId, semesterId, analytics, risk, adaptive, burnout)
        → Fetches tasks/deadlines from repositories
        → Computes priority scores, builds response text
        → Attaches AcademicInsightInput.buildAppendix()
        → Returns AiMessage with structured data
    → If unknown intent:
      → AiAssistantRepository.sendMessage() — HTTP POST to Edge Function
        → Edge Function: OpenAI LLM call with academic context
        → Returns LLM response + server-side insight appendix
    → AiMessage displayed with typing animation
```

### 3.4 Data Flow: Risk Score Calculation

```
riskProvider (watched by RiskScoreCard, RiskBreakdownCard, AI chat, home nudge)
  ← riskInputProvider
    ← aggregates from: tasksProvider (overdue/dueSoon counts)
                        studySessionsProvider (study hours, consistency)
                        moodLogsProvider (avg stress, hasStressData)
                        deadlinesProvider (overdue/dueSoon deadline counts)
                        coursesProvider (total ECTS)
                        courseResultsProvider (grade risk adjustment)
                        analyticsProvider (studyGoal, studyDeficit)
  → RiskCalculator.calculate(input)
    → core.RiskEngine.calculate(...)
    → Returns RiskResult (score 0–100, level, breakdown)
  → trendDelta: compared with previous snapshot
```

### 3.5 Data Flow: Notification Pipeline

```
Trigger Sources:
  1. Foreground: SmartNotificationEngine.evaluate() called after session/task mutations
  2. Background: workmanager/background_fetch periodic callback → NotificationIntelligenceService.evaluateBackground()
  3. Supabase Realtime: tasks/deadlines/sessions changes → NotificationsNotifier → triggered notification sync

Evaluation Flow:
  SmartNotificationEngine.evaluate()
    → Checks analytics (risk, overdue, deficit, stress, consistency)
    → Determines notification type (risk, overdue, overdue_batch, study_goal, stress, etc.)
    → Resolves NotificationConfig (cooldown, isCritical, isSilent)
    → Checks NotificationBehaviorService:
        canSendDaily()? (≤5/day)
        canSendHighPriority()? (≤2/day for critical)
        ignoredTooMuch()? → suppress non-critical
        isNightTime()? → defer non-critical (22:00–08:00)
    → If allowed: NotificationService.showNotification()
        → Local: flutter_local_notifications
        → Remote (if FCM token exists): send-push Edge Function → FCM
    → recordSent() in NotificationBehaviorService
```

### 3.6 Provider Dependency Graph

```
app_providers.dart (root)
  ├── supabaseProvider
  ├── Service providers (each depends on supabaseProvider)
  │   ├── authServiceProvider, studentProfileServiceProvider
  │   ├── semesterServiceProvider, courseServiceProvider
  │   ├── taskServiceProvider, deadlineServiceProvider
  │   ├── examServiceProvider, studyServiceProvider
  │   ├── moodServiceProvider, analyticsServiceProvider
  │   ├── trendServiceProvider, notificationServiceProvider
  │   └── aiAssistantServiceProvider
  ├── Repository providers (each depends on its Service)
  │   ├── authRepositoryProvider (authService + studentProfileService)
  │   ├── analyticsRepositoryProvider (analyticsService)
  │   ├── taskRepositoryProvider, deadlineRepositoryProvider
  │   ├── examRepositoryProvider, courseRepositoryProvider
  │   ├── semesterRepositoryProvider, moodRepositoryProvider
  │   ├── studyRepositoryProvider, notificationRepositoryProvider
  │   ├── trendRepositoryProvider, courseResultRepositoryProvider
  │   └── aiAssistantRepositoryProvider
  ├── Auth providers
  │   ├── authStateProvider (Supabase auth stream)
  │   ├── currentUserProvider (Supabase auth.currentUser)
  │   └── currentAppUserProvider (DB-backed AppUser)
  └── Feature providers (each depends on repositories + other providers)
      ├── activeSemesterProvider → semesterRepositoryProvider
      ├── coursesProvider → courseRepositoryProvider, activeSemesterProvider
      ├── tasksProvider → taskRepositoryProvider, activeSemesterProvider
      ├── deadlinesProvider → deadlineRepositoryProvider, activeSemesterProvider
      ├── studySessionsProvider → studyRepositoryProvider, activeSemesterProvider
      ├── examsProvider → examRepositoryProvider, activeSemesterProvider
      ├── moodLogsProvider → moodRepositoryProvider, activeSemesterProvider
      ├── analyticsProvider → analyticsRepositoryProvider, activeSemesterProvider
      ├── riskInputProvider → tasksProvider + studySessionsProvider + moodLogsProvider + deadlinesProvider + coursesProvider + courseResultsProvider
      ├── riskProvider → riskInputProvider + RiskCalculator
      ├── dashboardProvider → tasksProvider + deadlinesProvider + analyticsProvider + riskProvider
      ├── decisionProvider → DecisionEngine + analyticsProvider + moodLogsProvider + tasksProvider
      ├── predictionProvider → PredictionEngine + analyticsProvider + decisionProvider
      └── aiAssistantProvider → AiIntentParser + AiDataResolver + analyticsProvider + riskProvider
```

### 3.7 Semester Scoping

Every data query in the app is scoped by `activeSemesterProvider`. This means:
- All providers filter their data by `semesterId`
- When the user switches semesters, `activeSemesterProvider` updates, which cascades invalidation through all dependent providers
- The DB enforces `semester_id` foreign keys
- The `semesterGoalRefreshProvider` specifically invalidates `weeklyStudyGoalHours` on semester change

### 3.8 Realtime Sync

`realtime_provider.dart` subscribes to Supabase Postgres Changes on 5 tables:
- `tasks` → invalidates `tasksProvider`
- `academic_deadlines` → invalidates `deadlinesProvider`
- `study_sessions` → invalidates `studySessionsProvider`
- `course_results` → invalidates `courseResultsProvider`
- `courses` → invalidates `coursesProvider`

Changes are debounced (300ms) to prevent rapid re-fetches. This ensures multi-device sync and immediate UI updates when data changes server-side.

### 3.9 Cross-Platform Risk Engine Sync

The risk calculation exists in TWO places:
1. **Dart**: `lib/core/services/risk_engine.dart` — used by all Dart providers
2. **TypeScript**: `supabase/functions/acadia-ai/unified_analytics.ts` — used by the Edge Function for AI chat

Both implement the same formula (overdue 30, dueSoon 15, deficit 25, stress 15, consistency 15). The `ai_consistency_debug.dart` service helps verify they stay in sync. If you modify one, you MUST update the other.

---

## Section 4: Dependencies and External Resources

### 4.1 Pub Package Dependencies

| Package | Version | Role |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management (all providers, StateNotifiers, AsyncValues) |
| `go_router` | ^14.1.4 | Declarative routing with auth guards |
| `supabase_flutter` | ^2.5.6 | Auth, Postgres DB, Realtime, Edge Functions client |
| `firebase_core` | ^3.6.0 | Firebase initialization (required for messaging) |
| `firebase_messaging` | ^15.1.3 | Remote push notifications (FCM) |
| `hive` + `hive_flutter` | ^2.2.3 / ^1.1.0 | Local persistence for UI prefs, timer state, rate limits |
| `flutter_dotenv` | ^5.1.0 | .env file loading (Supabase URL, keys, OAuth URLs) |
| `fl_chart` | ^0.68.0 | Study hours charts, grade distribution, trend graphs |
| `google_fonts` | ^6.2.1 | Inter font family for entire app |
| `heroicons` | ^0.10.0 | Primary icon library (wrapped by `AppIcon`) |
| `phosphor_flutter` | ^2.1.0 | Fallback icon library |
| `flutter_animate` | ^4.5.0 | Declarative animations (fade, slide, scale) |
| `lottie` | ^3.1.2 | Lottie animations (onboarding, celebrations) |
| `shimmer` | ^3.0.0 | Loading skeleton placeholders |
| `haptic_feedback` | ^0.5.1 | Tactile feedback on interactions |
| `pin_code_fields` | ^8.0.1 | OTP input fields (6-digit) |
| `image_picker` | ^1.1.2 | Profile avatar selection |
| `permission_handler` | ^12.0.1 | Runtime permission requests |
| `audioplayers` | ^5.2.1 | Pomodoro completion sound |
| `flutter_local_notifications` | ^17.0.0 | Local notification scheduling + display |
| `flutter_timezone` | ^4.1.1 | Device timezone detection |
| `timezone` | ^0.9.2 | Timezone-aware notification scheduling |
| `shared_preferences` | ^2.2.2 | Notification behavior stats persistence |
| `workmanager` | ^0.7.0 | Periodic background tasks (notification evaluation) |
| `background_fetch` | ^1.3.8 | Background fetch callback (iOS/Android) |
| `google_sign_in` | ^7.2.0 | Google OAuth |
| `sign_in_with_apple` | ^7.0.1 | Apple OAuth |
| `table_calendar` | ^3.0.9 | Calendar view for deadlines/exams |
| `intl` | ^0.20.2 | Date/number formatting, localization support |

### 4.2 External Services

| Service | Purpose | Key Used |
|---|---|---|
| **Supabase** | Auth, Postgres DB, Realtime subscriptions, Edge Functions hosting | `SUPABASE_URL` + `SUPABASE_ANON_KEY` |
| **OpenAI via NVIDIA** | LLM for AI assistant chat | `NVIDIA_API_KEY` + `NVIDIA_MODEL` |
| **Firebase Cloud Messaging** | Remote push notifications | Configured via `firebase_core` (google-services.json/GoogleService-Info.plist) |
| **Resend** | Transactional email (AI digest, reports) | `RESEND_API_KEY` |

### 4.3 Environment Variables (`.env`)

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key (public, RLS-protected) |
| `NVIDIA_API_KEY` | NVIDIA API key for OpenAI-compatible LLM endpoint |
| `NVIDIA_MODEL` | Model identifier (e.g., `meta/llama-3.1-405b-instruct`) |
| `OAUTH_REDIRECT_URL` | Deep link for OAuth callback (e.g., `com.acadia.app://auth-callback/`) |
| `PASSWORD_RESET_REDIRECT_URL` | Deep link for password reset (e.g., `com.acadia.app://reset-password`) |
| `RESEND_API_KEY` | Resend API key for email delivery |

### 4.4 Asset Dependencies

| Path | Contents |
|---|---|
| `assets/app_logo.png` | App icon source |
| `assets/images/` | Static images |
| `assets/onboarding/` | Onboarding illustrations |
| `assets/sounds/` | Pomodoro completion sound |

### 4.5 Database Constraints

- All tables have Row Level Security (RLS): `auth.uid() = user_id`
- `session_type` CHECK constraint: `pomodoro | deep_work | review | practice`
- `notification type` CHECK constraint: `deadline | task_overdue | study_goal | system` (extended in code with additional types)
- Foreign keys: `courses.semester_id → semesters.id`, `tasks.course_id → courses.id`, `tasks.deadline_id → academic_deadlines.id`, `study_sessions.course_id → courses.id`, etc.
- `letter_grade` values: AA, BA, BB, CB, CC, DC, DD, FF (ECTS scale)

---

## Section 5: Summary and Important Details

### 5.1 Key Architectural Principles

1. **Semester scoping is absolute**: Every data operation is filtered by `activeSemesterId`. Switching semesters cascades invalidation through all dependent providers. Never query without a semester scope.

2. **Risk engine is duplicated**: The same formula lives in both `lib/core/services/risk_engine.dart` (Dart) and `supabase/functions/acadia-ai/unified_analytics.ts` (TypeScript). Any change to one MUST be mirrored in the other. The `ai_consistency_debug.dart` service helps verify consistency.

3. **Academic Insight is a single brain**: `AcademicInsightInput` in `lib/services/ai/academic_insight_layer.dart` is the single deterministic source for all insight/recommendation text across the app — Home nudge, AI chat appendix, and Analytics screen all consume it. The TypeScript Edge Function mirrors this logic.

4. **Stress > Deficit Override**: In both `RiskState.getInterpretation()` and `DecisionEngine`, if `avgSessionStress >= 7`, stress takes absolute priority over study deficit messages. This is a user-requested rule to prevent deficit nagging during burnout.

5. **Tracking state is write-only**: `moodSettingsProvider.trackingEnabled` controls only NEW data collection — prompts, reminders, post-session logging. It must NEVER gate reads, analytics computations, charts, averages, or AI inputs. Violations cause visible contradictions (charts show data, metric cards say "No data"). Historical mood data is always available regardless of tracking state.

6. **Hive is ONLY for UI preferences**: Never store academic data, auth state, or anything that must survive reinstallation in Hive. The only exceptions are: theme mode, locale, onboarding welcome flag, timer state (crash recovery), rate limit counters, and notification behavior stats.

6. **Supabase is the source of truth**: Auth state, academic profile completion, active semester — all come from the database. The router reads `currentAppUserProvider` (DB-backed) for guards, never a Hive boolean.

### 5.2 Critical Business Rules

- **GPA**: German 1.0–5.0 scale is NOT used. The app uses the ECTS letter grade system (AA=4.0, BA=3.5, BB=3.0, CB=2.5, CC=2.0, DC=1.5, DD=1.0, FF=0.0) with credit-weighted averaging. For retaken courses, only the latest attempt counts.

- **Burnout Score**: `stressFactor×0.4 + deficitFactor×0.4 + consistencyFactor×0.2 × 100`. Levels: stable (<25), warning (25–49), highRisk (50–64), burnoutRisk (≥65).

- **Adaptive Session Length**: Base from `DecisionRules` → adjusted by `AdaptiveProfile` (completion ratio, completion rate) → capped by burnout (≥65→30min max, ≥50→35min max) → final clamp 10–45min.

- **Notification Limits**: 5 total/day, 2 high-priority/day. Types with >3 consecutive ignores get suppressed. Night-time (22:00–08:00) defers non-critical notifications. Critical types (risk, overdue) bypass night restriction.

- **Decision V1 vs V2**: V1 is priority-based (overdue → deadline → least-studied). V2 is weighted scoring (urgency 34%, deficit 24%, workload 16%, weight 16%, riskSignal 10%). Both coexist; V2 is the newer algorithm.

### 5.3 Known Gaps and Ambiguities

- **Test coverage**: Only 4 test files exist. The domain logic (risk engine, decision engine, prediction engine) has some coverage, but providers, repositories, services, screens, and widgets have zero automated tests.

- **Screens not fully documented**: Several large screen files (1000–2400 lines) were truncated during reading. Their full internal widget structure and event handlers are not exhaustively catalogued here.

- **Notification type expansion**: The code defines 14 notification types in `NotificationTypeConfig.allTypes`, but the DB CHECK constraint only allows 4. This suggests the constraint was not updated after the expansion, or the additional types are only used locally (not persisted to DB).

- **Analytics dual-path**: `AnalyticsRepository` has two computation paths (`getAnalyticsData` from raw DB maps, `computeFromPreloaded` from typed models). The `computeFromPreloaded` path is preferred (avoids duplicate queries) but both exist. Inconsistent usage could lead to slightly different numbers.

- **Mood source classification**: Mood logs have a `source` field ('manual' or 'session'). The analytics repository splits mood stats by this source. If all logs are classified as 'session' (e.g., source field not properly set), daily mood stats would show zero.

### 5.4 Non-Negotiable Project Rules (Summary)

1. **Icons**: HeroIcons primary, Phosphor fallback, never Material/Cupertino directly. Use `AppIcon` wrapper.
2. **Localization**: Zero hardcoded UI strings. Both `app_en.arb` and `app_tr.arb` must always be in sync. Run `flutter gen-l10n` after any ARB change.
3. **Architecture**: Strict layered pattern (Screen → Provider → Repository → Service → Supabase).
4. **State Management**: Riverpod only. Never `setState()`, `ChangeNotifier`, `InheritedWidget`, BLoC, or GetX.
5. **Database Truth**: Supabase is authoritative. Hive only for UI preferences.
6. **Navigation**: GoRouter only. Never `Navigator.push()`.
7. **Migrations**: Every schema change gets a SQL file. RLS on every table. Idempotent blocks.
8. **Lint**: Zero analyzer warnings. Remove unused imports/variables.
9. **Course Health Guard**: Block task/deadline creation if no courses exist.
10. **Theme**: Never hardcode colors/spacing/radius. Use `AppColors`, `AppSpacing`, `AppRadius`, `AppGlassCard`, `AppButton`.
11. **Provider Registration**: Every new Service/Repository MUST be registered in `app_providers.dart`.
12. **Serialization**: `fromJson`/`toJson` with snake_case keys matching DB columns. Both must be updated together.
13. **Error Handling**: Always handle `AsyncValue` loading/data/error. Never use `.value!` without null check.
14. **Session Types**: Fixed set (pomodoro, deep_work, review, practice). Adding one requires DB migration + l10n + UI.
15. **New Feature Checklist**: DB migration → Service → Repository → Model → Provider → Screen → L10n → Lint.
16. **System UI**: SafeArea on every screen, correct status bar style per theme, AnnotatedRegion for fullscreen.
17. **UX Clarity**: Never generic messages. Always include what/where/when.
18. **SQL Logging**: Every DB change executed via MCP must be saved as a `.sql` file.
19. **Async Context**: Never compare `AsyncValue` directly to its inner type. Use `.value` or `.when()`.
20. **Swipe Back**: Use shared `AppSwipeBack` widget. Never ad-hoc gesture detectors.

### 5.5 Quick Reference: File Counts

| Category | Count |
|---|---|
| Models | 23 |
| Supabase Services | 16 |
| AI Services | 5 |
| Notification Services | 5 |
| Other Services | 3 |
| Repositories | 13 |
| Providers | 31 |
| Domain Files | 13 |
| Core (theme/design/config/services/utils) | 16 |
| Components | 8 |
| Widgets | 23 |
| Screens | 57 |
| Localization | 6 |
| Utils | 2 |
| DB Migrations | 29 |
| Edge Functions | 2+ |
| Tests | 4 |
| **Total Dart files (approx)** | **~230** |

### 5.6 Common Gotchas

- **Active semester null**: Many providers return empty data if `activeSemesterProvider.value` is null. Always ensure a semester is selected before expecting data.
- **Timer state in Hive**: If the app crashes during a Pomodoro, the timer state is restored from Hive on next launch. The timer checks for stale state and discards sessions older than 24 hours.
- **GPA shows 0.0**: If no course results exist for the active semester, GPA is 0.0. This is not an error — it means the student hasn't entered grades yet.
- **Notification not showing**: Check (1) permissions granted, (2) daily limit not reached, (3) cooldown not active, (4) not night-time for non-critical type, (5) not ignored too many times.
- **AI chat "still learning"**: If the intent parser classifies as `unknown`, the app falls back to the LLM Edge Function. If the Edge Function is down or the NVIDIA API key is invalid, the user gets an error.
- **Risk trend delta is null**: On first calculation (no previous snapshot), `trendDelta` is null. The UI shows "New" badge.
