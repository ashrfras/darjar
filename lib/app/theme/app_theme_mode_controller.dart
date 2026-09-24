import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeModeProvider =
    AsyncNotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

class AppThemeModeController extends AsyncNotifier<ThemeMode> {
  static const preferenceKey = 'app_theme_mode';

  ThemeMode? _selectedDuringLoad;

  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedMode = preferences.getString(preferenceKey);
    return _selectedDuringLoad ?? themeModeFromPreference(storedMode);
  }

  Future<void> select(ThemeMode mode) async {
    _selectedDuringLoad = mode;
    state = AsyncData(mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, mode.name);
  }

  static ThemeMode themeModeFromPreference(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
