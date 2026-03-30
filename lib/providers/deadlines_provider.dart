import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/deadline.dart';
import 'app_providers.dart';

class DeadlinesNotifier
    extends StateNotifier<AsyncValue<List<Deadline>>> {
  DeadlinesNotifier({
    required this.deadlineRepository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading()) {
    _loadDeadlines();
  }

  final dynamic deadlineRepository;
  final SupabaseClient supabaseClient;

  Future<void> _loadDeadlines() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final list = await deadlineRepository.getDeadlines(userId)
          as List<Deadline>;
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadDeadlines();
  }

  Future<void> createDeadline(Deadline deadline) async {
    try {
      final created = await deadlineRepository.createDeadline(deadline)
          as Deadline;
      state = state.whenData((items) => [created, ...items]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDeadline(String id) async {
    try {
      await deadlineRepository.deleteDeadline(id);
      state = state.whenData(
        (items) => items.where((d) => d.id != id).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDeadline(
    String id,
    Map<String, dynamic> patch,
  ) async {
    try {
      final updated =
          await deadlineRepository.updateDeadline(id, patch)
              as Deadline;
      state = state.whenData(
        (items) => items
            .map((d) => d.id == id ? updated : d)
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final deadlinesProvider =
    StateNotifierProvider<DeadlinesNotifier, AsyncValue<List<Deadline>>>(
  (ref) {
    final repo = ref.watch(deadlineRepositoryProvider);
    final supabase = Supabase.instance.client;
    return DeadlinesNotifier(
      deadlineRepository: repo,
      supabaseClient: supabase,
    );
  },
);

