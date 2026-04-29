import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase/auth_service.dart';
import '../services/supabase/task_service.dart';
import '../services/supabase/study_service.dart';
import '../services/supabase/exam_service.dart';
import '../services/supabase/mood_service.dart';
import '../services/supabase/analytics_service.dart';
import '../services/supabase/deadline_service.dart';
import '../services/supabase/course_service.dart';
import '../services/supabase/course_result_service.dart';
import '../services/supabase/semester_service.dart';
import '../services/supabase/notification_service.dart';
import '../services/supabase/trend_service.dart';
import '../services/supabase/ai_assistant_service.dart';
import '../services/ai/intent_parser.dart';
import '../services/ai/data_resolver.dart';
import '../services/storage/avatar_service.dart';

import '../repositories/auth_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/study_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/mood_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/deadline_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/course_result_repository.dart';
import '../repositories/semester_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/trend_repository.dart';
import '../repositories/ai_assistant_repository.dart';
import '../models/app_user.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// --- SERVICES ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(supabaseProvider)));
final taskServiceProvider = Provider<TaskService>((ref) => TaskService(ref.watch(supabaseProvider)));
final studyServiceProvider = Provider<StudyService>((ref) => StudyService(ref.watch(supabaseProvider)));
final examServiceProvider = Provider<ExamService>((ref) => ExamService(ref.watch(supabaseProvider)));
final moodServiceProvider = Provider<MoodService>((ref) => MoodService(ref.watch(supabaseProvider)));
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService(ref.watch(supabaseProvider)));
final deadlineServiceProvider =
    Provider<DeadlineService>((ref) => DeadlineService(ref.watch(supabaseProvider)));
final courseServiceProvider = Provider<CourseService>((ref) => CourseService(ref.watch(supabaseProvider)));
final courseResultServiceProvider =
    Provider<CourseResultService>((ref) => CourseResultService(ref.watch(supabaseProvider)));
final semesterServiceProvider = Provider<SemesterService>((ref) => SemesterService(ref.watch(supabaseProvider)));
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref.watch(supabaseProvider)));
final trendServiceProvider = Provider<TrendService>((ref) => TrendService(ref.watch(supabaseProvider)));
final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) => AiAssistantService(ref.watch(supabaseProvider)));
final avatarServiceProvider = Provider<AvatarService>((ref) => AvatarService(ref.watch(supabaseProvider)));

// AI Logic Services
final aiIntentParserProvider = Provider<AiIntentParser>((ref) => AiIntentParser());
final aiDataResolverProvider = Provider<AiDataResolver>((ref) {
  return AiDataResolver(
    ref.watch(taskRepositoryProvider),
    ref.watch(deadlineRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
  );
});


// --- REPOSITORIES ---
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(authServiceProvider)));
final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository(ref.watch(taskServiceProvider)));
final studyRepositoryProvider = Provider<StudyRepository>((ref) => StudyRepository(ref.watch(studyServiceProvider)));
final examRepositoryProvider = Provider<ExamRepository>((ref) => ExamRepository(ref.watch(examServiceProvider)));
final moodRepositoryProvider = Provider<MoodRepository>((ref) => MoodRepository(ref.watch(moodServiceProvider)));
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) => AnalyticsRepository(ref.watch(analyticsServiceProvider)));
final deadlineRepositoryProvider =
    Provider<DeadlineRepository>((ref) => DeadlineRepository(ref.watch(deadlineServiceProvider)));
final courseRepositoryProvider = Provider<CourseRepository>((ref) => CourseRepository(ref.watch(courseServiceProvider)));
final courseResultRepositoryProvider = Provider<CourseResultRepository>(
  (ref) => CourseResultRepository(ref.watch(courseResultServiceProvider)),
);
final semesterRepositoryProvider = Provider<SemesterRepository>((ref) => SemesterRepository(ref.watch(semesterServiceProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(notificationServiceProvider)));
final trendRepositoryProvider = Provider<TrendRepository>((ref) => TrendRepository(ref.watch(trendServiceProvider)));
final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) => AiAssistantRepository(ref.watch(aiAssistantServiceProvider)));


// --- STATE PROVIDERS ---
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  debugPrint("Fetching current user from database...");
  debugPrint("Auth user id: ${Supabase.instance.client.auth.currentUser?.id}");
  
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint("Fetched user: null (no auth user)");
    return null;
  }
  
  final authRepo = ref.watch(authRepositoryProvider);
  final appUser = await authRepo.getUserProfile(user.id);
  debugPrint("Fetched user: $appUser");
  return appUser;
});

// --- DATA PROVIDERS ---
// Course provider is managed in course_provider.dart

// Active courses provider moved to course_provider.dart

// Tasks and Deadlines are managed in their own providers for state updates

// Providers for tasks and deadlines are found in their respective files.


