import 'package:darjar/app/theme/app_theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recreates retained route UI when its effective theme changes.
///
/// GoRouter keeps previous route elements alive for back navigation. Rebuilding
/// below the Navigator prevents an old route from returning with stale colors.
class DarJarThemeRefreshBoundary extends ConsumerWidget {
  const DarJarThemeRefreshBoundary({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final brightness = Theme.of(context).brightness;
    return KeyedSubtree(
      key: ValueKey('theme-boundary-${mode.name}-${brightness.name}'),
      child: Builder(builder: builder),
    );
  }
}
