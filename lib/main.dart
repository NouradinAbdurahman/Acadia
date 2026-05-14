import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acadia/l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';

import 'core/config/env_validation.dart';
import 'core/navigation/navigation_keys.dart';
import 'core/theme/app_theme.dart';
import 'components/app_swipe_back.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_otp_screen.dart';
import 'screens/auth/forgot_password_code_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/tasks/tasks_list_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/deadline_detail_screen.dart';
import 'screens/tasks/edit_task_screen.dart';
import 'screens/tasks/create_deadline_screen.dart';
import 'screens/tasks/edit_deadline_screen.dart';
import 'screens/exams/exams_screen.dart';
import 'screens/exams/exams_calendar_screen.dart';
import 'screens/exams/exam_detail_screen.dart';
import 'screens/exams/create_exam_screen.dart';
import 'screens/exams/edit_exam_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/academic_onboarding_screen.dart';
import 'screens/app/app_shell.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'screens/language/language_selection_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/courses/course_management_screen.dart';
import 'screens/courses/semester_management_screen.dart';
import 'screens/courses/create_course_screen.dart';
import 'screens/courses/create_semester_screen.dart';
import 'screens/courses/course_results_screen.dart';
import 'screens/courses/course_result_editor_screen.dart';
import 'screens/profile/edit_academic_profile_screen.dart';
import 'screens/profile/student_profile_summary_screen.dart';
import 'screens/profile/study_preferences_screen.dart';
import 'screens/profile/account_settings_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/profile/terms_of_service_screen.dart';
import 'screens/profile/data_permissions_screen.dart';
import 'screens/profile/contact_support_screen.dart';
import 'screens/analytics/academic_history_screen.dart';
import 'screens/mood/log_mood_screen.dart';
import 'screens/mood/mood_history_screen.dart';
import 'screens/settings/mood_settings_screen.dart';
import 'utils/go_router_refresh_stream.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/app_providers.dart';
import 'providers/realtime_provider.dart';
import 'providers/semester_goal_refresh_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/student_profile_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/semester_provider.dart';
import 'models/task.dart';
import 'services/background_notification_service.dart';
import 'services/notification_intelligence_service.dart';

import 'package:firebase_core/firebase_core.dart';

