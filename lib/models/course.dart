import 'package:flutter/material.dart';

class Course {
  final String id;
  final String userId;
  final String courseName;
  final String? courseCode;
  final int? semester;
  final String? semesterId;
  final int credits;
  final String? color;
  final bool isActive;
  final int ects;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.userId,
    required this.courseName,
    this.courseCode,
    this.semester,
    this.semesterId,
    required this.credits,
    this.color,
    this.isActive = true,
    required this.ects,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      userId: json['user_id'],
      courseName: json['course_name'],
      courseCode: json['course_code'],
      semester: json['semester'],
      semesterId: json['semester_id'],
      credits: json['credits'] ?? 0,
      color: json['color'],
      ects: json['ects'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'user_id': userId,
      'course_name': courseName,
      'course_code': courseCode,
      'semester': semester,
      'semester_id': semesterId,
      'credits': credits,
      'color': color,
      'ects': ects,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  Course copyWith({
    String? id,
    String? userId,
    String? courseName,
    String? courseCode,
    String? semesterId,
    int? semester,
    int? credits,
    String? color,
    int? ects,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Course(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      semesterId: semesterId ?? this.semesterId,
      semester: semester ?? this.semester,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      ects: ects ?? this.ects,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color get uiColor {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
