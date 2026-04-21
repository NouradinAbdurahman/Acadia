class Deadline {
  final String id;
  final String userId;
  final String title;
  final String course;
  final String? courseId;
  final String? semesterId;
  final DateTime deadlineDate;
  final String deadlineType;
  final String priority;
  final String? notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;


  /// Alias: fixed target date (same as [deadlineDate]).
  DateTime get dueDate => deadlineDate;

  /// Alias: event type (same as [deadlineType]).
  String get type => deadlineType;

  Deadline({
    required this.id,
    required this.userId,
    required this.title,
    required this.course,
    this.courseId,
    this.semesterId,
    required this.deadlineDate,
    required this.deadlineType,
    required this.priority,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });


  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      course: json['course'] as String,
      courseId: json['course_id'] as String?,
      semesterId: json['semester_id'] as String?,
      deadlineDate: DateTime.parse(json['deadline_date'] as String),
      deadlineType: json['deadline_type'] as String,
      priority: json['priority'] as String,
      notes: json['notes'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'course': course,
      if (courseId != null) 'course_id': courseId,
      if (semesterId != null) 'semester_id': semesterId,
      'deadline_date': deadlineDate.toIso8601String(),
      'deadline_type': deadlineType,
      'priority': priority,
      if (notes != null) 'notes': notes,
      'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };

  }

  Deadline copyWith({
    String? id,
    String? userId,
    String? title,
    String? course,
    String? courseId,
    String? semesterId,
    DateTime? deadlineDate,
    String? deadlineType,
    String? priority,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
  }) {

    return Deadline(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      course: course ?? this.course,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      deadlineType: deadlineType ?? this.deadlineType,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
    );

  }
}
