import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/professional_profile_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/directory/presentation/create_service_page.dart';
import 'package:darjar/features/directory/presentation/directory_entry_image.dart';
import 'package:darjar/features/directory/presentation/directory_profile_page.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:darjar/features/shell/presentation/darjar_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ProfessionalWorkspaceView { manage, edit, preview }

class ProfessionalWorkspace extends ConsumerWidget {
  const ProfessionalWorkspace({
    this.view = ProfessionalWorkspaceView.manage,
    super.key,
  });

  final ProfessionalWorkspaceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaces = ref.watch(residenceContextProvider);
    if (spaces.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (spaces.hasError) {
      return Scaffold(
        body: Center(
          child: DarJarButton(
            label: l10n.accountResolutionRetry,
            onPressed: () => ref.invalidate(residenceContextProvider),
          ),
        ),
      );
    }
    final selection = spaces.requireValue;
    final id = selection.activeProfessionalId;
    if (id == null) {
      final destination = selection.activeResidence == null
          ? AppRoutes.residenceSetup
          : AppRoutes.community;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final router = GoRouter.of(context);
        final path = router.routeInformationProvider.value.uri.path;
        if (path == AppRoutes.professional ||
            path == AppRoutes.editProfessional ||
            path == AppRoutes.previewProfessional) {
          router.go(destination);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entry = ref.watch(professionalEntryProvider(id));
    final user = ref.watch(authRepositoryProvider).currentUser;
    return DarJarProfessionalShell(
      key: const Key('professional-workspace'),
      residenceContext: selection,
      child: entry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: DarJarButton(
            label: l10n.accountResolutionRetry,
            onPressed: () => ref.invalidate(professionalEntryProvider(id)),
          ),
        ),
        data: (listing) {
          if (listing == null || !listing.isOwnedBy(user?.uid)) {
            return Center(child: Text(l10n.professionalProfileUnavailable));
          }
          if (view == ProfessionalWorkspaceView.edit) {
            return CreateServicePage(
              key: ValueKey(id),
              entryId: id,
              professional: true,
            );
          }
          final recommendations = ref.watch(
            professionalRecommendationsProvider(id),
          );
          return recommendations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: DarJarButton(
                label: l10n.accountResolutionRetry,
                onPressed: () =>
                    ref.invalidate(professionalRecommendationsProvider(id)),
              ),
            ),
            data: (recommendations) {
              final profile = mergeDirectoryRecommendations(
                listing,
                recommendations,
              );
              return view == ProfessionalWorkspaceView.preview
                  ? DirectoryProfilePage(entryId: id, preview: profile)
                  : _WorkspaceContent(entry: profile);
            },
          );
        },
      ),
    );
  }
}

enum _ServiceAction { pause, resume, delete }

class _WorkspaceContent extends ConsumerStatefulWidget {
  const _WorkspaceContent({required this.entry});

  final DirectoryEntry entry;

  @override
  ConsumerState<_WorkspaceContent> createState() => _WorkspaceContentState();
}

