import 'package:darjar/features/account/presentation/account_resolution_page.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/auth/presentation/phone_auth_page.dart';
import 'package:darjar/features/community/presentation/community_feed_page.dart';
import 'package:darjar/features/community/presentation/create_post_page.dart';
import 'package:darjar/features/community/presentation/community_post_detail_page.dart';
import 'package:darjar/features/component_gallery/presentation/component_gallery_page.dart';
import 'package:darjar/features/directory/presentation/directory_page.dart';
import 'package:darjar/features/directory/presentation/directory_profile_page.dart';
import 'package:darjar/features/onboarding/presentation/onboarding_page.dart';
import 'package:darjar/features/profile/presentation/profile_page.dart';
import 'package:darjar/features/profile/presentation/settings_page.dart';
import 'package:darjar/features/residence/presentation/dues_page.dart';
import 'package:darjar/features/residence/presentation/finance_transactions_page.dart';
import 'package:darjar/features/residence/presentation/group_invitation_page.dart';
import 'package:darjar/features/residence/presentation/management_page.dart';
import 'package:darjar/features/residence/presentation/apartments_residents_page.dart';
import 'package:darjar/features/residence/presentation/residence_admin_page.dart';
import 'package:darjar/features/residence/presentation/residence_finances_page.dart';
import 'package:darjar/features/residence/presentation/residence_home_page.dart';
import 'package:darjar/features/residence/presentation/residence_setup_page.dart';
import 'package:darjar/features/residence/presentation/residence_settings_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const auth = '/auth/phone';
  static const accountResolution = '/auth/resolve';
  static const onboarding = '/onboarding';
  static const residenceSetup = '/residence/setup';
  static const community = '/community';
  static const createPost = '/community/create';
  static const directory = '/directory';
  static const residence = '/residence';
  static const dues = '/residence/dues';
  static const residenceFinances = '/residence/finances';
  static const financeTransactions = '/residence/finances/transactions';
  static const management = '/residence/management';
  static const manageApartments = '/residence/admin/apartments';
  static const groupInvitation = '/residence/admin/apartments/invitation';
  static const manageProjects = '/residence/admin/projects';
  static const manageResidence = '/residence/admin/details';
  static const profile = '/profile';
  static const settings = '/settings';
  static const gallery = '/gallery';

  static String directoryProfile(String id) => '/directory/$id';
  static String communityPost(String id) => '/community/post/$id';
}

final appInitialLocationProvider = Provider<String>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  return user == null ? AppRoutes.onboarding : AppRoutes.accountResolution;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authRefresh = _AuthRefreshListenable(authRepository.currentUser);
  ref.listen(authStateProvider, (previous, next) {
    next.whenData(authRefresh.update);
  });
  final router = GoRouter(
    initialLocation: ref.watch(appInitialLocationProvider),
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.auth;
      final isAccountResolutionRoute = location == AppRoutes.accountResolution;
      final isPublicRoute =
          location == '/' || location == AppRoutes.onboarding || isAuthRoute;
      final user = authRefresh.user;

      if (user == null && !isPublicRoute) {
        return Uri(
          path: AppRoutes.auth,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (user != null && isAuthRoute) {
        return AppRoutes.accountResolution;
      }

      if (user == null && isAccountResolutionRoute) {
        return AppRoutes.auth;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.onboarding),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const PhoneAuthPage(),
      ),
      GoRoute(
        path: AppRoutes.accountResolution,
        builder: (context, state) => const AccountResolutionPage(),
      ),
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
            path: '/community/post/:postId',
            builder: (context, state) => CommunityPostDetailPage(
              postId: state.pathParameters['postId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.directory,
            builder: (context, state) => const DirectoryPage(),
          ),
          GoRoute(
            path: '/directory/:entryId',
            builder: (context, state) =>
                DirectoryProfilePage(entryId: state.pathParameters['entryId']!),
          ),
          GoRoute(
            path: AppRoutes.residence,
            builder: (context, state) => const ResidenceHomePage(),
          ),
          GoRoute(
            path: AppRoutes.dues,
            builder: (context, state) => const DuesPage(),
          ),
          GoRoute(
            path: AppRoutes.residenceFinances,
            builder: (context, state) => const ResidenceFinancesPage(),
          ),
          GoRoute(
            path: AppRoutes.financeTransactions,
            builder: (context, state) => const FinanceTransactionsPage(),
          ),
          GoRoute(
            path: AppRoutes.management,
            builder: (context, state) => const ManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.manageApartments,
            builder: (context, state) => const ApartmentsResidentsPage(),
          ),
          GoRoute(
            path: AppRoutes.groupInvitation,
            builder: (context, state) => const GroupInvitationPage(),
          ),
          GoRoute(
            path: AppRoutes.manageProjects,
            builder: (context, state) => const ResidenceAdminPage.projects(),
          ),
          GoRoute(
            path: AppRoutes.manageResidence,
            builder: (context, state) => const ResidenceSettingsPage(),
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

  ref.onDispose(() {
    authRefresh.dispose();
    router.dispose();
  });
  return router;
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.user);

  AuthUser? user;

  void update(AuthUser? nextUser) {
    user = nextUser;
    notifyListeners();
  }
}
