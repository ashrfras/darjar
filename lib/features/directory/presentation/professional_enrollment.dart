import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_setup_scaffold.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/professional_profile_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final professionalAccountProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, AuthUser>(
      (ref, user) =>
          ref.watch(accountOnboardingRepositoryProvider).loadProfile(user),
    );

class ProfessionalClaimPrompt extends ConsumerStatefulWidget {
  const ProfessionalClaimPrompt({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ProfessionalClaimPrompt> createState() =>
      _ProfessionalClaimPromptState();
}

class _ProfessionalClaimPromptState
    extends ConsumerState<ProfessionalClaimPrompt> {
  AuthUser? _offeredTo;
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider);
    final user = session.isLoading
        ? ref.watch(authRepositoryProvider).currentUser
        : session.value;
    if (user == null) _offeredTo = null;
    return ListenableBuilder(
      listenable: widget.router.routeInformationProvider,
      builder: (context, child) {
        final path = widget.router.routeInformationProvider.value.uri.path;
        return _CandidateListener(
          user: user == _offeredTo ? null : user,
          path: path,
          onCandidates: (user, candidates) => _offer(user, candidates),
          child: child!,
        );
      },
      child: widget.child,
    );
  }

  Future<void> _offer(
    AuthUser user,
    List<ProfessionalCandidate> candidates,
  ) async {
    if (!mounted ||
        _checking ||
        _offeredTo == user ||
        ref.read(authRepositoryProvider).currentUser != user) {
      return;
    }
    _checking = true;
    final preferences = await SharedPreferences.getInstance();
    final key = 'professional-claim-dismissed-${user.uid}';
    final dismissed = preferences.getStringList(key)?.toSet() ?? <String>{};
    final available = candidates
        .where((candidate) => !dismissed.contains(candidate.id))
        .toList();
    _checking = false;
    if (!mounted || ref.read(authRepositoryProvider).currentUser != user) {
      return;
    }
    final path = widget.router.routeInformationProvider.value.uri.path;
    if (!_canOfferOn(path)) return;
    _offeredTo = user;
    if (available.isEmpty) return;
    final navigatorContext =
        widget.router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    final claimed = await showDialog<bool>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (_) => _ClaimDialog(user: user, candidates: available),
    );
    if (!mounted ||
        ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
      return;
    }
    if (claimed == true) {
      widget.router.go(AppRoutes.professional);
    } else if (claimed == false) {
      await preferences.setStringList(
        key,
        {...dismissed, ...available.map((candidate) => candidate.id)}.toList(),
      );
    }
  }
}

bool _canOfferOn(String path) =>
    !path.startsWith(AppRoutes.professional) &&
    path != AppRoutes.root &&
    path != AppRoutes.onboarding &&
    path != AppRoutes.install &&
    path != AppRoutes.auth &&
    path != AppRoutes.deleteAccount &&
    path != AppRoutes.support &&
    path != AppRoutes.publicPrivacyPolicy &&
    !path.startsWith('/r/');

class _CandidateListener extends ConsumerWidget {
  const _CandidateListener({
    required this.user,
    required this.path,
    required this.onCandidates,
    required this.child,
  });

  final AuthUser? user;
  final String path;
  final void Function(AuthUser, List<ProfessionalCandidate>) onCandidates;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = this.user;
    if (user == null ||
        user.phoneNumber?.isNotEmpty != true ||
        !_canOfferOn(path)) {
      return child;
    }
    final candidates = ref.watch(professionalCandidateProvider(user)).value;
    if (path == AppRoutes.accountResolution) {
      final account = ref.watch(accountResolutionProvider).value;
      // The resolution page redirects except when it displays pending
      // residence invitations or an account pending deletion.
      if (account == null ||
          account.deletionRequested ||
          account.profile != null ||
          account.invitations.isEmpty) {
        return child;
      }
    }
    if (candidates != null && candidates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onCandidates(user, candidates);
      });
    }
    return child;
  }
}

class ProfessionalEnrollmentPage extends ConsumerStatefulWidget {
  const ProfessionalEnrollmentPage({super.key});

  @override
  ConsumerState<ProfessionalEnrollmentPage> createState() =>
      _ProfessionalEnrollmentPageState();
}

