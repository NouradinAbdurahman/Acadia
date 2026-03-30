class ExamModel {
  final String id;
  final String userId;
  final String? course;
  final DateTime? examDate;
  final int? weight;

  ExamModel({
    required this.id,
    required this.userId,
    this.course,
    this.examDate,
    this.weight,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'],
      userId: json['user_id'],
      course: json['course'],
      examDate: json['exam_date'] != null ? DateTime.parse(json['exam_date']) : null,
      weight: json['weight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (course != null) 'course': course,
      if (examDate != null) 'exam_date': examDate?.toIso8601String(),
      if (weight != null) 'weight': weight,
    };
  }
}
