import 'package:darjar/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextTheme get textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.ink,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        color: AppColors.inkMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: AppColors.inkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}
