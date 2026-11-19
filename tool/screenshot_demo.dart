import 'package:darjar/features/directory/presentation/directory_page.dart';
import 'package:darjar/features/directory/presentation/directory_profile_page.dart';
// Local preview only. Production lib/main.dart is deliberately unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/features/community/presentation/community_feed_page.dart';
import 'package:darjar/features/residence/presentation/residence_home_page.dart';
import 'package:darjar/features/residence/presentation/residence_finances_page.dart';
import 'package:darjar/features/residence/presentation/dues_management_page.dart';
import 'package:darjar/features/residence/presentation/finance_management_page.dart';
import 'package:darjar/features/residence/presentation/residence_administration_page.dart';
import 'package:darjar/features/residence/presentation/finance_transactions_page.dart';
import 'package:darjar/features/residence/presentation/dues_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'screenshot_demo_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  AppColors.configure(ThemeMode.light);
  final pages = <String, Widget>{
    '/community': const CommunityFeedPage(),
    '/directory': const DirectoryPage(),
    '/residence': const ResidenceHomePage(),
    '/residence/finances': const ResidenceFinancesPage(),
    '/residence/finances/transactions': const FinanceTransactionsPage(),
    '/residence/dues': const DuesPage(),
    '/administration': const ResidenceAdministrationPage(),
    '/residence/admin/dues': const DuesManagementPage(),
    '/residence/admin/finances': const FinanceManagementPage(),
  };
  final router = GoRouter(
    initialLocation: '/community',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/community'),
      ShellRoute(
        builder: (_, state, child) =>
            DarJarShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/directory/:entryId',
            builder: (_, state) =>
                DirectoryProfilePage(entryId: state.pathParameters['entryId']!),
          ),
          for (final page in pages.entries)
            GoRoute(path: page.key, builder: (_, _) => page.value),
        ],
      ),
    ],
  );
  runApp(
    screenshotDemoScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'DarJar',
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    ),
  );
}
