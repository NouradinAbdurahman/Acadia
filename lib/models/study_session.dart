import 'package:acadia/models/course.dart';

class StudySession {
  final String id;
  final String userId;
  final String courseId;
  final String semesterId;
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
  final double? mood;
  final double? stress;
  final int? plannedMinutes;
  final int? actualMinutes;
  final DateTime? startedAt;
  final DateTime? endedAt;


  StudySession({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.semesterId,
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
    this.mood,
    this.stress,
    this.plannedMinutes,
    this.actualMinutes,
    this.startedAt,
    this.endedAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final isPomodoro = json['is_pomodoro'] as bool? ?? false;
    final totalFocusMinutes = json['total_focus_minutes'] as int?;
    final dynamic courseJoinRaw = json['courses'];
    final Map<String, dynamic>? courseJoin = courseJoinRaw is List
        ? (courseJoinRaw.isNotEmpty && courseJoinRaw.first is Map
            ? Map<String, dynamic>.from(courseJoinRaw.first as Map)
            : null)
        : (courseJoinRaw is Map
          ? Map<String, dynamic>.from(courseJoinRaw)
            : null);
    final semesterId = (json['semester_id'] as String?) ??
      (courseJoin != null
        ? courseJoin['semester_id'] as String?
        : null) ??
      '';
    // For Pomodoro sessions, durationMinutes mirrors totalFocusMinutes for
    // backwards-compatible analytics queries.
    final durationMinutes = isPomodoro
        ? (totalFocusMinutes ?? (json['duration_minutes'] as num).toInt())
        : (json['duration_minutes'] as num).toInt();

    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      semesterId: semesterId,
      sessionType: json['session_type'] as String,
      durationMinutes: durationMinutes,
      createdAt: DateTime.parse(json['created_at'] as String),
      course: courseJoin != null ? Course.fromJson(courseJoin) : null,
      intent: json['intent'] as String?,
      completed: json['completed'] as bool? ?? true,
      completedCycles: json['completed_cycles'] as int?,
      skippedBreaks: json['skipped_breaks'] as int?,
      isPomodoro: isPomodoro,

      totalFocusMinutes: totalFocusMinutes,
      totalBreakMinutes: json['total_break_minutes'] as int?,
      cyclesCompleted: json['cycles_completed'] as int?,
      totalCycles: json['total_cycles'] as int?,
      mood: (json['mood'] as num?)?.toDouble(),
      stress: (json['stress'] as num?)?.toDouble(),
      plannedMinutes: (json['planned_minutes'] as num?)?.toInt(),
      actualMinutes: (json['actual_minutes'] as num?)?.toInt() ?? durationMinutes,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : DateTime.parse(json['created_at'] as String).add(
              Duration(minutes: durationMinutes),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'course_id': courseId,
      'semester_id': semesterId,
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
      if (mood != null) 'mood': mood,
      if (stress != null) 'stress': stress,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    };
  }

  StudySession copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? semesterId,
    String? sessionType,
    int? durationMinutes,
    DateTime? createdAt,
    Course? course,
    String? intent,
    bool? completed,
    int? completedCycles,
    int? skippedBreaks,
    bool? isPomodoro,
    int? totalFocusMinutes,
    int? totalBreakMinutes,
    int? cyclesCompleted,
    int? totalCycles,
    double? mood,
    double? stress,
    int? plannedMinutes,
    int? actualMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sessionType: sessionType ?? this.sessionType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      course: course ?? this.course,
      intent: intent ?? this.intent,
      completed: completed ?? this.completed,
      completedCycles: completedCycles ?? this.completedCycles,
      skippedBreaks: skippedBreaks ?? this.skippedBreaks,
      isPomodoro: isPomodoro ?? this.isPomodoro,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      totalCycles: totalCycles ?? this.totalCycles,
      mood: mood ?? this.mood,
      stress: stress ?? this.stress,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
