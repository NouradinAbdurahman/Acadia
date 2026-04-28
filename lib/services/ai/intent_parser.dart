import '../../models/ai_intent.dart';

class AiIntentParser {
  AiIntent parse(String message) {
    final lower = message.toLowerCase();
    
    // 1. Identify Intent Type
    AiIntentType type = AiIntentType.unknown;
    
    if (_matches(lower, [r'\btask', r'\btodo', r'\bwork', r'\bassignment', r'\bdo\b'])) {
      if (_matches(lower, [r'completed', r'done', r'finished', r'already did'])) {
        type = AiIntentType.getCompletedTasks;
      } else {
        type = AiIntentType.getTasksByTimeRange;
      }
    } else if (_matches(lower, [r'deadline', r'due', r'upcoming', r'when is'])) {
      type = AiIntentType.getUpcomingDeadlines;
    } else if (_matches(lower, [r'summary', r'recap', r'how am i doing', r'dashboard'])) {
      type = AiIntentType.getStudySummary;
    } else if (_matches(lower, [r'progress', r'stats', r'grades', r'results', r'performance'])) {
      type = AiIntentType.getProgress;
    } else if (_matches(lower, [r'risk', r'fail', r'struggling', r'warning', r'danger'])) {
      type = AiIntentType.getRiskStatus;
    }

    // 2. Identify Time Range
    TimeRange? timeRange;
    if (_matches(lower, [r'\btoday', r'tonight', r'\bnow\b'])) {
      timeRange = TimeRange.today;
    } else if (_matches(lower, [r'this week', r'upcoming week', r'next 7 days'])) {
      timeRange = TimeRange.thisWeek;
    } else if (_matches(lower, [r'last week', r'past week', r'previous week'])) {
      timeRange = TimeRange.lastWeek;
    } else if (_matches(lower, [r'last 2 weeks', r'past 2 weeks', r'last two weeks'])) {
      timeRange = TimeRange.lastTwoWeeks;
    }

    // 3. Identify Course
    String? course;
    final courseMatch = RegExp(r'(?:for|in|about)\s+([a-z\d\s]+)$').firstMatch(lower);
    if (courseMatch != null) {
      course = courseMatch.group(1)?.trim();
    }

    return AiIntent(
      type: type,
      filter: AiFilter(
        timeRange: timeRange,
        isCompleted: type == AiIntentType.getCompletedTasks,
        course: course,
      ),
      originalMessage: message,
    );
  }

  bool _matches(String text, List<String> patterns) {
    return patterns.any((p) => RegExp(p).hasMatch(text));
  }
}
