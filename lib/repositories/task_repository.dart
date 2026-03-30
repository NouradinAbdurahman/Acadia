import '../../models/task.dart';
import '../../services/supabase/task_service.dart';

class TaskRepository {
  final TaskService _taskService;

  TaskRepository(this._taskService);

  Future<List<Task>> getTasks(String userId) async {
    final data = await _taskService.getTasks(userId);
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
    final response = await _taskService.updateTask(task.id, task.toJson());
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }
}