/// Runs after the first frame so cold start reaches [GoRouter] before FCM /
/// Workmanager work (avoids long splash on real Android devices).
Future<void> _initDeferredNotificationStack(bool attachFcmListeners) async {
  try {
    await NotificationService.init(
      attachForegroundListeners: attachFcmListeners,
    );
  } catch (e, st) {
    debugPrint('[Startup] NotificationService.init failed: $e');
    debugPrintStack(stackTrace: st);
  }
  try {
    await BackgroundNotificationService.initialize(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e, st) {
    debugPrint('[Startup] BackgroundNotificationService.initialize failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('[Startup] 1/5 — Flutter binding ready');

      var isFirebaseInitialized = false;
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 10));
        isFirebaseInitialized = true;
        debugPrint('[Startup] 2/5 — Firebase initialized');
      } on TimeoutException {
        debugPrint(
          '[Startup] 2/5 — Firebase.initializeApp timed out after 10s, continuing without FCM',
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[Startup] 2/5 — Firebase init failed, continuing without FCM. Error: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }

      await Hive.initFlutter();
      await Hive.openBox('settings');
      debugPrint('[Startup] 3/5 — Hive ready');

      await dotenv.load(fileName: '.env');
      validateRequiredEnv();
      debugPrint('[Startup] 4/5 — dotenv loaded');

      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!.trim(),
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          detectSessionInUri: true,
        ),
      );
      debugPrint('[Startup] 5/5 — Supabase initialized');

      if (kDebugMode) {
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          debugPrint('EVENT: ${data.event}');
          debugPrint('SESSION: ${data.session != null ? 'not null' : 'null'}');
          if (data.session != null) {
            debugPrint('SIGNED IN SUCCESSFULLY');
          }
        });
      }

      runApp(const ProviderScope(child: MyApp()));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initDeferredNotificationStack(isFirebaseInitialized));
        unawaited(ReviewService.onAppLaunch());
      });
    },
    (Object error, StackTrace stack) {
      // Deep-link PKCE failures call notifyException → can surface here; avoid crashing debug builds.
      if (error is AuthException) {
        debugPrint('Supabase auth (handled): ${error.message}');
        return;
      }
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild the router when these providers change
  final localeLoaded = ref.watch(localeLoadedProvider);
  final onboardingLoaded = ref.watch(onboardingLoadedProvider);
  final appUserAsync = ref.watch(currentAppUserProvider);
  final onboardingCompleted = ref.watch(onboardingProvider);
  final languageSelected = ref.watch(languageSelectedProvider);
  final themeLoaded = ref.watch(themeLoadedProvider);
  final activeSemesterAsync = ref.watch(activeSemesterProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(
        Supabase.instance.client.auth.onAuthStateChange.where(
          (event) =>
              event.event != AuthChangeEvent.tokenRefreshed &&
              event.event != AuthChangeEvent.mfaChallengeVerified,
        ),
      ),
    ]),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordOTPScreen(),
      ),
      GoRoute(
        path: '/forgot-password-code',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ForgotPasswordCodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final sessionToken = state.uri.queryParameters['sessionToken'] ?? '';
          return ResetPasswordScreen(email: email, sessionToken: sessionToken);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final fullName = state.uri.queryParameters['fullName'] ?? '';
          return VerifyEmailScreen(email: email, fullName: fullName);
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const AppShell()),
      GoRoute(path: '/app', builder: (context, state) => const AppShell()),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksListScreen(),
      ),
      GoRoute(
        path: '/create-task',
        builder: (context, state) => CreateTaskScreen(
          initialDeadlineId: state.uri.queryParameters['deadlineId'],
          initialCourseId: state.uri.queryParameters['courseId'],
        ),
      ),
      GoRoute(
        path: '/create-deadline',
        builder: (context, state) => const CreateDeadlineScreen(),
      ),
      GoRoute(path: '/exams', builder: (context, state) => const ExamsScreen()),
      GoRoute(
        path: '/exams-calendar',
        builder: (context, state) => const ExamsCalendarScreen(),
      ),
      GoRoute(
        path: '/exam-detail',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return ExamDetailScreen(examId: id);
        },
      ),
      GoRoute(
        path: '/create-exam',
        builder: (context, state) => const CreateExamScreen(),
      ),
      GoRoute(
        path: '/edit-exam',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return EditExamScreen(examId: id);
        },
      ),
      GoRoute(
        path: '/task-detail',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        path: '/deadline-detail',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return DeadlineDetailScreen(deadlineId: id);
        },
      ),
      GoRoute(
        path: '/edit-task',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return EditTaskScreen(taskId: id);
        },
      ),
      GoRoute(
        path: '/edit-deadline',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return EditDeadlineScreen(deadlineId: id);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/academic-onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AcademicOnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/onboarding-semester',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateSemesterScreen(isOnboarding: true),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/mood/log',
        builder: (context, state) {
          final source = state.uri.queryParameters['source'] ?? 'manual';
          return LogMoodScreen(source: source);
        },
      ),
      GoRoute(
        path: '/mood/history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: '/settings/mood-stress',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const MoodSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/courses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CourseManagementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/semesters',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const SemesterManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/create-course',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const CreateCourseScreen(),
        ),
      ),
      GoRoute(
        path: '/course-results',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const CourseResultsScreen(),
        ),
      ),
      GoRoute(
        path: '/academic-history',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const AcademicHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/course-results/edit',
        pageBuilder: (context, state) {
          final resultId = state.uri.queryParameters['id'];
          final semesterId =
              state.uri.queryParameters['semesterId'] ??
              state.uri.queryParameters['semester'];
          return CupertinoPage<void>(
            key: state.pageKey,
            child: CourseResultEditorScreen(
              resultId: resultId,
              initialSemesterId: semesterId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/profile/student-summary',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const StudentProfileSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const EditAcademicProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/courses',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const CourseManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/study-preferences',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const StudyPreferencesScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/account-settings',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const AccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/privacy-policy',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/terms-of-service',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const TermsOfServiceScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/data-permissions',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const DataPermissionsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/contact-support',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const ContactSupportScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;

      final isSplashScreen = state.matchedLocation == '/splash';
      final isAuthScreen =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/forgot-password-code' ||
          state.matchedLocation == '/reset-password' ||
          state.matchedLocation == '/verify-email';
      final isLanguageScreen = state.matchedLocation == '/language';
      final isOnboardingScreen = state.matchedLocation == '/onboarding';
      final isAcademicOnboardingScreen =
          state.matchedLocation == '/academic-onboarding';

      // 0. Wait for Hive-backed settings and initial providers to load
      if (!localeLoaded || !onboardingLoaded || !themeLoaded) {
        return isSplashScreen ? null : '/splash';
      }

      // 1. Auth Gate
      if (!loggedIn) {
        if (!languageSelected && !isLanguageScreen) return '/language';
        if (languageSelected && !onboardingCompleted && !isOnboardingScreen) {
          return '/onboarding';
        }
        if (languageSelected &&
            onboardingCompleted &&
            !isAuthScreen &&
            !isSplashScreen &&
            !isLanguageScreen &&
            !isOnboardingScreen) {
          return '/login';
        }
        return isSplashScreen
            ? (!languageSelected
                  ? '/language'
                  : (!onboardingCompleted ? '/onboarding' : '/login'))
            : null;
      }

      // 2. Profile Loading Wait
      if (appUserAsync.isLoading) {
        return isSplashScreen ? null : '/splash';
      }

      final appUser = appUserAsync.asData?.value;

      // 3. Academic Onboarding Enforcement
      // If profile record is missing or not completed, force academic onboarding
      if (appUser == null || !appUser.academicProfileCompleted) {
        // Allow reset/verify even if profile not completed
        if (isAcademicOnboardingScreen ||
            state.matchedLocation == '/reset-password' ||
            state.matchedLocation == '/verify-email') {
          return null;
        }
        return '/academic-onboarding';
      }

      // 3.5. Active-semester guard — enforce first semester creation
      final isOnboardingSemesterScreen =
          state.matchedLocation == '/onboarding-semester';
      if (activeSemesterAsync.isLoading) {
        // Wait for the active-semester check before deciding
        return isSplashScreen ? null : '/splash';
      }
      if (activeSemesterAsync.asData?.value == null &&
          !isOnboardingSemesterScreen) {
        return '/onboarding-semester';
      }

      // 4. Entry redirection to home
      // NOTE: /onboarding-semester is intentionally NOT here — the screen
      // navigates itself to /home via context.go() after semester creation.
      if (isSplashScreen ||
          isAuthScreen ||
          isLanguageScreen ||
          isOnboardingScreen ||
          (isAcademicOnboardingScreen && appUser.academicProfileCompleted)) {
        return '/home';
      }

      return null;
    },
  );
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _didInitialEvaluate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateIntelligence();
    }
  }

  SystemUiOverlayStyle _overlayStyleForTheme(ThemeMode themeMode) {
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  Future<void> _evaluateIntelligence() async {
    final analytics = ref.read(analyticsProvider).valueOrNull;
    if (analytics == null) return;

    Future<List<Task>> fetcher() async {
      final userId = ref.read(currentUserProvider)?.id;
      final semesterId = ref.read(activeSemesterProvider).value;
      if (userId == null) return <Task>[];

      try {
        final repo = ref.read(taskRepositoryProvider);
        return await repo.getTasks(userId: userId, semesterId: semesterId);
      } catch (_) {
        return ref.read(tasksProvider).valueOrNull ?? <Task>[];
      }
    }

    await NotificationIntelligenceService.evaluateForeground(
      analytics: analytics,
      fetchTasks: fetcher,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    ref.read(realtimeProvider);
    ref.watch(semesterGoalRefreshProvider);
    ref.listen(analyticsProvider, (prev, next) {
      next.whenData((_) => _evaluateIntelligence());
    });
    ref.listen(authStateProvider, (prev, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn &&
            authState.session != null) {
          Future(() async {
            try {
              await ref
                  .read(authRepositoryProvider)
                  .ensurePublicUserRowIfMissing();
            } catch (e) {
              // Log clearly so RLS / network failures are visible in the console.
              debugPrint(
                '[AuthListener] ensurePublicUserRowIfMissing failed: $e',
              );
            }
            ref.invalidate(currentAppUserProvider);
            ref.invalidate(studentProfileProvider);
          });
        }
      });
    });
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final overlayStyle = _overlayStyleForTheme(themeMode);

    if (!_didInitialEvaluate) {
      _didInitialEvaluate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _evaluateIntelligence();
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp.router(
        title: 'Acadia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        routerConfig: router,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: _overlayStyleForTheme(themeMode),
            child: UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: const Duration(days: 1),
              ),
              dialogStyle: UpgradeDialogStyle.cupertino,
              child: AppSwipeBack(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    );
  }
}
