import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: const Color(0xFFFFFFFF),
      error: AppColors.danger,
    );

    return _theme(
      colorScheme: colorScheme,
      canvas: const Color(0xFFF8F6F2),
      surface: const Color(0xFFFFFFFF),
      ink: const Color(0xFF17151D),
      inkMuted: const Color(0xFF6D6976),
      outline: const Color(0xFFE7E3EA),
      primarySoft: const Color(0xFFE5F3F1),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: const Color(0xFF2F8F87),
          surface: const Color(0xFF181C1B),
          error: const Color(0xFFFFB4AB),
        ).copyWith(
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF1C3835),
          onPrimaryContainer: const Color(0xFFC1E6E1),
          secondary: const Color(0xFFADB8B4),
          onSecondary: const Color(0xFF1A211F),
          secondaryContainer: const Color(0xFF29312E),
          onSecondaryContainer: const Color(0xFFDDE5E2),
          tertiary: const Color(0xFFC4B8AE),
          onTertiary: const Color(0xFF27211D),
          surface: const Color(0xFF181C1B),
          onSurface: const Color(0xFFF2F4F3),
          onSurfaceVariant: const Color(0xFFB3BBB7),
          outline: const Color(0xFF737C78),
          outlineVariant: const Color(0xFF353B38),
          surfaceContainerLowest: const Color(0xFF0E1110),
          surfaceContainerLow: const Color(0xFF141716),
          surfaceContainer: const Color(0xFF181C1B),
          surfaceContainerHigh: const Color(0xFF202523),
          surfaceContainerHighest: const Color(0xFF292F2C),
        );

    return _theme(
      colorScheme: colorScheme,
      canvas: const Color(0xFF0E1110),
      surface: const Color(0xFF181C1B),
      ink: const Color(0xFFF2F4F3),
      inkMuted: const Color(0xFFAAAFAA),
      outline: const Color(0xFF353A38),
      primarySoft: const Color(0xFF1C3835),
    );
  }

  static ThemeData _theme({
    required ColorScheme colorScheme,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color inkMuted,
    required Color outline,
    required Color primarySoft,
  }) {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surface,
        indicatorColor: primarySoft,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(color: ink),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primarySoft,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    );
  }

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarPageTransitionsBuilder(),
      TargetPlatform.iOS: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarCupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarPageTransitionsBuilder(),
      TargetPlatform.windows: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarPageTransitionsBuilder(),
      TargetPlatform.linux: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarPageTransitionsBuilder(),
      TargetPlatform.fuchsia: kIsWeb
          ? _DarJarWebPageTransitionsBuilder()
          : _DarJarPageTransitionsBuilder(),
    },
  );
}

class _DarJarCupertinoPageTransitionsBuilder
    extends CupertinoPageTransitionsBuilder {
  const _DarJarCupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);
}

class _DarJarWebPageTransitionsBuilder extends PageTransitionsBuilder {
  const _DarJarWebPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 140);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 140);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _DarJarPageTransitionsBuilder extends PageTransitionsBuilder {
  const _DarJarPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
      child: child,
    );
  }
}
