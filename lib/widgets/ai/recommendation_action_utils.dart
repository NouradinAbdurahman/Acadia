import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/bottom_nav_provider.dart';
import 'passive_ai_constants.dart';

/// Deterministic keyword routing — no ML. Mirrors recommendation wording from [AcademicInsightInput].
enum RecommendationActionKind {
  startStudySession,
  addTask,
  viewTasksDeadlines,
  openAnalytics,
}

RecommendationActionKind? inferRecommendationActionKind({
  required String recommendation,
  required String insight,
  int overdueTasks = 0,
  double studyDeficitHours = 0,
  double consistency01 = 1.0,
}) {
  final t = '${recommendation.toLowerCase()} ${insight.toLowerCase()}';

  final bool wantsSessions = RegExp(
    r'session|study block|study time|log study|focused session|blocks today|calendar blocks',
    caseSensitive: false,
  ).hasMatch(t);

  final bool wantsAddTask = RegExp(
    r'add (a )?task|new task|create (a )?task|undated tasks',
    caseSensitive: false,
  ).hasMatch(t);

  final bool wantsDeadlines = RegExp(
    r'deadline|due soon|due date|parallel deadlines|upcoming',
    caseSensitive: false,
  ).hasMatch(t);

  final bool wantsAnalytics = RegExp(
    r'risk|gpa|analytics|semester average|deficit',
    caseSensitive: false,
  ).hasMatch(t);

  RecommendationActionKind? byKeywords() {
    if (wantsSessions) return RecommendationActionKind.startStudySession;
    if (wantsAddTask) return RecommendationActionKind.addTask;
    if (wantsDeadlines) return RecommendationActionKind.viewTasksDeadlines;
    if (wantsAnalytics) return RecommendationActionKind.openAnalytics;
    return null;
  }

  final keyword = byKeywords();

  if (overdueTasks > 0) {
    if (wantsSessions && !wantsDeadlines && !wantsAddTask) {
      return RecommendationActionKind.startStudySession;
    }
    if (wantsAddTask) return RecommendationActionKind.addTask;
    return RecommendationActionKind.viewTasksDeadlines;
  }

  if (studyDeficitHours >= kPassiveAiStudyDeficitHours) {
    if (consistency01 < kPassiveAiLowConsistency) {
      if (wantsAnalytics || wantsDeadlines) {
        return wantsDeadlines
            ? RecommendationActionKind.viewTasksDeadlines
            : RecommendationActionKind.openAnalytics;
      }
    }
    if (wantsDeadlines) return RecommendationActionKind.viewTasksDeadlines;
    if (wantsSessions) return RecommendationActionKind.startStudySession;
    return RecommendationActionKind.startStudySession;
  }

  if (consistency01 < kPassiveAiLowConsistency) {
    if (wantsSessions) return RecommendationActionKind.startStudySession;
    return RecommendationActionKind.openAnalytics;
  }

  return keyword;
}

void invokeRecommendationAction({
  required RecommendationActionKind kind,
  required BuildContext context,
  required WidgetRef ref,
}) {
  switch (kind) {
    case RecommendationActionKind.startStudySession:
      ref.read(bottomNavProvider.notifier).state = 2;
      context.go('/home');
      return;
    case RecommendationActionKind.addTask:
      context.push('/create-task');
      return;
    case RecommendationActionKind.viewTasksDeadlines:
      ref.read(bottomNavProvider.notifier).state = 1;
      context.go('/home');
      return;
    case RecommendationActionKind.openAnalytics:
      ref.read(bottomNavProvider.notifier).state = 3;
      context.go('/home');
      return;
  }
}
