class DecisionRules {
  const DecisionRules._();

  static int suggestedSessionMinutes(double avgStress) {
    if (avgStress >= 7) return 25;
    if (avgStress >= 5) return 35;
    return 45;
  }

  static bool highStress(double avgStress) => avgStress > 7;

  static bool mediumStress(double avgStress) => avgStress >= 4 && avgStress <= 7;

  static bool lowStress(double avgStress) => avgStress < 4;

  static bool lowMood(double avgMood) => avgMood > 0 && avgMood < 2.5;

  static bool highMood(double avgMood) => avgMood > 4;
}
