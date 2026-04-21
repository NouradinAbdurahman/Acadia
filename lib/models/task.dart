class Task {
  final String id;
  final String userId;
  final String title;
  final String? course;
  final String? courseId;
  final String? semesterId;
  final DateTime? deadline;

  /// Optional link to an [academic_deadlines] row (work target).
  final String? deadlineId;
  final String? priority;
  final int? estimatedTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;


  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.course,
    this.courseId,
    this.semesterId,
    this.deadline,
    this.deadlineId,
    this.priority,
    this.estimatedTime,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });


  factory Task.fromJson(Map<String, dynamic> json) {
    // Standardize status: favor 'status' column, fallback to 'is_completed' if it exists
    String standardizedStatus = 'pending';
    if (json['status'] != null) {
      standardizedStatus = json['status'].toString();
    } else if (json['is_completed'] == true) {
      standardizedStatus = 'completed';
    }

    return Task(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? 'Untitled Task',
      course: json['course'],
        courseId: json['course_id']?.toString(),
        semesterId: json['semester_id']?.toString(),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'])
          : null,
      priority: json['priority'],
      estimatedTime: json['estimated_time'],
      status: standardizedStatus,
      deadlineId: json['deadline_id']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at']) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at']) ?? DateTime.now())
          : null,
    );

  }

  bool get isCompleted => status == 'completed';

  /// Completion timestamp when status is completed (uses [updatedAt]).
  DateTime? get completedAt => isCompleted ? updatedAt : null;

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? course,
    String? courseId,
    String? semesterId,
    DateTime? deadline,
    String? deadlineId,
    bool clearDeadlineId = false,
    String? priority,
    int? estimatedTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {

    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      course: course ?? this.course,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      deadline: deadline ?? this.deadline,
      deadlineId: clearDeadlineId ? null : (deadlineId ?? this.deadlineId),
      priority: priority ?? this.priority,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      if (course != null) 'course': course,
      if (courseId != null) 'course_id': courseId,
      if (semesterId != null) 'semester_id': semesterId,
      if (deadline != null) 'deadline': deadline?.toIso8601String(),
      if (deadlineId != null) 'deadline_id': deadlineId,
      if (priority != null) 'priority': priority,
      if (estimatedTime != null) 'estimated_time': estimatedTime,
      if (notes != null) 'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };

  }
}
