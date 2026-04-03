class CourseResult {
  CourseResult({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.semesterId,
    required this.letterGrade,
    this.resultStatus,
    this.finalAverage,
    required this.createdAt,
    required this.updatedAt,
    this.components = const [],
  });

  final String id;
  final String userId;
  final String courseId;
  final String semesterId;
  final double? finalAverage;
  final String letterGrade;
  final String? resultStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CourseResultComponent> components;

  factory CourseResult.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['course_result_components'] as List<dynamic>? ?? const [];
    return CourseResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      semesterId: json['semester_id'] as String,
      finalAverage: (json['final_average'] as num?)?.toDouble(),
      letterGrade: json['letter_grade'] as String,
      resultStatus: json['result_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      components: rawComponents
          .map(
            (item) =>
                CourseResultComponent.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'course_id': courseId,
      'semester_id': semesterId,
      'letter_grade': letterGrade,
      'result_status': resultStatus,
      'final_average': finalAverage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  CourseResult copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? semesterId,
    double? finalAverage,
    String? letterGrade,
    String? resultStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CourseResultComponent>? components,
  }) {
    return CourseResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      finalAverage: finalAverage ?? this.finalAverage,
      letterGrade: letterGrade ?? this.letterGrade,
      resultStatus: resultStatus ?? this.resultStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      components: components ?? this.components,
    );
  }
}

class CourseResultComponent {
  CourseResultComponent({
    required this.id,
    required this.resultId,
    required this.title,
    required this.score,
    required this.percentage,
  });

  final String id;
  final String resultId;
  final String title;
  final double score;
  final double percentage;

  factory CourseResultComponent.fromJson(Map<String, dynamic> json) {
    return CourseResultComponent(
      id: json['id'] as String,
      resultId: json['result_id'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'result_id': resultId,
      'title': title,
      'score': score,
      'percentage': percentage,
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  CourseResultComponent copyWith({
    String? id,
    String? resultId,
    String? title,
    double? score,
    double? percentage,
  }) {
    return CourseResultComponent(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      title: title ?? this.title,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
    );
  }
}
