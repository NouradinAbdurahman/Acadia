import 'package:flutter_test/flutter_test.dart';
import 'package:acadia/domain/risk/risk_input.dart';
import 'package:acadia/domain/risk/risk_calculator.dart';

void main() {
  group('RiskCalculator Edge Cases', () {
    test('1. No tasks, no study, normal ECTS (High deficit, high risk)', () {
      final input = RiskInput(
        totalECTS: 30, // 60 points from ECTS
        overdueTasks: 0,
        upcomingTasks: 0,
        studyHours: 0.0,
        studyGoal: 45.0,
      );

      final result = RiskCalculator.calculate(input);

      // Score = 15 (ECTS) + 15 (Study Deficit) = 30.0 -> Low Risk
      expect(result.totalScore, 30.0);
      expect(result.riskLevel, 'low');
    });

    test('2. High overdue tasks (Capped at 3 tasks)', () {
      final input = RiskInput(
        totalECTS: 30, // 15 points
        overdueTasks: 10, // 45 points (min(10,3)*15)
        upcomingTasks: 0,
        studyHours: 45.0,
        studyGoal: 45.0,
      );

      final result = RiskCalculator.calculate(input);

      // Score = 15 + 45 = 60.0 -> Medium Risk (Boundary)
      expect(result.totalScore, 60.0);
      expect(result.riskLevel, 'medium');
    });

    test('3. High ECTS, Good study, No tasks (Low Risk)', () {
      final input = RiskInput(
        totalECTS: 30, // 15 points
        overdueTasks: 0,
        upcomingTasks: 0,
        studyHours: 50.0,
        studyGoal: 45.0,
      );

      final result = RiskCalculator.calculate(input);

      // Score = 0 + 0 + 15 + 0 = 15 -> Low Risk
      expect(result.totalScore, 15.0);
      expect(result.riskLevel, 'low');
    });

    test('4. No ECTS, No tasks (Low Risk / Zero state)', () {
      final input = RiskInput(
        totalECTS: 0,
        overdueTasks: 0,
        upcomingTasks: 0,
        studyHours: 0.0,
        studyGoal: 0.0,
      );

      final result = RiskCalculator.calculate(input);

      // Score = 0 + 0 + 0 + 0 = 0 -> Low Risk
      expect(result.totalScore, 0.0);
      expect(result.riskLevel, 'low');
    });

    test('Partial deficit calculation', () {
      final input = RiskInput(
        totalECTS: 30, // 15 points
        overdueTasks: 0,
        upcomingTasks: 0,
        studyHours: 22.5,
        studyGoal: 45.0,
      );

      final result = RiskCalculator.calculate(input);

      // Score = 15 (ECTS) + 7.5 (Deficit: 50% of 15) = 22.5
      expect(result.totalScore, 22.5);
    });
  });
}
