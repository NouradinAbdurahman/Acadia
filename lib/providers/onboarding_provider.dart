import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final onboardingLoadedProvider = StateProvider<bool>((ref) => false);

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._ref) : super(false) {
    _loadOnboardingStatus();
  }

  final Ref _ref;

  static const String _boxName = 'settings';
  static const String _key = 'onboarding_completed';

  Future<void> _loadOnboardingStatus() async {
    final box = await Hive.openBox(_boxName);
    state = box.get(_key, defaultValue: false);
    _ref.read(onboardingLoadedProvider.notifier).state = true;
  }

  Future<void> completeOnboarding() async {
    state = true;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, true);
  }
}
