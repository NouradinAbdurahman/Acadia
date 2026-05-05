import '../../models/ai_intent.dart';

class AiIntentParser {
  AiIntent parse(String message) {
    final lower = message.toLowerCase();

    // Must hit the Edge Function (not local risk/task parsers) so "send my risk to email" works.
    if (_wantsEmailDelivery(lower)) {
      return AiIntent(
        type: AiIntentType.unknown,
        filter: const AiFilter(),
        originalMessage: message,
      );
    }
    
    // 1. Identify Intent Type
    AiIntentType type = AiIntentType.unknown;
    
    bool? completionFilter;
    if (_matches(lower, [r'plan my week', r'weekly plan', r'plan this week'])) {
      type = AiIntentType.planWeek;
    } else if (_matches(lower, [
      r'plan today',
      r'plan_today',
      r'today plan',
      r'what should i study today',
    ])) {
      type = AiIntentType.planToday;
    } else if (_matches(lower, [
      r'focus now',
      r'focus_now',
      r'start focus',
      r'start session',
      r'study now',
    ])) {
      type = AiIntentType.focusNow;
    } else if (_matches(lower, [
      r'what should i do first',
      r'priority tasks',
      r'rank my tasks',
      r'most important tasks',
    ])) {
      type = AiIntentType.rankTasks;
    } else if (_matches(lower, [r'focus_now', r'focus now', r'\bsummary\b'])) {
      type = AiIntentType.getStudySummary;
    } else if (_matches(lower, [r'\btask', r'\btodo', r'\bwork', r'\bassignment', r'\bdo\b'])) {
      final wantsIncomplete = _matches(lower, [
        r'uncompleted',
        r'incomplete',
        r'not done',
        r'not completed',
        r'pending',
        r'open tasks?',
        r'unfinished',
      ]);
      final wantsCompleted = _matches(lower, [
        r'completed',
        r'\bcomplete\b',
        r'done',
        r'finished',
        r'already did',
      ]);

      if (wantsIncomplete) {
        type = AiIntentType.getTasksByTimeRange;
        completionFilter = false;
      } else if (wantsCompleted) {
        type = AiIntentType.getCompletedTasks;
        completionFilter = true;
      } else {
        type = AiIntentType.getTasksByTimeRange;
        completionFilter = null; // generic tasks query => include all
      }
    } else if (_matches(lower, [r'deadline', r'due', r'upcoming', r'when is'])) {
      type = AiIntentType.getUpcomingDeadlines;
    } else if (_matches(lower, [r'summary', r'recap', r'how am i doing', r'dashboard'])) {
      type = AiIntentType.getStudySummary;
    } else if (_matches(lower, [
      r'progress',
      r'stats',
      r'grade',
      r'grades',
      r'gpa',
      r'gba',
      r'cgpa',
      r'result',
      r'results',
      r'performance'
    ])) {
      type = AiIntentType.getProgress;
    } else if (_matches(lower, [r'risk', r'fail', r'struggling', r'warning', r'danger'])) {
      type = AiIntentType.getRiskStatus;
    }

    // 2. Identify Time Range
    TimeRange? timeRange;
    DateTime? startDate;
    DateTime? endDate;
    final explicitRange = _extractAbsoluteDateRange(lower);
    if (explicitRange != null) {
      startDate = explicitRange['start'];
      endDate = explicitRange['end'];
      timeRange = TimeRange.custom;
    }

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
      final candidate = courseMatch.group(1)?.trim();
      if (candidate != null && !_looksLikeDatePhrase(candidate)) {
        course = candidate;
      }
    }

    return AiIntent(
      type: type,
      filter: AiFilter(
        timeRange: timeRange,
        isCompleted: completionFilter,
        course: course,
        startDate: startDate,
        endDate: endDate,
      ),
      originalMessage: message,
    );
  }

  bool _matches(String text, List<String> patterns) {
    return patterns.any((p) => RegExp(p).hasMatch(text));
  }

  Map<String, DateTime>? _extractAbsoluteDateRange(String lower) {
    final monthMap = <String, int>{
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final monthRegex = RegExp(
      r'\b(?:in|for|during)?\s*(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\b(?:\s+(\d{4}))?',
    );
    final match = monthRegex.firstMatch(lower);
    if (match == null) return null;

    final monthToken = match.group(1);
    if (monthToken == null) return null;
    final month = monthMap[monthToken];
    if (month == null) return null;

    final now = DateTime.now();
    final parsedYear = int.tryParse(match.group(2) ?? '');
    final year = parsedYear ?? now.year;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    return {'start': start, 'end': end};
  }

  bool _looksLikeDatePhrase(String text) {
    return RegExp(
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec|today|week|month|year)\b',
    ).hasMatch(text);
  }

  /// User is asking to receive something by email (handled by acadia-ai + Resend).
  bool _wantsEmailDelivery(String lower) {
    if (RegExp(r'\bemail\s+me\b').hasMatch(lower)) return true;
    final targetsEmail = lower.contains('email') ||
        lower.contains('e-mail') ||
        lower.contains('inbox');
    if (targetsEmail &&
        RegExp(r'\b(send|forward|mail|deliver|shoot|push)\b').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\b(send|mail)\s+this\b').hasMatch(lower) ||
        RegExp(r'\bmail\s+this\b').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\bto\s+(my\s+)?(email|e-?mail|inbox)\b').hasMatch(lower) &&
        RegExp(r'\b(send|forward|mail|get)\b').hasMatch(lower)) {
      return true;
    }
    return false;
  }
}
