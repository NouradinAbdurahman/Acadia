import 'package:acadia/models/course.dart';

class StudySession {
  final String id;
  final String userId;
  final String courseId;
  final String sessionType;
  final int durationMinutes;
  final DateTime createdAt;
  final Course? course; // For join result

  StudySession({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.sessionType,
    required this.durationMinutes,
    required this.createdAt,
    this.course,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      sessionType: json['session_type'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      course: json['courses'] != null ? Course.fromJson(json['courses']) : null,
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
    };
  }
}