class _WorkspaceContentState extends ConsumerState<_WorkspaceContent> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final categories =
        ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final category = categories
        .where((category) => category.id == entry.categoryId)
        .firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DirectoryEntryImage(entry: entry, radius: 28),
                        if (entry.isPaused)
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: DarJarBadge(
                                label: l10n.professionalActivityPaused,
                                tone: DarJarBadgeTone.warning,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        PopupMenuButton<_ServiceAction>(
                          key: const Key('professional-service-options'),
                          tooltip: l10n.professionalServiceOptions,
                          icon: _updating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.more_vert_rounded),
                          enabled: !_updating,
                          onSelected: _applyAction,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              key: const Key(
                                'professional-service-availability',
                              ),
                              value: entry.isPaused
                                  ? _ServiceAction.resume
                                  : _ServiceAction.pause,
                              child: Text(
                                entry.isPaused
                                    ? l10n.professionalResumeActivity
                                    : l10n.professionalPauseActivity,
                              ),
                            ),
                            if (!entry.hasFeedback)
                              PopupMenuItem(
                                key: const Key(
                                  'delete-professional-service-button',
                                ),
                                value: _ServiceAction.delete,
                                child: Text(l10n.professionalDeleteService),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      entry.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (category != null)
                      Text(category.localizedLongName(language)),
                    Text(localizedMoroccanCityName(l10n, entry.city)),
                    DarJarPhoneNumber(entry.phone),
                    if (entry.profession.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.medium),
                      Text(entry.profession),
                    ],
                    if (category != null) ...[
                      const SizedBox(height: AppSpacing.medium),
                      Wrap(
                        spacing: AppSpacing.small,
                        children: [
                          for (final service in category.subcategories)
                            if (entry.subcategoryIds.contains(service.id))
                              Chip(
                                label: Text(service.localizedName(language)),
                              ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.large),
                    Wrap(
                      spacing: AppSpacing.medium,
                      runSpacing: AppSpacing.small,
                      children: [
                        DarJarButton(
                          label: l10n.editService,
                          icon: Icons.edit_outlined,
                          onPressed: _updating
                              ? null
                              : () => context.push(AppRoutes.editProfessional),
                        ),
                        DarJarButton(
                          label: l10n.professionalPreview,
                          icon: Icons.visibility_outlined,
                          variant: DarJarButtonVariant.secondary,
                          onPressed: _updating
                              ? null
                              : () =>
                                    context.push(AppRoutes.previewProfessional),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recentReviews,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      '${l10n.recommendations}  ${entry.recommendationCount}',
                    ),
                    if (entry.score > 0)
                      Text('${l10n.recommendationScore}  ${entry.score}'),
                    if (entry.reviews.isEmpty) Text(l10n.noReviewsYet),
                    for (final review in entry.reviews) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(review.author),
                        subtitle: Text(review.comment),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyAction(_ServiceAction action) async {
    if (_updating) return;
    final entry = widget.entry;
    final l10n = AppLocalizations.of(context);
    final deleting = action == _ServiceAction.delete;
    if (action != _ServiceAction.resume) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            deleting
                ? l10n.professionalDeleteTitle
                : l10n.professionalPauseTitle,
          ),
          content: Text(
            deleting
                ? l10n.professionalDeleteDescription(entry.name)
                : l10n.professionalPauseDescription,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: Key(
                deleting
                    ? 'confirm-delete-professional-service-button'
                    : 'confirm-pause-professional-service-button',
              ),
              style: deleting
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                deleting ? l10n.delete : l10n.professionalPauseActivity,
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || _updating) return;
    }

    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    if (user == null || !entry.isOwnedBy(user.uid)) return;

    // The listing may disappear from its stream before the delete response.
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final repository = container.read(professionalProfileRepositoryProvider);
    setState(() => _updating = true);
    try {
      if (deleting) {
        await repository.delete(user, entry.id);
      } else {
        await repository.setPaused(
          user,
          entry.id,
          paused: action == _ServiceAction.pause,
        );
      }
      if (!messenger.mounted || auth.currentUser?.uid != user.uid) return;
      if (deleting) refreshProfessionalSpace(container, user);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (action) {
            _ServiceAction.delete => l10n.professionalServiceDeleted,
            _ServiceAction.pause => l10n.professionalServicePaused,
            _ServiceAction.resume => l10n.professionalServiceResumed,
          }),
        ),
      );
    } catch (error) {
      if (!messenger.mounted || auth.currentUser?.uid != user.uid) return;
      final hasFeedback =
          error is DirectoryFailure && error.code == 'service-has-feedback';
      if (hasFeedback) {
        container.invalidate(professionalRecommendationsProvider(entry.id));
      }
      if (deleting && !mounted) refreshProfessionalSpace(container, user);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hasFeedback
                ? l10n.professionalServiceHasFeedback
                : deleting
                ? l10n.professionalServiceDeleteFailed
                : l10n.professionalAvailabilityUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}
