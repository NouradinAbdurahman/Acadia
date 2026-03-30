import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analytics_data.dart';
import '../repositories/analytics_repository.dart';
import 'app_providers.dart';

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>(
  (ref) {
    final repository = ref.watch(analyticsRepositoryProvider);
    final supabase = ref.watch(supabaseProvider);
    final user = ref.watch(currentUserProvider);
    
    final notifier = AnalyticsNotifier(
      repository: repository,
      supabaseClient: supabase,
    );
    
    if (user != null) {
      notifier.loadAnalytics(user.id);
    }
    
    return notifier;
  },
);

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  final AnalyticsRepository repository;
  final SupabaseClient supabaseClient;

  AnalyticsNotifier({
    required this.repository,
    required this.supabaseClient,
  }) : super(const AsyncValue.loading());

  Future<void> loadAnalytics(String userId) async {
    try {
      state = const AsyncValue.loading();
      final data = await repository.getAnalyticsData(userId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      await loadAnalytics(userId);
    }
  }
}
