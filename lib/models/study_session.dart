import 'package:acadia/models/course.dart';

class StudySession {
  final String id;
  final String userId;
  final String courseId;
  final String sessionType;
  final int durationMinutes;
  final DateTime createdAt;
  final Course? course;
  final String? intent;
  final bool completed;
  final int? completedCycles;
  final int? skippedBreaks;

  // ── Pomodoro structured session fields ──
  final bool isPomodoro;
  final int? totalFocusMinutes;
  final int? totalBreakMinutes;
  final int? cyclesCompleted;
  final int? totalCycles;

  StudySession({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.sessionType,
    required this.durationMinutes,
    required this.createdAt,
    this.course,
    this.intent,
    this.completed = true,
    this.completedCycles,
    this.skippedBreaks,
    this.isPomodoro = false,
    this.totalFocusMinutes,
    this.totalBreakMinutes,
    this.cyclesCompleted,
    this.totalCycles,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final isPomodoro = json['is_pomodoro'] as bool? ?? false;
    final totalFocusMinutes = json['total_focus_minutes'] as int?;
    // For Pomodoro sessions, durationMinutes mirrors totalFocusMinutes for
    // backwards-compatible analytics queries.
    final durationMinutes = isPomodoro
        ? (totalFocusMinutes ?? (json['duration_minutes'] as num).toInt())
        : (json['duration_minutes'] as num).toInt();

    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      sessionType: json['session_type'] as String,
      durationMinutes: durationMinutes,
      createdAt: DateTime.parse(json['created_at'] as String),
      course: json['courses'] != null ? Course.fromJson(json['courses']) : null,
      intent: json['intent'] as String?,
      completed: json['completed'] as bool? ?? true,
      completedCycles: json['completed_cycles'] as int?,
      skippedBreaks: json['skipped_breaks'] as int?,
      isPomodoro: isPomodoro,
      totalFocusMinutes: totalFocusMinutes,
      totalBreakMinutes: json['total_break_minutes'] as int?,
      cyclesCompleted: json['cycles_completed'] as int?,
      totalCycles: json['total_cycles'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'course_id': courseId,
      'session_type': sessionType,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
      if (intent != null) 'intent': intent,
      'completed': completed,
      if (completedCycles != null) 'completed_cycles': completedCycles,
      if (skippedBreaks != null) 'skipped_breaks': skippedBreaks,
      'is_pomodoro': isPomodoro,
      if (totalFocusMinutes != null) 'total_focus_minutes': totalFocusMinutes,
      if (totalBreakMinutes != null) 'total_break_minutes': totalBreakMinutes,
      if (cyclesCompleted != null) 'cycles_completed': cyclesCompleted,
      if (totalCycles != null) 'total_cycles': totalCycles,
    };
  }
}
