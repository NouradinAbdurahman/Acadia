import 'package:flutter/material.dart';

class Course {
  final String id;
  final String userId;
  final String courseName;
  final String? courseCode;
  final int academicSemester;
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
    required this.academicSemester,
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
        academicSemester: (json['semester'] as num?)?.toInt() ??
          int.tryParse(json['semester']?.toString() ?? '') ??
          1,
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
      'semester': academicSemester,
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
    int? academicSemester,
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
      academicSemester: academicSemester ?? this.academicSemester,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      ects: ects ?? this.ects,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @Deprecated('Use academicSemester')
  int get semester => academicSemester;

  Color get uiColor {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
