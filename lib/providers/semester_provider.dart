import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../repositories/semester_repository.dart';
import '../services/supabase/semester_state_service.dart';
import 'app_providers.dart';
 
final semesterStateServiceProvider = Provider((ref) => SemesterStateService());
final isSemesterSwitchingProvider = StateProvider<bool>((ref) => false);

final semesterProvider =
    StateNotifierProvider<SemesterNotifier, AsyncValue<List<Semester>>>((ref) {
  // Ensure the provider resets when the user changes
  ref.watch(currentUserProvider);
  return SemesterNotifier(ref.watch(semesterRepositoryProvider), ref);
});

List<Semester> orderSemestersForDisplay(
  List<Semester> semesters, {
  String? activeSemesterId,
}) {
  final sorted = List<Semester>.from(semesters)
    ..sort((a, b) {
      final aDate = a.startDate ?? a.createdAt;
      final bDate = b.startDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

  if (activeSemesterId == null) return sorted;

  final activeIndex = sorted.indexWhere((s) => s.id == activeSemesterId);
  if (activeIndex <= 0) return sorted;

  final active = sorted.removeAt(activeIndex);
  sorted.insert(0, active);
  return sorted;
}

final orderedSemestersProvider = Provider<AsyncValue<List<Semester>>>((ref) {
  final semestersAsync = ref.watch(semesterProvider);
  final activeIdAsync = ref.watch(activeSemesterProvider);

  return semestersAsync.when(
    data: (semesters) => activeIdAsync.when(
      data: (id) => AsyncValue.data(orderSemestersForDisplay(
        semesters,
        activeSemesterId: id,
      )),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class SemesterNotifier extends StateNotifier<AsyncValue<List<Semester>>> {
  final SemesterRepository _repository;

  SemesterNotifier(this._repository, Ref _) : super(const AsyncValue.loading()) {
    loadSemesters();
  }

  Future<void> loadSemesters() async {
    state = const AsyncValue<List<Semester>>.loading().copyWithPrevious(state);
    try {
      final semesters = await _repository.getSemesters();
      if (!mounted) return;
      state = AsyncValue.data(semesters);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<Semester?> addSemester(Semester semester) async {
    try {
      final created = await _repository.createSemester(semester);
      await loadSemesters();
      return created;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateSemester(Semester semester) async {
    try {
      await _repository.updateSemester(semester);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteSemester(String id) async {
    try {
      await _repository.deleteSemester(id);
      await loadSemesters();
    } catch (e) {
      // Handle error
    }
  }
}

final activeSemesterProvider = AsyncNotifierProvider<ActiveSemesterNotifier, String?>(() {
  return ActiveSemesterNotifier();
});

class ActiveSemesterNotifier extends AsyncNotifier<String?> {
  SemesterStateService get _service => ref.read(semesterStateServiceProvider);

  /// Survives provider rebuilds (auth token refresh, dependency changes).
  /// Set ONLY by explicit user action in [setActiveSemester].
  /// Cleared on logout (user == null).
  static String? _explicitSelection;

  @override
  FutureOr<String?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      _explicitSelection = null;
      return null;
    }

    if (_explicitSelection != null) {
      debugPrint(
        '[ActiveSemester] build() → returning explicit selection: $_explicitSelection',
      );
      return _explicitSelection;
    }

    final fetched = await _service.getActiveSemesterId();
    debugPrint('[ActiveSemester] build() → initial load from DB: $fetched');
    return fetched;
  }

  Future<void> setActiveSemester(String semesterId) async {
    if (ref.read(isSemesterSwitchingProvider)) return;
    if (state.valueOrNull == semesterId) return;

    final semesters = ref.read(semesterProvider).value ?? const <Semester>[];
    if (semesters.isNotEmpty && !semesters.any((s) => s.id == semesterId)) {
      return;
    }

    ref.read(isSemesterSwitchingProvider.notifier).state = true;
    try {
      debugPrint('[ActiveSemester] SET → $semesterId (user action)');
      final success = await _service.updateActiveSemester(semesterId);
      if (!success) {
        debugPrint('[ActiveSemester] DB write failed for $semesterId');
        return;
      }
      _explicitSelection = semesterId;
      state = AsyncValue.data(semesterId);
    } finally {
      ref.read(isSemesterSwitchingProvider.notifier).state = false;
    }
  }
}

final activeSemesterFullProvider = Provider<AsyncValue<Semester?>>((ref) {
  final activeIdAsync = ref.watch(activeSemesterProvider);
  final semestersAsync = ref.watch(semesterProvider);

  return activeIdAsync.when(
    data: (id) {
      if (id == null) return const AsyncValue.data(null);
      return semestersAsync.when(
        data: (list) {
          try {
            return AsyncValue.data(list.firstWhere((s) => s.id == id));
          } catch (_) {
            return const AsyncValue.data(null);
          }
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
