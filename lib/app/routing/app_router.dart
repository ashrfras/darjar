import 'package:darjar/features/community/presentation/community_feed_page.dart';
import 'package:darjar/features/community/presentation/create_post_page.dart';
import 'package:darjar/features/component_gallery/presentation/component_gallery_page.dart';
import 'package:darjar/features/marketplace/presentation/create_listing_page.dart';
import 'package:darjar/features/marketplace/presentation/listing_details_page.dart';
import 'package:darjar/features/marketplace/presentation/marketplace_page.dart';
import 'package:darjar/features/onboarding/presentation/onboarding_page.dart';
import 'package:darjar/features/profile/presentation/profile_page.dart';
import 'package:darjar/features/profile/presentation/settings_page.dart';
import 'package:darjar/features/residence/presentation/residence_setup_page.dart';
import 'package:darjar/features/services/presentation/create_maintenance_page.dart';
import 'package:darjar/features/services/presentation/dues_page.dart';
import 'package:darjar/features/services/presentation/maintenance_page.dart';
import 'package:darjar/features/services/presentation/management_page.dart';
import 'package:darjar/features/services/presentation/services_home_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const residenceSetup = '/residence/setup';
  static const community = '/community';
  static const createPost = '/community/create';
  static const marketplace = '/marketplace';
  static const createListing = '/marketplace/create';
  static const services = '/services';
  static const maintenance = '/services/maintenance';
  static const createMaintenance = '/services/maintenance/create';
  static const dues = '/services/dues';
  static const management = '/services/management';
  static const profile = '/profile';
  static const settings = '/settings';
  static const gallery = '/gallery';

  static String listingDetails(String id) => '/marketplace/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.onboarding),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.residenceSetup,
        builder: (context, state) => const ResidenceSetupPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DarJarShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.community,
            builder: (context, state) => const CommunityFeedPage(),
          ),
          GoRoute(
            path: AppRoutes.createPost,
            builder: (context, state) => const CreatePostPage(),
          ),
          GoRoute(
            path: AppRoutes.marketplace,
            builder: (context, state) => const MarketplacePage(),
          ),
          GoRoute(
            path: AppRoutes.createListing,
            builder: (context, state) => const CreateListingPage(),
          ),
          GoRoute(
            path: '/marketplace/:listingId',
            builder: (context, state) => ListingDetailsPage(
              listingId: state.pathParameters['listingId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (context, state) => const ServicesHomePage(),
          ),
          GoRoute(
            path: AppRoutes.maintenance,
            builder: (context, state) => const MaintenancePage(),
          ),
          GoRoute(
            path: AppRoutes.createMaintenance,
            builder: (context, state) => const CreateMaintenancePage(),
          ),
          GoRoute(
            path: AppRoutes.dues,
            builder: (context, state) => const DuesPage(),
          ),
          GoRoute(
            path: AppRoutes.management,
            builder: (context, state) => const ManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
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
