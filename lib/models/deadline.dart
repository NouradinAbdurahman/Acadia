class Deadline {
  final String id;
  final String userId;
  final String title;
  final String course;
  final String? courseId;
  final DateTime deadlineDate;
  final String deadlineType;
  final String priority;
  final String? notes;
  final DateTime createdAt;

  Deadline({
    required this.id,
    required this.userId,
    required this.title,
    required this.course,
    this.courseId,
    required this.deadlineDate,
    required this.deadlineType,
    required this.priority,
    this.notes,
    required this.createdAt,
  });

  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      course: json['course'] as String,
      courseId: json['course_id'] as String?,
      deadlineDate: DateTime.parse(json['deadline_date'] as String),
      deadlineType: json['deadline_type'] as String,
      priority: json['priority'] as String,
      notes: json['notes'] as String?,
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
      'deadline_date': deadlineDate.toIso8601String(),
      'deadline_type': deadlineType,
      'priority': priority,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

