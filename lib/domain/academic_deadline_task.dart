import '../models/deadline.dart';
import '../models/task.dart';

/// Work-units linked to a fixed academic deadline.
class DeadlineTaskProgress {
  const DeadlineTaskProgress({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  double get ratio => totalCount == 0 ? 0.0 : completedCount / totalCount;
}

List<Task> tasksForDeadline(List<Task> tasks, String deadlineId) {
  return tasks.where((t) => t.deadlineId == deadlineId).toList();
}

int countCompletedTasksForDeadline(List<Task> tasks, String deadlineId) {
  return tasks
      .where((t) => t.deadlineId == deadlineId && t.status == 'completed')
      .length;
}

DeadlineTaskProgress deadlineTaskProgress(List<Task> tasks, String deadlineId) {
  final linked = tasksForDeadline(tasks, deadlineId);
  final done = linked.where((t) => t.status == 'completed').length;
  return DeadlineTaskProgress(completedCount: done, totalCount: linked.length);
}

/// COMPLETED (handled) / OVERDUE (past due, not handled) / PENDING.
enum AcademicDeadlineStatus { completed, overdue, pending }

AcademicDeadlineStatus deadlineStatus(Deadline d, DateTime now) {
  if (d.isCompleted) return AcademicDeadlineStatus.completed;
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(
    d.deadlineDate.year,
    d.deadlineDate.month,
    d.deadlineDate.day,
  );
  if (due.isBefore(today)) return AcademicDeadlineStatus.overdue;
  return AcademicDeadlineStatus.pending;
}
