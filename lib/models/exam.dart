enum ExamType {
  midterm('midterm'),
  finalExam('final'),
  quiz('quiz');

  const ExamType(this.dbValue);
  final String dbValue;

  static ExamType fromDb(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'final':
        return ExamType.finalExam;
      case 'quiz':
        return ExamType.quiz;
      case 'midterm':
      default:
        return ExamType.midterm;
    }
  }
}

String _toOffsetIsoString(DateTime value) {
  final local = value.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hh = offset.inHours.abs().toString().padLeft(2, '0');
  final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${local.toIso8601String()}$sign$hh:$mm';
}

class ExamModel {
  final String id;
  final String userId;
  final String? semesterId;
  final String title;
  final String? courseId;
  final String? courseName;
  final DateTime examDateTime;
  final String? classroom;
  final bool isOnline;
  final String? instructorName;
  final String type; // midterm | final | quiz
  final String? notes;
  final DateTime createdAt;

  ExamModel({
    required this.id,
    required this.userId,
    this.semesterId,
    required this.title,
    this.courseId,
    this.courseName,
    required this.examDateTime,
    this.classroom,
    required this.isOnline,
    this.instructorName,
    required this.type,
    this.notes,
    required this.createdAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final joinedCourse = json['courses'] as Map<String, dynamic>?;
    final rawCreatedAt =
        json['created_at'] as String? ??
        json['exam_datetime'] as String? ??
        json['exam_date'] as String?;
    return ExamModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      semesterId: json['semester_id'] as String?,
      title: (json['title'] as String?) ?? (json['course'] as String? ?? 'Exam'),
      courseId: json['course_id'] as String?,
      courseName:
          joinedCourse?['course_name'] as String? ??
          json['course'] as String?,
      examDateTime: DateTime.parse(
        (json['exam_datetime'] as String?) ?? (json['exam_date'] as String),
      ).toLocal(),
      classroom: json['classroom'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      instructorName: json['instructor_name'] as String?,
      type: ExamType.fromDb(json['type'] as String?).dbValue,
      notes: json['notes'] as String?,
      createdAt:
          rawCreatedAt == null ? DateTime.now() : DateTime.parse(rawCreatedAt).toLocal(),
    );
  }

  static String serializeExamDateTime(DateTime value) {
    return _toOffsetIsoString(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (semesterId != null) 'semester_id': semesterId,
      'title': title,
      if (courseId != null) 'course_id': courseId,
      'exam_datetime': serializeExamDateTime(examDateTime),
      if (classroom != null) 'classroom': classroom,
      'is_online': isOnline,
      if (instructorName != null) 'instructor_name': instructorName,
      'type': type,
      if (notes != null) 'notes': notes,
    };
  }

  ExamModel copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? title,
    String? courseId,
    String? courseName,
    DateTime? examDateTime,
    String? classroom,
    bool? isOnline,
    String? instructorName,
    String? type,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      examDateTime: examDateTime ?? this.examDateTime,
      classroom: classroom ?? this.classroom,
      isOnline: isOnline ?? this.isOnline,
      instructorName: instructorName ?? this.instructorName,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  ExamType get typeEnum => ExamType.fromDb(type);
}
