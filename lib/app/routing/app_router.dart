import 'package:darjar/features/account/presentation/account_resolution_page.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/auth/presentation/phone_auth_page.dart';
import 'package:darjar/features/community/presentation/community_feed_page.dart';
import 'package:darjar/features/community/presentation/create_post_page.dart';
import 'package:darjar/features/community/presentation/community_post_detail_page.dart';
import 'package:darjar/features/directory/presentation/directory_page.dart';
import 'package:darjar/features/directory/presentation/directory_profile_page.dart';
import 'package:darjar/features/directory/presentation/create_service_page.dart';
import 'package:darjar/features/documents/presentation/residence_documents_management_page.dart';
import 'package:darjar/features/documents/presentation/residence_documents_page.dart';
import 'package:darjar/features/onboarding/presentation/onboarding_page.dart';
import 'package:darjar/features/profile/presentation/profile_page.dart';
import 'package:darjar/features/profile/presentation/privacy_policy_page.dart';
import 'package:darjar/features/profile/presentation/about_app_page.dart';
import 'package:darjar/features/profile/presentation/delete_account_page.dart';
import 'package:darjar/features/profile/presentation/settings_page.dart';
import 'package:darjar/features/residence/presentation/dues_management_page.dart';
import 'package:darjar/features/residence/presentation/dues_page.dart';
import 'package:darjar/features/residence/presentation/finance_transactions_page.dart';
import 'package:darjar/features/residence/presentation/finance_management_page.dart';
import 'package:darjar/features/residence/presentation/group_invitation_page.dart';
import 'package:darjar/features/residence/presentation/management_page.dart';
import 'package:darjar/features/residence/presentation/apartments_residents_page.dart';
import 'package:darjar/features/residence/presentation/residence_admin_page.dart';
import 'package:darjar/features/residence/presentation/residence_administration_page.dart';
import 'package:darjar/features/residence/presentation/residence_finances_page.dart';
import 'package:darjar/features/residence/presentation/residence_home_page.dart';
import 'package:darjar/features/residence/presentation/residence_members_page.dart';
import 'package:darjar/features/residence/presentation/residence_setup_page.dart';
import 'package:darjar/features/residence/presentation/residence_settings_page.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const auth = '/auth/phone';
  static const accountResolution = '/auth/resolve';
  static const onboarding = '/onboarding';
  static const residenceSetup = '/residence/setup';
  static const joinResidence = '/join/:code';
  static const community = '/community';
  static const createPost = '/community/create';
  static const directory = '/directory';
  static const createService = '/directory/create';
  static const residence = '/residence';
  static const residenceResidents = '/residence/residents';
  static const documents = '/residence/documents';
  static const dues = '/residence/dues';
  static const residenceFinances = '/residence/finances';
  static const financeTransactions = '/residence/finances/transactions';
  static const management = '/residence/management';
  static const administration = '/administration';
  static const manageApartments = '/residence/admin/apartments';
  static const manageDues = '/residence/admin/dues';
  static const manageFinances = '/residence/admin/finances';
  static const manageDocuments = '/residence/admin/documents';
  static const groupInvitation = '/residence/admin/apartments/invitation';
  static const manageProjects = '/residence/admin/projects';
  static const manageResidence = '/residence/admin/details';
  static const profile = '/profile';
  static const privacyPolicy = '/profile/privacy';
  static const publicPrivacyPolicy = '/privacy';
  static const deleteAccount = '/delete-account';
  static const aboutApp = '/profile/about';
  static const settings = '/settings';

  static String directoryProfile(String id) => '/directory/$id';
  static String editService(String id) => '/directory/$id/edit';
  static String communityPost(String id) => '/community/post/$id';
  static String residenceInvitation(String code) => '/join/$code';
}

final appInitialLocationProvider = Provider<String>((ref) {
  final platformInitialLocation = ref.watch(platformInitialLocationProvider);
  final normalizedPlatformLocation = normalizePlatformInitialLocation(
    platformInitialLocation,
  );
  if (normalizedPlatformLocation != null) {
    return normalizedPlatformLocation;
  }

  final user = ref.watch(authRepositoryProvider).currentUser;
  return user == null ? AppRoutes.onboarding : AppRoutes.accountResolution;
});

final platformInitialLocationProvider = Provider<String>((ref) => '/');

String? normalizePlatformInitialLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null || !uri.path.startsWith('/') || uri.path == '/') {
    return null;
  }

  if (!uri.hasAuthority) {
    return uri.toString();
  }

  if (uri.scheme.toLowerCase() != 'https' ||
      uri.host.toLowerCase() != 'darjar.app') {
    return null;
  }

  return Uri(
    path: uri.path,
    query: uri.hasQuery ? uri.query : null,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();
}

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
          location == AppRoutes.root ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.publicPrivacyPolicy ||
          location == AppRoutes.deleteAccount ||
          isAuthRoute;
      final user = authRefresh.user;

      if (user == null && !isPublicRoute) {
        return Uri(
          path: AppRoutes.auth,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (user != null && isAuthRoute) {
        final destination = state.uri.queryParameters['from'];
        final uri = destination == null ? null : Uri.tryParse(destination);
        if (uri != null && uri.path.startsWith('/join/') && !uri.hasAuthority) {
          return uri.toString();
        }
        return AppRoutes.accountResolution;
      }

      if (user == null && isAccountResolutionRoute) {
        return AppRoutes.auth;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.onboarding,
      ),
      GoRoute(
        path: AppRoutes.publicPrivacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(isPublic: true),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountPage(),
      ),
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
      GoRoute(
        path: AppRoutes.joinResidence,
        builder: (context, state) =>
            ResidenceSetupPage(invitationCode: state.pathParameters['code']),
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
            path: AppRoutes.createService,
            builder: (context, state) => const CreateServicePage(),
          ),
          GoRoute(
            path: '/directory/:entryId/edit',
            builder: (context, state) =>
                CreateServicePage(entryId: state.pathParameters['entryId']!),
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
            path: AppRoutes.residenceResidents,
            builder: (context, state) => const ResidenceMembersPage(),
          ),
          GoRoute(
            path: AppRoutes.dues,
            builder: (context, state) => const DuesPage(),
          ),
          GoRoute(
            path: AppRoutes.documents,
            builder: (context, state) => const ResidenceDocumentsPage(),
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
            path: AppRoutes.administration,
            builder: (context, state) => const ResidenceAdministrationPage(),
          ),
          GoRoute(
            path: AppRoutes.manageApartments,
            builder: (context, state) => const ApartmentsResidentsPage(),
          ),
          GoRoute(
            path: AppRoutes.manageDues,
            builder: (context, state) => const DuesManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.manageFinances,
            builder: (context, state) => const FinanceManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.manageDocuments,
            builder: (context, state) =>
                const ResidenceDocumentsManagementPage(),
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
            path: AppRoutes.privacyPolicy,
            builder: (context, state) => const PrivacyPolicyPage(),
          ),
          GoRoute(
            path: AppRoutes.aboutApp,
            builder: (context, state) => const AboutAppPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
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
