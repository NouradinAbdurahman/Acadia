import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/tasks/task_deadline_validation.dart';
import '../models/task.dart';
import 'app_providers.dart';
import 'deadlines_provider.dart';
import 'semester_provider.dart';


final taskFilterProvider = StateProvider<String>((ref) => 'all');

/// Tasks screen primary tab: show only tasks or only deadlines (never mixed).
final tasksListSegmentProvider = StateProvider<String>((ref) => 'tasks');

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  final semesterId = ref.watch(activeSemesterProvider);
  final supabase = Supabase.instance.client;
  final notifier = TasksNotifier(
    ref: ref,
    taskRepository: repo,
    supabaseClient: supabase,
  );
  if (userId != null) {
    notifier.loadTasks(userId: userId, semesterId: semesterId);
  }
  return notifier;
});


final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);

  int compareTasks(Task a, Task b) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    bool isOverdue(Task t) {
      if (t.status == 'completed') return false;
      if (t.status == 'overdue') return true;
      return t.deadline != null && t.deadline!.isBefore(startOfToday);
    }
    
    bool aIsOverdue = isOverdue(a);
    bool bIsOverdue = isOverdue(b);
    bool aIsCompleted = a.status == 'completed';
    bool bIsCompleted = b.status == 'completed';

    if (aIsCompleted && !bIsCompleted) return 1;
    if (!aIsCompleted && bIsCompleted) return -1;
    
    if (aIsOverdue && !bIsOverdue) return -1;
    if (!aIsOverdue && bIsOverdue) return 1;

    final aDate = a.deadline;
    final bDate = b.deadline;

    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  return tasksAsync.whenData((List<Task> tasks) {
    final now = DateTime.now();
    List<Task> filtered;
    switch (filter) {
      case 'pending':
        filtered = tasks.where((t) => t.status == 'pending').toList();
        break;
      case 'completed':
        filtered = tasks.where((t) => t.status == 'completed').toList();
        break;
      case 'overdue':
        filtered = tasks.where((t) {
          final isPastDeadline =
              t.deadline != null &&
              t.deadline!.isBefore(DateTime(now.year, now.month, now.day));
          return t.status == 'overdue' || isPastDeadline;
        }).toList();
        break;
      default:
        filtered = tasks;
    }
    
    final sorted = List<Task>.from(filtered)..sort(compareTasks);
    return sorted;
  });
});

final tasksTodayCountProvider = Provider<int>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  return tasksAsync.when(
    data: (tasks) => tasks.where((t) => t.status != 'completed').length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TasksNotifier({
    required Ref ref,
    required this.taskRepository,
    required this.supabaseClient,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;
  final dynamic taskRepository;
  final SupabaseClient supabaseClient;

  Future<void> loadTasks({required String userId, String? semesterId}) async {
    try {
      // Preserve previous data during refresh so UI doesn't blank/flicker.
      state = const AsyncValue<List<Task>>.loading().copyWithPrevious(state);
      final list = await taskRepository.getTasks(userId: userId, semesterId: semesterId) as List<Task>;
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = _ref.read(activeSemesterProvider);
    if (userId != null) {
      await loadTasks(userId: userId, semesterId: semesterId);
    }
  }


  Future<void> createTask({
    required String title,
    String? course,
    String? courseId,
    DateTime? deadline,
    String? deadlineId,
    String? priority,
    int? estimatedHours,
    String? notes,
    String status = 'pending',
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final semesterId = _ref.read(activeSemesterProvider);
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot create task.');
    }


    final deadlinesList = _ref.read(deadlinesProvider).valueOrNull ?? const [];
    final safeDeadlineId = validatedDeadlineIdForTask(
      userId: userId,
      taskCourseId: courseId,
      deadlineId: deadlineId,
      deadlines: deadlinesList,
    );

    final newTask = Task(
      id: '',
      userId: userId,
      title: title,
      course: course?.isEmpty == true ? null : course,
      courseId: courseId,
      semesterId: semesterId,
      deadline: deadline,
      deadlineId: safeDeadlineId,
      priority: priority,
      estimatedTime: estimatedHours,
      notes: notes,
      status: status,
      createdAt: DateTime.now(),
    );


    final previous = state;
    try {
      final created = await taskRepository.createTask(newTask);
      state = state.whenData((List<Task> tasks) => [created, ...tasks]);
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    final deadlinesList = _ref.read(deadlinesProvider).valueOrNull ?? const [];
    final safeDeadlineId = validatedDeadlineIdForTask(
      userId: task.userId,
      taskCourseId: task.courseId,
      deadlineId: task.deadlineId,
      deadlines: deadlinesList,
    );
    final taskWithUpdate = task
        .copyWith(
          deadlineId: safeDeadlineId,
          clearDeadlineId: safeDeadlineId == null && task.deadlineId != null,
          updatedAt: DateTime.now(),
        );

    final previous = state;
    try {
      final updated = await taskRepository.updateTask(taskWithUpdate);
      state = state.whenData((List<Task> tasks) {
        return tasks
            .map<Task>((t) => t.id == updated.id ? updated : t)
            .toList();
      });
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final current = state.value;
    if (current == null) return;

    final index = current.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final existing = current[index];
    final updated = existing.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    await updateTask(updated);
  }

  Future<void> deleteTask(String taskId) async {
    final previous = state;
    try {
      await taskRepository.deleteTask(taskId);
      state = state.whenData((List<Task> tasks) {
        return tasks.where((t) => t.id != taskId).toList();
      });
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}
