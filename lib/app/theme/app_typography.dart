import 'package:darjar/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const fontFamily = 'IBM Plex Sans Arabic';

  static TextTheme get textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.inkMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.inkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}