class _ProfessionalEnrollmentPageState
    extends ConsumerState<ProfessionalEnrollmentPage> {
  late Future<void> _enrollment;
  bool _claimOpen = false;

  @override
  void initState() {
    super.initState();
    _enrollment = _load();
  }

  Future<void> _load() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final spaces = await ref.read(residenceContextProvider.future);
    if (!mounted ||
        ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
      return;
    }
    final repository = ref.read(professionalProfileRepositoryProvider);
    if (spaces.professionalServiceId != null) {
      await repository.activate(user);
      if (!mounted ||
          ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
        return;
      }
      refreshProfessionalSpace(
        ProviderScope.containerOf(context, listen: false),
        user,
      );
      context.go(AppRoutes.professional);
      return;
    }
    final candidates = await repository.discover(user);
    if (!mounted ||
        ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
      return;
    }
    if (candidates.isEmpty) {
      context.replace(AppRoutes.createProfessional);
      return;
    }
    setState(() => _claimOpen = true);
    final claimed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ClaimDialog(user: user, candidates: candidates),
    );
    if (!mounted ||
        ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
      return;
    }
    if (claimed == true) {
      context.go(AppRoutes.professional);
    } else {
      _back();
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.residenceSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DarJarSetupScaffold(
      onBack: _back,
      child: FutureBuilder(
        future: _enrollment,
        builder: (context, snapshot) {
          if (_claimOpen) return const SizedBox.shrink();
          final error = snapshot.error;
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is DirectoryFailure &&
                              error.code == 'directory-phone-exists'
                          ? l10n.professionalPhoneInUse
                          : l10n.professionalProfileUnavailable,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    DarJarButton(
                      label: l10n.accountResolutionRetry,
                      onPressed: () {
                        ref.invalidate(residenceContextProvider);
                        setState(() => _enrollment = _load());
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _ClaimDialog extends ConsumerStatefulWidget {
  const _ClaimDialog({required this.user, required this.candidates});

  final AuthUser user;
  final List<ProfessionalCandidate> candidates;

  @override
  ConsumerState<_ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends ConsumerState<_ClaimDialog> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String? _selection;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(professionalAccountProfileProvider(widget.user));
    final categories =
        ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final selection =
        _selection ??
        (widget.candidates.length == 1 ? widget.candidates.single.id : null);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        key: const Key('professional-claim-dialog'),
        title: Text(l10n.claimProfessionalTitle),
        scrollable: true,
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.claimProfessionalDescription),
              const SizedBox(height: AppSpacing.medium),
              if (widget.candidates.length > 1)
                Text(l10n.claimProfessionalMultiple),
              for (final candidate in widget.candidates)
                ListTile(
                  leading: Icon(
                    selection == candidate.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(candidate.name),
                  subtitle: Text(
                    candidate.profession.trim().isNotEmpty
                        ? candidate.profession
                        : categories
                                  .where(
                                    (category) =>
                                        category.id == candidate.categoryId,
                                  )
                                  .firstOrNull
                                  ?.localizedLongName(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ) ??
                              candidate.categoryId,
                  ),
                  selected: selection == candidate.id,
                  onTap: _saving
                      ? null
                      : () => setState(() => _selection = candidate.id),
                ),
              if (profile.isLoading || _saving) const LinearProgressIndicator(),
              if (profile.hasError)
                TextButton(
                  onPressed: () => ref.invalidate(
                    professionalAccountProfileProvider(widget.user),
                  ),
                  child: Text(l10n.accountResolutionRetry),
                ),
              if (profile.hasValue && profile.value == null)
                ProfessionalPersonalNameFields(
                  firstName: _firstName,
                  lastName: _lastName,
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.professionalNotNow),
          ),
          FilledButton(
            onPressed:
                selection == null ||
                    _saving ||
                    profile.isLoading ||
                    profile.hasError
                ? null
                : () => _claim(selection, profile.value == null),
            child: Text(l10n.claimProfessionalAction),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(String id, bool needsName) async {
    final l10n = AppLocalizations.of(context);
    final name = (
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
    );
    if (needsName && (name.firstName.isEmpty || name.lastName.isEmpty)) {
      setState(() => _error = l10n.accountResolutionMissingProfile);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(professionalProfileRepositoryProvider)
          .claim(widget.user, id, needsName ? name : null);
      if (!mounted ||
          ref.read(authRepositoryProvider).currentUser?.uid !=
              widget.user.uid) {
        return;
      }
      refreshProfessionalSpace(
        ProviderScope.containerOf(context, listen: false),
        widget.user,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            error is DirectoryFailure &&
                [
                  'already-owns-service',
                  'service-not-claimable',
                ].contains(error.code)
            ? l10n.professionalClaimUnavailable
            : l10n.accountResolutionUnexpectedError;
      });
    }
  }
}

class ProfessionalPersonalNameFields extends StatelessWidget {
  const ProfessionalPersonalNameFields({
    required this.firstName,
    required this.lastName,
    super.key,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.large),
        DarJarTextField(
          key: const Key('professional-first-name'),
          controller: firstName,
          label: l10n.firstName,
          hint: l10n.firstNameHint,
        ),
        const SizedBox(height: AppSpacing.medium),
        DarJarTextField(
          key: const Key('professional-last-name'),
          controller: lastName,
          label: l10n.lastName,
          hint: l10n.lastNameHint,
          helper: l10n.lastNamePrivacyHint,
        ),
      ],
    );
  }
}
