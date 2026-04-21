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
  final activeSemesterId = ref.watch(activeSemesterProvider);

  return semestersAsync.whenData(
    (semesters) => orderSemestersForDisplay(
      semesters,
      activeSemesterId: activeSemesterId,
    ),
  );
});

class SemesterNotifier extends StateNotifier<AsyncValue<List<Semester>>> {
  final SemesterRepository _repository;

  SemesterNotifier(this._repository, Ref _) : super(const AsyncValue.loading()) {
    loadSemesters();
  }

  Future<void> loadSemesters() async {
    state = const AsyncValue.loading();
    try {
      final semesters = await _repository.getSemesters();
      if (!mounted) return;
      state = AsyncValue.data(semesters);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSemester(Semester semester) async {
    try {
      await _repository.createSemester(semester);
      await loadSemesters();
    } catch (e) {
      // Handle error
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

final activeSemesterProvider =
    StateNotifierProvider<ActiveSemesterNotifier, String?>((ref) {
  // Re-initialize this notifier if the user changes
  final user = ref.watch(currentUserProvider);

  final notifier = ActiveSemesterNotifier(
    ref.watch(semesterStateServiceProvider),
    ref,
  );

  ref.listen<AsyncValue<List<Semester>>>(semesterProvider, (_, next) {
    notifier.onSemesterListChanged(next.value ?? const <Semester>[]);
  });

  // Only attempt to initialize if a user is currently logged in
  if (user != null) {
    notifier.initialize();
  }
  
  return notifier;
});

class ActiveSemesterNotifier extends StateNotifier<String?> {
  final SemesterStateService _service;
  final Ref _ref;
  bool _initialized = false;
  bool _isInitializing = false;

  ActiveSemesterNotifier(this._service, this._ref) : super(null);

  Future<void> initialize() async {
    if (_initialized || _isInitializing) return;

    _isInitializing = true;
    try {
      final incomingActiveSemesterId = await _service.getActiveSemesterId();
      _applyIncomingActiveSemester(incomingActiveSemesterId);
      _initialized = true;
      await _ensureInitializedActiveSemester();
    } finally {
      _isInitializing = false;
    }
  }

  void _applyIncomingActiveSemester(String? incomingActiveSemesterId) {
    // Hard guard: never allow null to overwrite an existing active semester.
    if (incomingActiveSemesterId == null) {
      if (state == null) {
        // No active semester set yet, this is normal for new users.
      } else {
        debugPrint('ActiveSemester: Blocked null overwrite of existing state.');
      }
      return;
    }

    state = incomingActiveSemesterId;
  }

  Future<void> _ensureInitializedActiveSemester() async {
    if (state != null) return;

    final semesters = _ref.read(semesterProvider).value ?? const <Semester>[];
    if (semesters.isEmpty) {
      // Not an error if the user hasn't created any semesters yet.
      return;
    }

    await setActiveSemester(semesters.first.id);
  }

  void onSemesterListChanged(List<Semester> semesters) {
    if (!_initialized) return;

    if (state == null && semesters.isNotEmpty) {
      Future.microtask(() => _ensureInitializedActiveSemester());
      return;
    }

    final currentActiveSemesterId = state;
    if (currentActiveSemesterId == null || semesters.isEmpty) return;

    final exists = semesters.any((s) => s.id == currentActiveSemesterId);
    if (!exists) {
      Future.microtask(() => setActiveSemester(semesters.first.id));
    }
  }

  Future<void> setActiveSemester(String semesterId) async {
    if (_ref.read(isSemesterSwitchingProvider)) return;

    final semesters = _ref.read(semesterProvider).value ?? const <Semester>[];
    if (semesters.isNotEmpty && !semesters.any((s) => s.id == semesterId)) {
      return;
    }

    _ref.read(isSemesterSwitchingProvider.notifier).state = true;
    try {
      final success = await _service.updateActiveSemester(semesterId);
      if (success) {
        state = semesterId;
      }
    } finally {
      _ref.read(isSemesterSwitchingProvider.notifier).state = false;
    }
  }
}

final activeSemesterFullProvider = Provider<Semester?>((ref) {
  final activeId = ref.watch(activeSemesterProvider);
  if (activeId == null) return null;
  
  final semestersAsync = ref.watch(semesterProvider);
  return semestersAsync.when(
    data: (list) {
      try {
        return list.firstWhere((s) => s.id == activeId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (e, _) => null,
  );
});
