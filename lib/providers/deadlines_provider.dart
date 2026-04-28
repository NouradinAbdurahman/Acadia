import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/deadline.dart';
import 'app_providers.dart';
import 'semester_provider.dart';

import 'tasks_provider.dart';

class DeadlinesNotifier extends StateNotifier<AsyncValue<List<Deadline>>> {
  DeadlinesNotifier({
    required Ref ref,
    required this.deadlineRepository,
    required this.supabaseClient,
  })  : _ref = ref,
        super(const AsyncValue.loading());


  final Ref _ref;
  final dynamic deadlineRepository;
  final SupabaseClient supabaseClient;

  Future<void> loadDeadlines({required String userId, String? semesterId}) async {
    try {
      // Preserve previous data during refresh so UI doesn't blank/flicker.
      state = const AsyncValue<List<Deadline>>.loading().copyWithPrevious(state);
      final list = await deadlineRepository.getDeadlines(userId: userId, semesterId: semesterId) as List<Deadline>;
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    final semesterId = _ref.read(activeSemesterProvider).value;
    if (userId != null) {
      await loadDeadlines(userId: userId, semesterId: semesterId);
    }
  }

  Future<void> createDeadline(Deadline deadline) async {
    final semesterId = _ref.read(activeSemesterProvider).value;
    if (semesterId == null) {
      throw Exception('No active semester set. Cannot create deadline.');
    }

    final scopedDeadline = deadline.copyWith(semesterId: semesterId);
    final previous = state;
    try {
      final created =
          await deadlineRepository.createDeadline(scopedDeadline) as Deadline;
      state = state.whenData((items) => [created, ...items]);
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteDeadline(String id) async {
    final previous = state;
    try {
      await deadlineRepository.deleteDeadline(id);
      state = state.whenData(
        (items) => items.where((d) => d.id != id).toList(),
      );
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateDeadline(String id, Map<String, dynamic> patch) async {
    final previous = state;
    try {
      final updated =
          await deadlineRepository.updateDeadline(id, patch) as Deadline;
      state = state.whenData(
        (items) => items.map((d) => d.id == id ? updated : d).toList(),
      );
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> markDeadlineCompleted(String id) async {
    final previous = state;
    try {
      final updated =
          await deadlineRepository.markDeadlineCompleted(
                id: id,
                isCompleted: true,
              )
              as Deadline;
      state = state.whenData(
        (items) => items.map((d) => d.id == id ? updated : d).toList(),
      );
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> toggleDeadlineCompletion(String id) async {
    final current = state.value;
    if (current == null) return;

    Deadline? existing;
    for (final deadline in current) {
      if (deadline.id == id) {
        existing = deadline;
        break;
      }
    }
    if (existing == null) return;

    final previous = state;
    try {
      final updated =
          await deadlineRepository.markDeadlineCompleted(
                id: id,
                isCompleted: !existing.isCompleted,
              )
              as Deadline;
      state = state.whenData(
        (items) => items.map((d) => d.id == id ? updated : d).toList(),
      );
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}

final deadlinesProvider =
    StateNotifierProvider<DeadlinesNotifier, AsyncValue<List<Deadline>>>((ref) {
      final repo = ref.watch(deadlineRepositoryProvider);
      final userId = ref.watch(currentUserProvider)?.id;
      final semesterIdAsync = ref.watch(activeSemesterProvider);
      final supabase = Supabase.instance.client;
      final notifier = DeadlinesNotifier(
        ref: ref,
        deadlineRepository: repo,
        supabaseClient: supabase,
      );

      semesterIdAsync.when(
        data: (id) {
          if (userId != null && id != null) {
            notifier.loadDeadlines(userId: userId, semesterId: id);
          }
        },
        loading: () => {},
        error: (_, __) => {},
      );

      return notifier;
    });

final filteredDeadlinesProvider = Provider<AsyncValue<List<Deadline>>>((ref) {
  final deadlinesAsync = ref.watch(deadlinesProvider);
  final filter = ref.watch(taskFilterProvider);

  int compareDeadlines(Deadline a, Deadline b) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    final aDueDay = DateTime(a.deadlineDate.year, a.deadlineDate.month, a.deadlineDate.day);
    final bDueDay = DateTime(b.deadlineDate.year, b.deadlineDate.month, b.deadlineDate.day);
    
    bool isOverdue(Deadline d, DateTime dueDay) {
      if (d.isCompleted) return false;
      return dueDay.isBefore(startOfToday);
    }
    
    bool aIsOverdue = isOverdue(a, aDueDay);
    bool bIsOverdue = isOverdue(b, bDueDay);
    bool aIsCompleted = a.isCompleted;
    bool bIsCompleted = b.isCompleted;

    if (aIsCompleted && !bIsCompleted) return 1;
    if (!aIsCompleted && bIsCompleted) return -1;
    
    if (aIsOverdue && !bIsOverdue) return -1;
    if (!aIsOverdue && bIsOverdue) return 1;

    return a.deadlineDate.compareTo(b.deadlineDate);
  }

  return deadlinesAsync.whenData((List<Deadline> deadlines) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    List<Deadline> filtered;
    
    switch (filter) {
      case 'pending':
        filtered = deadlines.where((d) => !d.isCompleted).toList();
        break;
      case 'completed':
        filtered = deadlines.where((d) => d.isCompleted).toList();
        break;
      case 'overdue':
        filtered = deadlines.where((d) {
          final dueDay = DateTime(d.deadlineDate.year, d.deadlineDate.month, d.deadlineDate.day);
          return !d.isCompleted && dueDay.isBefore(startOfToday);
        }).toList();
        break;
      default:
        filtered = deadlines;
    }
    
    final sorted = List<Deadline>.from(filtered)..sort(compareDeadlines);
    return sorted;
  });
});
