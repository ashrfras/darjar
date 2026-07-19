import 'package:darjar/features/component_gallery/presentation/component_gallery_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:darjar/features/shell/presentation/section_placeholder_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const community = '/community';
  static const marketplace = '/marketplace';
  static const services = '/services';
  static const gallery = '/gallery';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.community,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return DarJarShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.community,
            builder: (context, state) =>
                const SectionPlaceholderPage(section: AppSection.community),
          ),
          GoRoute(
            path: AppRoutes.marketplace,
            builder: (context, state) =>
                const SectionPlaceholderPage(section: AppSection.marketplace),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (context, state) =>
                const SectionPlaceholderPage(section: AppSection.services),
          ),
          GoRoute(
            path: AppRoutes.gallery,
            builder: (context, state) => const ComponentGalleryPage(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
