class AdaptiveProfile {
  final double completionRate;
  final double avgCompletionRatio;
  final int avgActualMinutes;
  final double consistency;

  const AdaptiveProfile({
    required this.completionRate,
    required this.avgCompletionRatio,
    required this.avgActualMinutes,
    required this.consistency,
  });

  const AdaptiveProfile.defaults()
      : completionRate = 1.0,
        avgCompletionRatio = 1.0,
        avgActualMinutes = 30,
        consistency = 1.0;
}
