import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_provider.dart';
import '../services/supabase/auth_service.dart';
import '../services/supabase/task_service.dart';
import '../services/supabase/study_service.dart';
import '../services/supabase/exam_service.dart';
import '../services/supabase/mood_service.dart';
import '../services/supabase/analytics_service.dart';
import '../services/supabase/deadline_service.dart';
import '../services/supabase/course_service.dart';
import '../services/supabase/semester_service.dart';
import '../services/supabase/notification_service.dart';
import '../services/storage/avatar_service.dart';

import '../repositories/auth_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/study_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/mood_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/deadline_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/semester_repository.dart';
import '../repositories/notification_repository.dart';
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
final semesterServiceProvider = Provider<SemesterService>((ref) => SemesterService(ref.watch(supabaseProvider)));
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref.watch(supabaseProvider)));
final avatarServiceProvider = Provider<AvatarService>((ref) => AvatarService(ref.watch(supabaseProvider)));


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
final semesterRepositoryProvider = Provider<SemesterRepository>((ref) => SemesterRepository(ref.watch(semesterServiceProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(notificationServiceProvider)));


// --- STATE PROVIDERS ---
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getUserProfile(user.id);
});

// --- DATA PROVIDERS ---
// Course provider is managed in course_provider.dart

// Active courses provider moved to course_provider.dart

// Tasks and Deadlines are managed in their own providers for state updates

// Providers for tasks and deadlines are found in their respective files.


