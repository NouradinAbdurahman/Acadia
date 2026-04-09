import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import 'semester_provider.dart';
import '../models/performance_summary.dart';
import '../models/semester.dart';

/// Provider for summarizing lifetime academic performance across all semesters.
final performanceSummaryProvider = FutureProvider<PerformanceSummary?>((ref) async {
  final userAsync = await ref.watch(currentAppUserProvider.future);
  if (userAsync == null) return null;

  final semestersAsync = ref.watch(semesterProvider);
  final analyticsRepo = ref.watch(analyticsRepositoryProvider);

  return semestersAsync.when(
    data: (semesters) async {
      if (semesters.isEmpty) return null;

      // Ensure historical sorting (Cronological order)
      final sortedSemesters = List<Semester>.from(semesters)..sort((a, b) {
        final dateA = a.startDate ?? a.createdAt;
        final dateB = b.startDate ?? b.createdAt;
        return dateA.compareTo(dateB);
      });

      final history = <SemesterPerformance>[];
      
      // Fetch analytics for ALL semesters
      for (final s in sortedSemesters) {
        final data = await analyticsRepo.getAnalyticsData(userAsync.id, semesterId: s.id);
        history.add(SemesterPerformance(semester: s, data: data));
      }

      if (history.isEmpty) return null;

      // Identify performance tiers
      SemesterPerformance? best;
      double maxGPA = -1;
      
      SemesterPerformance? worst;
      double minGPA = 5.0; // Assume 4.0 or 5.0 scale

      SemesterPerformance? mostImproved;
      double maxDelta = -10.0;

      for (int i = 0; i < history.length; i++) {
        final current = history[i];
        final gpa = current.data.averageGPA;
        
        // Skip N/A (0.0) GPAs for trend analysis
        if (gpa > 0) {
          if (gpa > maxGPA) {
            maxGPA = gpa;
            best = current;
          }
          if (gpa < minGPA) {
            minGPA = gpa;
            worst = current;
          }
        }

        // Improvement calculation (at least 2 semesters needed)
        if (i > 0) {
          final prev = history[i - 1];
          if (prev.data.averageGPA > 0 && current.data.averageGPA > 0) {
            final delta = current.data.averageGPA - prev.data.averageGPA;
            if (delta > maxDelta) {
              maxDelta = delta;
              mostImproved = current;
            }
          }
        }
      }

      return PerformanceSummary(
        bestSemester: best?.semester,
        highestGpa: maxGPA > 0 ? maxGPA : null,
        worstSemester: worst?.semester,
        lowestGpa: minGPA < 5.0 ? minGPA : null,
        mostImprovedSemester: mostImproved?.semester,
        improvementDelta: maxDelta > 0 ? maxDelta : null,
        history: history,
      );
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});
