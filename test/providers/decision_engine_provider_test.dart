import 'package:acadia/models/course.dart';
import 'package:acadia/models/deadline.dart';
import 'package:acadia/models/study_session.dart';
import 'package:acadia/models/task.dart';
import 'package:acadia/models/trend_data.dart';
import 'package:acadia/providers/analytics_provider.dart';
import 'package:acadia/providers/decision_engine_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  Course courseA() => Course(
    id: 'c1',
    userId: 'u1',
    courseName: 'Data Structures',
    academicSemester: 3,
    credits: 4,
    ects: 6,
    createdAt: now,
  );

  Course courseB() => Course(
    id: 'c2',
    userId: 'u1',
    courseName: 'Cybersecurity',
    academicSemester: 3,
    credits: 5,
    ects: 7,
    createdAt: now,
  );

  StudyAnalytics stableAnalytics() =>
      StudyAnalytics(const <StudySession>[], 900);

  group('Decision engine V1 cases', () {
    test('Case 1: deadline in 2 days picks correct course with 90 min', () {
      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: [
          Deadline(
            id: 'd1',
            userId: 'u1',
            title: 'DS Exam',
            course: 'Data Structures',
            courseId: 'c1',
            deadlineDate: startOfToday.add(const Duration(days: 2)),
            deadlineType: 'exam',
            priority: 'high',
            createdAt: now,
          ),
        ],
        studyHoursByCourse: const {'c1': 0.5, 'c2': 3.0},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c1');
      expect(snapshot.nextAction.durationMinutes, 90);
    });

    test('Case 2: no deadlines picks least studied course', () {
      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: const <Deadline>[],
        studyHoursByCourse: const {'c1': 2.0, 'c2': 0.2},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c2');
      expect(snapshot.nextAction.durationMinutes, 60);
    });

    test('Case 3: overdue exists overrides everything', () {
      final overdueTask = Task(
        id: 't1',
        userId: 'u1',
        title: 'Overdue task',
        courseId: 'c2',
        deadline: startOfToday.subtract(const Duration(days: 1)),
        status: 'pending',
        createdAt: now,
      );

      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA(), courseB()],
        tasks: [overdueTask],
        deadlines: [
          Deadline(
            id: 'd2',
            userId: 'u1',
            title: 'Upcoming',
            course: 'Data Structures',
            courseId: 'c1',
            deadlineDate: startOfToday.add(const Duration(days: 1)),
            deadlineType: 'quiz',
            priority: 'high',
            createdAt: now,
          ),
        ],
        studyHoursByCourse: const {'c1': 0.1, 'c2': 0.1},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c2');
      expect(
        snapshot.nextAction.reason,
        startsWith('Overdue tasks need immediate attention'),
      );
      expect(snapshot.nextAction.durationMinutes, 90);
    });

    test('Case 4: burnout high reduces duration', () {
      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: [
          Deadline(
            id: 'd3',
            userId: 'u1',
            title: 'DS Deadline',
            course: 'Data Structures',
            courseId: 'c1',
            deadlineDate: startOfToday.add(const Duration(days: 1)),
            deadlineType: 'exam',
            priority: 'high',
            createdAt: now,
          ),
        ],
        studyHoursByCourse: const {'c1': 0.2, 'c2': 0.2},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.highRisk,
      );

      expect(snapshot.nextAction.durationMinutes, 60);
      expect(snapshot.nextAction.durationMinutes >= 45, isTrue);
    });

    test('Case B: one course only still recommends that course', () {
      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA()],
        tasks: const <Task>[],
        deadlines: const <Deadline>[],
        studyHoursByCourse: const {'c1': 4.0},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c1');
    });

    test('Case C: all courses heavily studied still picks lowest studied', () {
      final snapshot = buildDecisionSnapshotV1(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: const <Deadline>[],
        studyHoursByCourse: const {'c1': 8.0, 'c2': 7.5},
        trendData: const TrendData.empty(),
        studyAnalytics: stableAnalytics(),
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c2');
    });
  });
}
