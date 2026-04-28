class DecisionRules {
  const DecisionRules._();

  static int getRecommendedSessionLength(double stress) {
    if (stress >= 7) return 35;
    return 45;
  }

  static bool isHighStress(double avgStress) => avgStress >= 7;

  static bool isMediumStress(double avgStress) => avgStress >= 5 && avgStress < 7;

  static bool isLowStress(double avgStress) => avgStress < 5;

  static bool lowMood(double avgMood) => avgMood > 0 && avgMood < 2.5;

  static bool highMood(double avgMood) => avgMood > 4;
}
