import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/localization/zgh_framework_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/app/theme/app_theme_mode_controller.dart';
import 'package:darjar/app/theme/app_theme_refresh_boundary.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/features/profile/presentation/appearance_selector.dart';
import 'package:darjar/features/profile/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('theme mode defaults to system and persists a selection', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(appThemeModeProvider.future), ThemeMode.system);

    await container.read(appThemeModeProvider.notifier).select(ThemeMode.dark);

    expect(container.read(appThemeModeProvider).value, ThemeMode.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppThemeModeController.preferenceKey), 'dark');
  });

  testWidgets('account settings applies dark mode immediately', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SettingsPage())],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: _ThemeSettingsHost(router: router)),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settings-page'))),
      ).brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('theme-mode-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('داكن').last);
    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settings-page'))),
      ).brightness,
      Brightness.dark,
    );
    expect(find.byKey(const Key('theme-mode-selector')), findsOneWidget);
  });

  testWidgets('back navigation repaints retained routes and the brand', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const _ThemeProbePage()),
        GoRoute(
          path: '/appearance',
          builder: (_, _) => const _AppearancePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: _ThemeSettingsHost(router: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-mode-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('داكن').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearance-back')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ColoredBox>(find.byKey(const Key('adaptive-canvas'))).color,
      AppColors.canvas,
    );
    expect(AppColors.canvas, const Color(0xFF0E1110));
    expect(
      tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter,
      ColorFilter.mode(AppTheme.dark.colorScheme.onSurface, BlendMode.srcIn),
    );
  });
}

class _ThemeSettingsHost extends ConsumerWidget {
  const _ThemeSettingsHost({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    AppColors.configure(mode);
    return MaterialApp.router(
      key: ValueKey('test-app-${mode.name}'),
      locale: const Locale('ar'),
      localizationsDelegates: [
        ...ZghFrameworkLocalizations.delegates,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
    );
  }
}

class _ThemeProbePage extends StatelessWidget {
  const _ThemeProbePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DarJarThemeRefreshBoundary(
        builder: (context) => ColoredBox(
          key: const Key('adaptive-canvas'),
          color: AppColors.canvas,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DarJarLogo(
                  asset:
                      'assets/images/branding/darjar-logo-header-compact.png',
                  size: 31,
                ),
                TextButton(
                  key: const Key('open-appearance'),
                  onPressed: () => context.push('/appearance'),
                  child: const Text('المظهر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePage extends ConsumerWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          IconButton(
            key: const Key('appearance-back'),
            onPressed: context.pop,
            icon: const Icon(Icons.arrow_back),
          ),
          DarJarAppearanceSelector(
            selectedMode:
                ref.watch(appThemeModeProvider).value ?? ThemeMode.system,
            onSelected: ref.read(appThemeModeProvider.notifier).select,
          ),
        ],
      ),
    );
  }
}
