import '../../models/deadline.dart';

/// Ensures [deadlineId] references a deadline owned by the user and aligned
/// with the task's course. Returns `null` when the link would be invalid.
String? validatedDeadlineIdForTask({
  required String userId,
  required String? taskCourseId,
  required String? deadlineId,
  required List<Deadline> deadlines,
}) {
  if (deadlineId == null || deadlineId.isEmpty) return null;

  Deadline? match;
  for (final d in deadlines) {
    if (d.id == deadlineId) {
      match = d;
      break;
    }
  }
  if (match == null) return null;
  if (match.userId != userId) return null;

  final tc = taskCourseId;
  final dc = match.courseId;
  if (tc != null && dc != null) {
    return tc == dc ? deadlineId : null;
  }
  if (tc == null && dc == null) return deadlineId;
  return null;
}
