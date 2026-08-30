import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleProvider = AsyncNotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

class AppLocaleController extends AsyncNotifier<Locale> {
  static const _preferenceKey = 'app_locale';

  Locale? _selectedDuringLoad;

  @override
  Future<Locale> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedLanguage = preferences.getString(_preferenceKey);
    return _selectedDuringLoad ?? _supportedLocale(storedLanguage);
  }

  Future<void> select(Locale locale) async {
    if (locale.languageCode != 'ar' && locale.languageCode != 'en') return;
    _selectedDuringLoad = locale;
    state = AsyncData(locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, locale.languageCode);
  }

  Locale _supportedLocale(String? languageCode) => switch (languageCode) {
    'en' => const Locale('en'),
    _ => const Locale('ar'),
  };
}
