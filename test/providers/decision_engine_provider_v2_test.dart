import 'package:acadia/models/course.dart';
import 'package:acadia/models/deadline.dart';
import 'package:acadia/models/study_session.dart';
import 'package:acadia/models/task.dart';
import 'package:acadia/models/trend_data.dart';
import 'package:acadia/providers/analytics_provider.dart';
import 'package:acadia/providers/decision_engine_provider_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  Course courseA({int ects = 6}) => Course(
        id: 'c1',
        userId: 'u1',
        courseName: 'Machine Learning',
        academicSemester: 4,
        credits: 4,
        ects: ects,
        createdAt: now,
      );

  Course courseB({int ects = 6}) => Course(
        id: 'c2',
        userId: 'u1',
        courseName: 'Data Structures',
        academicSemester: 4,
        credits: 4,
        ects: ects,
        createdAt: now,
      );

  StudyAnalytics analytics() => StudyAnalytics(const <StudySession>[], 900);

  group('Decision engine V2 weighted scoring', () {
    test('Case 1: deadline urgency beats least-studied only', () {
      final snapshot = buildDecisionSnapshotV2(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: [
          Deadline(
            id: 'd1',
            userId: 'u1',
            title: 'ML exam',
            course: 'Machine Learning',
            courseId: 'c1',
            deadlineDate: startOfToday.add(const Duration(days: 1)),
            deadlineType: 'exam',
            priority: 'high',
            createdAt: now,
          ),
        ],
        studyHoursByCourse: const {
          'c1': 4.0,
          'c2': 0.2,
        },
        trendData: const TrendData.empty(),
        studyAnalytics: analytics(),
        analyticsRiskScore: 40,
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c1');
      expect(snapshot.nextAction.durationMinutes, 90);
    });

    test('Case 2: no deadlines, biggest deficit wins', () {
      final snapshot = buildDecisionSnapshotV2(
        courses: [courseA(), courseB()],
        tasks: const <Task>[],
        deadlines: const <Deadline>[],
        studyHoursByCourse: const {
          'c1': 0.1,
          'c2': 5.0,
        },
        trendData: const TrendData.empty(),
        studyAnalytics: analytics(),
        analyticsRiskScore: 20,
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c1');
    });

    test('Case 3: tie broken by higher ECTS', () {
      final snapshot = buildDecisionSnapshotV2(
        courses: [courseA(ects: 10), courseB(ects: 6)],
        tasks: const <Task>[],
        deadlines: const <Deadline>[],
        studyHoursByCourse: const {
          'c1': 2.0,
          'c2': 2.0,
        },
        trendData: const TrendData.empty(),
        studyAnalytics: analytics(),
        analyticsRiskScore: 20,
        burnoutLevelOverride: BurnoutLevel.stable,
      );

      expect(snapshot.nextAction.courseId, 'c1');
    });
  });
}
