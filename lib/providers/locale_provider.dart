import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

final localeLoadedProvider = StateProvider<bool>((ref) => false);

final languageSelectedProvider = StateProvider<bool>((ref) {
  final box = Hive.box('settings');
  return box.get('language_selected', defaultValue: false);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._box, this._ref) : super(const Locale('en')) {
    _init();
  }

  final Box _box;
  final Ref _ref;
  
  void _init() {
    final saved = _box.get('locale', defaultValue: 'en');
    state = Locale(saved);
  }

  void setLocale(Locale locale) {
    state = locale;
    _box.put('locale', locale.languageCode);
  }

  void completeLanguageSelection() {
    _box.put('language_selected', true);
    _ref.read(languageSelectedProvider.notifier).state = true;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final box = Hive.box('settings');
  
  Future.microtask(() {
    ref.read(localeLoadedProvider.notifier).state = true;
  });
  
  return LocaleNotifier(box, ref);
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return lookupAppLocalizations(locale);
});
