import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeLoadedProvider = StateProvider<bool>((ref) => false);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._box) : super(ThemeMode.dark) {
    _init();
  }

  final Box _box;

  void _init() {
    final saved = _box.get('theme', defaultValue: 'dark');
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _box.put('theme', mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = Hive.box('settings');
  
  // Use microtask to avoid modifying other providers during initialization
  Future.microtask(() {
    ref.read(themeLoadedProvider.notifier).state = true;
  });
  
  return ThemeNotifier(box);
});

