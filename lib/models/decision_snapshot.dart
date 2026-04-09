enum DecisionConfidence {
  high,
  medium,
  low,
}

class DecisionNextAction {
  final String courseId;
  final String courseName;
  final int durationMinutes;
  final String reason;
  final DecisionConfidence confidence;
  final String? higherPriorityThanCourseName;

  const DecisionNextAction({
    required this.courseId,
    required this.courseName,
    required this.durationMinutes,
    required this.reason,
    this.confidence = DecisionConfidence.medium,
    this.higherPriorityThanCourseName,
  });
}

class DecisionFocusRecommendation {
  final String courseId;
  final String courseName;
  final String reason;

  const DecisionFocusRecommendation({
    required this.courseId,
    required this.courseName,
    required this.reason,
  });
}

class DecisionWhatChanged {
  final String study;
  final String taskLoad;
  final String performance;

  const DecisionWhatChanged({
    required this.study,
    required this.taskLoad,
    required this.performance,
  });
}

class DecisionSnapshot {
  final DecisionNextAction nextAction;
  final DecisionFocusRecommendation? focusRecommendation;
  final DecisionFocusRecommendation? todayPlanSecondaryRecommendation;
  final DecisionWhatChanged whatChanged;

  const DecisionSnapshot({
    required this.nextAction,
    required this.focusRecommendation,
    this.todayPlanSecondaryRecommendation,
    required this.whatChanged,
  });
}
