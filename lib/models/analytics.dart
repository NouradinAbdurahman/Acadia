class AnalyticsModel {
  final String id;
  final String userId;
  final int? performanceScore;
  final int? workloadDensity;
  final int? burnoutRisk;
  final DateTime? weekStart;

  AnalyticsModel({
    required this.id,
    required this.userId,
    this.performanceScore,
    this.workloadDensity,
    this.burnoutRisk,
    this.weekStart,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      id: json['id'],
      userId: json['user_id'],
      performanceScore: json['performance_score'],
      workloadDensity: json['workload_density'],
      burnoutRisk: json['burnout_risk'],
      weekStart: json['week_start'] != null ? DateTime.parse(json['week_start']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (performanceScore != null) 'performance_score': performanceScore,
      if (workloadDensity != null) 'workload_density': workloadDensity,
      if (burnoutRisk != null) 'burnout_risk': burnoutRisk,
      if (weekStart != null) 'week_start': weekStart?.toIso8601String(),
    };
  }
}
