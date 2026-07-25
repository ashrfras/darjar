import 'package:darjar/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const fontFamily = 'IBM Plex Sans Arabic';
  static const brandArabic = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w800,
  );
  static const brandLatin = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w400,
    letterSpacing: 2.5,
  );

  static TextTheme get textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.inkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.inkMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}
