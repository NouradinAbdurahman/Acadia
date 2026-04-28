import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import 'semester_provider.dart';
import '../models/semester_comparison.dart';
import '../models/semester.dart';

/// Provider for comparing current selected semester with previous semester performance.
final semesterComparisonProvider = FutureProvider<SemesterComparison?>((ref) async {
  final userAsync = await ref.watch(currentAppUserProvider.future);
  if (userAsync == null) return null;

  final activeId = ref.watch(activeSemesterProvider).value;
  final semestersAsync = ref.watch(semesterProvider);
  final analyticsRepo = ref.watch(analyticsRepositoryProvider);

  return semestersAsync.when(
    data: (semesters) async {
      if (semesters.isEmpty || activeId == null) return null;

      // Sort by start_date or created_at descending
      final sorted = List<Semester>.from(semesters)..sort((a, b) {
        final dateA = a.startDate ?? a.createdAt;
        final dateB = b.startDate ?? b.createdAt;
        return dateB.compareTo(dateA); 
      });

      final currentIndex = sorted.indexWhere((s) => s.id == activeId);
      if (currentIndex == -1) return null;

      // Fetch analytics for current selected semester (now includes risk snapshot)
      final currentData = await analyticsRepo.getAnalyticsData(
        userAsync.id,
        semesterId: activeId,
      );

      // Find previous semester (the one before in sorted list)
      Semester? prev;
      if (currentIndex + 1 < sorted.length) {
        prev = sorted[currentIndex + 1];
      }

      if (prev == null) {
        return SemesterComparison(
          current: currentData,
          currentRiskScore: currentData.riskScore,
        );
      }

      // Fetch analytics for previous semester
      final prevData = await analyticsRepo.getAnalyticsData(
        userAsync.id,
        semesterId: prev.id,
      );

      return SemesterComparison(
        current: currentData,
        previous: prevData,
        previousSemesterName: prev.name,
        currentRiskScore: currentData.riskScore,
        previousRiskScore: prevData.riskScore,
      );
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});
