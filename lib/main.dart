import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acadia/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
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
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/academic_onboarding_screen.dart';
import 'screens/app/app_shell.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'screens/language/language_selection_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/courses/course_management_screen.dart';
import 'screens/courses/create_course_screen.dart';
import 'screens/profile/edit_academic_profile_screen.dart';
import 'screens/profile/study_preferences_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'utils/go_router_refresh_stream.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/app_providers.dart';

// We declare a globally accessible navigator key to handle programmatic pushes if necessary
final _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
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

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
      // We can also add other listenables here if needed
    ]),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
          final shouldResend = state.uri.queryParameters['resend'] == '1';
          return VerifyEmailScreen(
            email: email,
            fullName: fullName,
            shouldResendCodeOnLoad: shouldResend,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksListScreen(),
      ),
      GoRoute(
        path: '/create-task',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: '/create-deadline',
        builder: (context, state) => const CreateDeadlineScreen(),
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
              position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOutCubic))),
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
        path: '/courses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CourseManagementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/create-course',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateCourseScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditAcademicProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile/study-preferences',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StudyPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            );
          },
        ),
      ),
    ],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      
      final isSplashScreen = state.matchedLocation == '/splash';
      final isAuthScreen = state.matchedLocation == '/login' || 
          state.matchedLocation == '/signup' || 
          state.matchedLocation == '/forgot-password' || 
          state.matchedLocation == '/forgot-password-code' || 
          state.matchedLocation == '/reset-password' || 
          state.matchedLocation == '/verify-email';
      final isLanguageScreen = state.matchedLocation == '/language';
      final isOnboardingScreen = state.matchedLocation == '/onboarding';
      final isAcademicOnboardingScreen = state.matchedLocation == '/academic-onboarding';

      // 0. Wait for Hive-backed settings and initial providers to load
      if (!localeLoaded || !onboardingLoaded || !themeLoaded) {
        return isSplashScreen ? null : '/splash';
      }

      // 1. Auth Gate
      if (!loggedIn) {
        if (!languageSelected && !isLanguageScreen) return '/language';
        if (languageSelected && !onboardingCompleted && !isOnboardingScreen) return '/onboarding';
        if (languageSelected && onboardingCompleted && !isAuthScreen && !isSplashScreen && !isLanguageScreen && !isOnboardingScreen) return '/login';
        return isSplashScreen ? (!languageSelected ? '/language' : (!onboardingCompleted ? '/onboarding' : '/login')) : null;
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
        if (isAcademicOnboardingScreen || state.matchedLocation == '/reset-password' || state.matchedLocation == '/verify-email') {
          return null;
        }
        return '/academic-onboarding';
      }

      // 4. Entry redirection to home
      if (isSplashScreen || isAuthScreen || isLanguageScreen || isOnboardingScreen || (isAcademicOnboardingScreen && appUser.academicProfileCompleted)) {
        return '/home';
      }

      return null;
    },
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  SystemUiOverlayStyle _overlayStyleForTheme(ThemeMode themeMode) {
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformBrightness == Brightness.dark);

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final overlayStyle = _overlayStyleForTheme(themeMode);

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
        supportedLocales: const [
          Locale('en'),
          Locale('tr'),
        ],
        routerConfig: router,
        builder: (context, child) {
          // Additional safety layer for status bar visibility
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: _overlayStyleForTheme(themeMode),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
