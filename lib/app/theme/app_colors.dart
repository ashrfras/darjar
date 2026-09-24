import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0F766E);
  static ThemeMode _themeMode = ThemeMode.system;

  static void configure(ThemeMode themeMode) => _themeMode = themeMode;

  static bool get _isDark => switch (_themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  static Color get primarySoft =>
      _isDark ? const Color(0xFF1C3835) : const Color(0xFFE5F3F1);

  // Semantic feature names all resolve to the single DarJar accent.
  static const community = primary;
  static const directory = primary;
  static Color get directorySoft => primarySoft;
  static const residence = primary;
  static Color get residenceSoft => primarySoft;
  static const warning = Color(0xFFE97824);
  static Color get warningSoft =>
      _isDark ? const Color(0xFF3D291B) : const Color(0xFFFFF1E5);
  static const danger = Color(0xFFE5484D);
  static Color get canvas =>
      _isDark ? const Color(0xFF0E1110) : const Color(0xFFF8F6F2);
  static Color get surface =>
      _isDark ? const Color(0xFF181C1B) : const Color(0xFFFFFFFF);
  static Color get ink =>
      _isDark ? const Color(0xFFF2F4F3) : const Color(0xFF17151D);
  static Color get inkMuted =>
      _isDark ? const Color(0xFFAAAFAA) : const Color(0xFF6D6976);
  static Color get outline =>
      _isDark ? const Color(0xFF353A38) : const Color(0xFFE7E3EA);
}
