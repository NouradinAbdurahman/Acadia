import 'dart:math' as math;

import '../adaptive/adaptive_profile.dart';

class DecisionRules {
  const DecisionRules._();

  static int getRecommendedSessionMinutes({
    required double consistency,
    required double avgStress,
  }) {
    if (consistency < 0.5) return 30;
    if (avgStress >= 6) return 25;
    return 45;
  }

  static int getRecommendedSessionLength(double stress) {
    return getRecommendedSessionMinutes(consistency: 1.0, avgStress: stress);
  }

  static int getAdaptiveMinutes({
    required double consistency,
    required double stress,
    required AdaptiveProfile profile,
    double burnoutRisk = 0,
  }) {
    int base = getRecommendedSessionMinutes(
      consistency: consistency,
      avgStress: stress,
    );
    if (profile.avgCompletionRatio < 0.75) {
      base = profile.avgActualMinutes.clamp(10, base);
      base = (base * 0.9).round();
    }
    if (profile.completionRate < 0.6) {
      base = (base * 0.75).round();
    }
    if (profile.completionRate > 0.85 && profile.avgCompletionRatio > 0.9) {
      base = (base * 1.2).round();
      base += 4;
    }
    if (burnoutRisk > 50) {
      base -= burnoutRisk >= 65 ? 10 : 5;
    }
    base = base.clamp(10, 45);
    if (burnoutRisk > 50) {
      final burnoutCeiling = burnoutRisk >= 65 ? 30 : 35;
      return math.min(base, burnoutCeiling);
    }
    return base;
  }

  static int getFinalRecommendedMinutes({
    required double consistency,
    required double stress,
    required AdaptiveProfile profile,
    required double? burnoutRisk,
  }) {
    if (burnoutRisk == null) {
      throw Exception('Burnout must not be null at decision stage');
    }
    if (burnoutRisk.isNaN) {
      throw Exception('Burnout must be a valid number at decision stage');
    }
    return getAdaptiveMinutes(
      consistency: consistency,
      stress: stress,
      profile: profile,
      burnoutRisk: burnoutRisk,
    );
  }

  static int getRecommendedDailySessions(double studyDeficitHours) {
    if (studyDeficitHours >= 20) return 3;
    if (studyDeficitHours >= 8) return 2;
    return 1;
  }

  static bool isHighStress(double avgStress) => avgStress >= 7;

  static bool isMediumStress(double avgStress) => avgStress >= 5 && avgStress < 7;

  static bool isLowStress(double avgStress) => avgStress < 5;

  static bool lowMood(double avgMood) => avgMood > 0 && avgMood < 2.5;

  static bool highMood(double avgMood) => avgMood > 4;
}
