class AcademicCalendarModel {
  final String id;
  final String userId;
  final int? semester;
  final DateTime semesterStart;
  final DateTime semesterEnd;
  final DateTime? examPeriodStart;
  final DateTime? examPeriodEnd;
  final DateTime createdAt;

  AcademicCalendarModel({
    required this.id,
    required this.userId,
    this.semester,
    required this.semesterStart,
    required this.semesterEnd,
    this.examPeriodStart,
    this.examPeriodEnd,
    required this.createdAt,
  });

  factory AcademicCalendarModel.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarModel(
      id: json['id'],
      userId: json['user_id'],
      semester: json['semester'],
      semesterStart: DateTime.parse(json['semester_start']),
      semesterEnd: DateTime.parse(json['semester_end']),
      examPeriodStart: json['exam_period_start'] != null 
          ? DateTime.parse(json['exam_period_start']) 
          : null,
      examPeriodEnd: json['exam_period_end'] != null 
          ? DateTime.parse(json['exam_period_end']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'semester': semester,
      'semester_start': semesterStart.toIso8601String().split('T')[0],
      'semester_end': semesterEnd.toIso8601String().split('T')[0],
      'exam_period_start': examPeriodStart?.toIso8601String().split('T')[0],
      'exam_period_end': examPeriodEnd?.toIso8601String().split('T')[0],
    };
  }
}
