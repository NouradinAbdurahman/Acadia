import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final onboardingLoadedProvider = StateProvider<bool>((ref) => false);

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._ref) : super(false) {
    _loadOnboardingFromOpenBox();
  }

  final Ref _ref;

  static const String _boxName = 'settings';
  static const String _key = 'onboarding_completed';

  /// [main] already opens `settings` before [runApp]; use the open box so we
  /// never leave [onboardingLoadedProvider] false if a second [openBox] stalls
  /// (seen on some physical Android devices).
  void _loadOnboardingFromOpenBox() {
    try {
      final box = Hive.box(_boxName);
      state = box.get(_key, defaultValue: false);
    } catch (e, st) {
      debugPrint('[OnboardingNotifier] Failed to read onboarding flag: $e');
      debugPrintStack(stackTrace: st);
      state = false;
    }
    Future.microtask(() {
      _ref.read(onboardingLoadedProvider.notifier).state = true;
    });
  }

  Future<void> completeOnboarding() async {
    state = true;
    try {
      final box = Hive.box(_boxName);
      await box.put(_key, true);
    } catch (e, st) {
      debugPrint('[OnboardingNotifier] Failed to persist onboarding: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
