import '../../models/task.dart';
import '../../services/supabase/task_service.dart';

class TaskRepository {
  final TaskService _taskService;

  TaskRepository(this._taskService);

  Future<List<Task>> getTasks({required String userId, String? semesterId}) async {
    final data = await _taskService.getTasks(userId: userId, semesterId: semesterId);
    return data.map((json) => Task.fromJson(json)).toList();
  }


  Future<List<Task>> getTasksByDeadline({
    required String userId,
    required String deadlineId,
    String? semesterId,
  }) async {
    final data = await _taskService.getTasksByDeadline(
      userId: userId,
      deadlineId: deadlineId,
      semesterId: semesterId,
    );
    return data.map((json) => Task.fromJson(json)).toList();
  }


  Future<Task> createTask(Task task) async {
    // Excluding id and created_at because defaults are set in DB
    final data = task.toJson();
    data.remove('id');
    data.remove('created_at');
    final response = await _taskService.createTask(data);
    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
    final data = Map<String, dynamic>.from(task.toJson());
    data.remove('id');
    data.remove('created_at');
    data['deadline_id'] = task.deadlineId;
    final response = await _taskService.updateTask(task.id, data);
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }

  Future<void> completeAllTasksForDeadline({
    required String userId,
    required String semesterId,
    required String deadlineId,
  }) =>
      _taskService.completeAllTasksForDeadline(
        userId: userId,
        semesterId: semesterId,
        deadlineId: deadlineId,
      );
}
