import '../../models/study_session.dart';
import 'adaptive_profile.dart';

class AdaptiveEngine {
  static AdaptiveProfile build(
    List<StudySession> sessions, {
    required double consistency,
  }) {
    if (sessions.isEmpty) {
      return AdaptiveProfile.defaults();
    }

    final completionRate = sessions
            .where((s) {
              final planned = (s.plannedMinutes ?? s.durationMinutes);
              final actual = (s.actualMinutes ?? s.durationMinutes);
              if (!s.completed) return false;
              if (planned <= 0) return true;
              return (actual / planned) >= 0.7;
            })
            .length /
        sessions.length;

    final ratios = sessions.map((s) {
      final planned = (s.plannedMinutes ?? s.durationMinutes);
      final actual = (s.actualMinutes ?? s.durationMinutes);
      if (planned == 0) return 1.0;
      return actual / planned;
    }).toList();

    final avgRatio =
        ratios.isEmpty ? 1.0 : ratios.reduce((a, b) => a + b) / ratios.length;

    final avgActual = sessions.isEmpty
        ? 30
        : sessions
                .map((s) => s.actualMinutes ?? s.durationMinutes)
                .reduce((a, b) => a + b) ~/
            sessions.length;

    return AdaptiveProfile(
      completionRate: completionRate,
      avgCompletionRatio: avgRatio,
      avgActualMinutes: avgActual,
      consistency: consistency,
    );
  }
}
