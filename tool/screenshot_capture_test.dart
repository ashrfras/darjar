import 'package:darjar/features/directory/presentation/directory_page.dart';
import 'package:darjar/features/directory/presentation/directory_profile_page.dart';
import 'screenshot_demo_data.dart';
// Local capture harness: all data stays in memory; Firebase is never initialized.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/community/presentation/community_feed_page.dart';
import 'package:darjar/features/residence/presentation/residence_home_page.dart';
import 'package:darjar/features/residence/presentation/residence_finances_page.dart';
import 'package:darjar/features/residence/presentation/dues_management_page.dart';
import 'package:darjar/features/residence/presentation/finance_management_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final item in {
      'IBM Plex Sans Arabic': 'assets/fonts/IBMPlexSansArabic-Regular.ttf',
      'Cairo': 'assets/fonts/Cairo-Variable.ttf',
      'MaterialIcons':
          '${File(Process.runSync('which', ['flutter']).stdout.toString().trim()).resolveSymbolicLinksSync().replaceFirst(RegExp(r'/bin/flutter$'), '')}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(item.key);
      loader.addFont(
        item.value.startsWith('/')
            ? File(
                item.value,
              ).readAsBytes().then((b) => ByteData.sublistView(b))
            : rootBundle.load(item.value),
      );
      await loader.load();
    }
  });
  final pages = <String, (String, Widget)>{
    '01-feed': ('/community', const CommunityFeedPage()),
    '06-services': ('/directory', const DirectoryPage()),
    '07-service-profile': (
      '/directory/service0',
      const DirectoryProfilePage(entryId: 'service0'),
    ),
    '02-residence': ('/residence', const ResidenceHomePage()),
    '03-residence-finances': (
      '/residence/finances',
      const ResidenceFinancesPage(),
    ),
    '04-subscription-management': (
      '/residence/admin/dues',
      const DuesManagementPage(),
    ),
    '05-finance-management': (
      '/residence/admin/finances',
      const FinanceManagementPage(),
    ),
  };
  for (final entry in pages.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      tester.view.physicalSize = Size(
        1440,
        entry.key == '03-residence-finances'
            ? 850
            : entry.key == '02-residence'
            ? 1050
            : 1200,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppColors.configure(ThemeMode.light);
      final router = GoRouter(
        initialLocation: entry.value.$1,
        routes: [
          GoRoute(
            path: entry.value.$1,
            builder: (_, _) =>
                DarJarShell(location: entry.value.$1, child: entry.value.$2),
          ),
        ],
      );
      await tester.pumpWidget(
        screenshotDemoScope(
          child: RepaintBoundary(
            key: const Key('capture'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MaterialApp));
        for (var i = 1; i <= 8; i++) {
          await precacheImage(
            AssetImage('assets/images/community/demo-avatar-$i.jpg'),
            context,
          );
        }
        for (final name in [
          'plumber.jpg',
          'elevator-tools.jpg',
          'elevator-maintenance.jpg',
          'tree-saplings.jpg',
        ]) {
          await precacheImage(
            AssetImage('assets/images/community/$name'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'screenshots/light/${entry.key}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
