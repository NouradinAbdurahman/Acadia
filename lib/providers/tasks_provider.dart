import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'app_providers.dart';

final taskFilterProvider = StateProvider<String>((ref) => 'all');

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>(
  (ref) {
    final repo = ref.watch(taskRepositoryProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    final supabase = Supabase.instance.client;
    final notifier = TasksNotifier(taskRepository: repo, supabaseClient: supabase);
    if (userId != null) {
      notifier.loadTasks(userId);
    }
    return notifier;
  },
);

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);

  int byClosestDeadline(Task a, Task b) {
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
        filtered = tasks
            .where((t) => t.status == 'pending')
            .toList();
        break;
      case 'completed':
        filtered = tasks.where((t) => t.status == 'completed').toList();
        break;
      case 'overdue':
        filtered = tasks.where((t) {
          final isPastDeadline = t.deadline != null &&
              t.deadline!.isBefore(DateTime(now.year, now.month, now.day));
          return t.status == 'overdue' || isPastDeadline;
        }).toList();
        break;
      default:
        filtered = tasks;
    }
    filtered.sort(byClosestDeadline);
    return filtered;
  });
});

final tasksTodayCountProvider = Provider<int>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  return tasksAsync.when(
    data: (tasks) =>
        tasks.where((t) => t.status != 'completed').length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TasksNotifier({
    required this.taskRepository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading());

  final dynamic taskRepository;
  final SupabaseClient supabaseClient;

  Future<void> loadTasks(String userId) async {
    try {
      final list = await taskRepository.getTasks(userId) as List<Task>;
      state = AsyncValue.data(list);
    } catch (e, st) {
      print('TASK ERROR: $e');
      print('STACK TRACE: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      await loadTasks(userId);
    }
  }

  Future<void> createTask({
    required String title,
    String? course,
    String? courseId,
    DateTime? deadline,
    String? priority,
    int? estimatedHours,
    String? notes,
    String status = 'pending',
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final newTask = Task(
      id: '',
      userId: userId,
      title: title,
      course: course?.isEmpty == true ? null : course,
      courseId: courseId,
      deadline: deadline,
      priority: priority,
      estimatedTime: estimatedHours,
      notes: notes,
      status: status,
      createdAt: DateTime.now(),
    );

    try {
      final created = await taskRepository.createTask(newTask);
      state = state.whenData(
        (List<Task> tasks) => [created, ...tasks],
      );
    } catch (e, st) {
      print('TASK CREATE ERROR: $e');
      print(st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final taskWithUpdate = task.copyWith(updatedAt: DateTime.now());
      final updated = await taskRepository.updateTask(taskWithUpdate);
      state = state.whenData((List<Task> tasks) {
        return tasks
            .map<Task>(
              (t) => t.id == updated.id ? updated : t,
            )
            .toList();
      });
    } catch (e, st) {
      print('TASK UPDATE ERROR: $e');
      print(st);
      state = AsyncValue.error(e, st);
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
    try {
      await taskRepository.deleteTask(taskId);
      state = state.whenData((List<Task> tasks) {
        return tasks.where((t) => t.id != taskId).toList();
      });
    } catch (e, st) {
      print('TASK DELETE ERROR: $e');
      print(st);
      state = AsyncValue.error(e, st);
    }
  }
}

