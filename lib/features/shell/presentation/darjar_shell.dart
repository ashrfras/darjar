import 'dart:math' as math;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_theme_refresh_boundary.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/professional_profile_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/directory/presentation/directory_entry_image.dart';
import 'package:darjar/features/notifications/data/notification_push_service.dart';
import 'package:darjar/features/notifications/data/notifications_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_deletion_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_progress_provider.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_visibility.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:darjar/features/shell/data/residence_data_warmup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DarJarShell extends ConsumerWidget {
  const DarJarShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residenceContext = ref.watch(residenceContextProvider);
    return DarJarThemeRefreshBoundary(
      builder: (context) => residenceContext.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      AppLocalizations.of(context).residenceContextLoadError,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    SelectableText(
                      _residenceContextErrorDetails(error),
                      key: const Key('residence-context-error-details'),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.danger,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(residenceContextProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        AppLocalizations.of(context).accountResolutionRetry,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        data: (data) {
          if (data.activeProfessionalId != null) {
            if (location == AppRoutes.profile ||
                location.startsWith('/profile/') ||
                location == AppRoutes.settings ||
                location == AppRoutes.appActivityLog) {
              return DarJarProfessionalShell(
                residenceContext: data,
                child: child,
              );
            }
            return _ShellRedirect(AppRoutes.professional, source: location);
          }
          final residence = data.activeResidence;
          if (residence == null) {
            return _ShellRedirect(AppRoutes.residenceSetup, source: location);
          }
          final deletion = residence.canManageApartmentsAndResidents
              ? null
              : ref.watch(activeResidenceDeletionProvider);
          final redirect = _administrationRedirect(residence, deletion);
          if (redirect != null) {
            return _ShellRedirect(
              redirect,
              source: location,
              key: ValueKey(redirect),
            );
          }
          ref.watch(residenceDataWarmupProvider(residence.id));
          return _buildShell(
            context,
            data,
            showAdministration:
                residence.canManageApartmentsAndResidents ||
                deletion?.value != null,
          );
        },
      ),
    );
  }

  String _residenceContextErrorDetails(Object error) {
    return switch (error) {
      ResidenceContextFailure(:final code, :final details) =>
        details == null || details.isEmpty ? code : '$code\n$details',
      _ => error.toString(),
    };
  }

  String? _administrationRedirect(
    UserResidence residence,
    AsyncValue<ResidenceDeletionTarget?>? deletion,
  ) {
    if (!AppRoutes.isAdministrationPath(location)) return null;
    if (!residence.canManageApartmentsAndResidents) {
      if (location == AppRoutes.administration &&
          (deletion?.isLoading == true || deletion?.value != null)) {
        return null;
      }
      return deletion?.value != null
          ? AppRoutes.administration
          : AppRoutes.community;
    }
    if (residence.canManageResidence ||
        location == AppRoutes.administration ||
        location == AppRoutes.manageResidence ||
        location == AppRoutes.appointResidencePresident ||
        location == AppRoutes.manageApartments ||
        location == AppRoutes.groupInvitation) {
      return null;
    }
    return AppRoutes.administration;
  }

  Widget _buildShell(
    BuildContext context,
    ResidenceContext residenceContext, {
    required bool showAdministration,
  }) {
    final localizations = AppLocalizations.of(context);
    final destinations = _destinations(
      localizations,
      showAdministration: showAdministration,
    );
    final selectedPath = AppRoutes.isAdministrationPath(location)
        ? AppRoutes.administration
        : location;
    final selectedIndex = destinations.indexWhere(
      (destination) => selectedPath.startsWith(destination.path),
    );

    final page = residenceContext.supportResidence != null
        ? Column(
            children: [
              const _SupportModeBanner(),
              Expanded(child: child),
            ],
          )
        : child;

    return _SpaceScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      residenceContext: residenceContext,
      child: page,
    );
  }
}

class DarJarProfessionalShell extends StatelessWidget {
  const DarJarProfessionalShell({
    required this.residenceContext,
    required this.child,
    super.key,
  });

  final ResidenceContext residenceContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SpaceScaffold(
      destinations: const [],
      selectedIndex: -1,
      residenceContext: residenceContext,
      child: SafeArea(top: false, child: child),
    );
  }
}

class _SpaceScaffold extends StatelessWidget {
  const _SpaceScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.residenceContext,
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ResidenceContext residenceContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizeClass) => switch (sizeClass) {
        WindowSizeClass.compact => _CompactShell(
          destinations: destinations,
          selectedIndex: math.max(selectedIndex, 0),
          residenceContext: residenceContext,
          child: child,
        ),
        WindowSizeClass.medium => _MediumShell(
          destinations: destinations,
          selectedIndex: selectedIndex,
          residenceContext: residenceContext,
          child: child,
        ),
        WindowSizeClass.expanded => _ExpandedShell(
          destinations: destinations,
          selectedIndex: selectedIndex,
          residenceContext: residenceContext,
          child: child,
        ),
      },
    );
  }
}

class _SupportModeBanner extends ConsumerWidget {
  const _SupportModeBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      key: const Key('residence-support-banner'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.large,
          end: AppSpacing.small,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                strings.appActivitySupportMode,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(residenceSupportProvider.notifier).close();
                context.go(AppRoutes.appActivityLog);
              },
              child: Text(strings.appActivityExitSupport),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.destinations,
    required this.selectedIndex,
    required this.residenceContext,
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ResidenceContext residenceContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('compact-shell'),
      appBar: AppBar(
        toolbarHeight: 58,
        titleSpacing: 0,
        leadingWidth: 238,
        leading: _CompactIdentity(residenceContext),
        title: const SizedBox.shrink(),
        actions: [
          if (destinations.isNotEmpty) _NotificationsAction(compact: true),
          _ProfileAction(compact: true),
          const SizedBox(width: 6),
        ],
      ),
      body: child,
      bottomNavigationBar: destinations.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }
}

class _MediumShell extends StatelessWidget {
  const _MediumShell({
    required this.destinations,
    required this.selectedIndex,
    required this.residenceContext,
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ResidenceContext residenceContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('medium-shell'),
      appBar: AppBar(
        title: Row(
          children: [
            _Brand(residenceContext, compact: true),
            const SizedBox(width: AppSpacing.large),
            Flexible(child: SpaceSelector(residenceContext)),
          ],
        ),
        actions: [
          if (destinations.isNotEmpty) const _NotificationsAction(),
          _ProfileAction(),
          const SizedBox(width: AppSpacing.large),
        ],
      ),
      body: destinations.isEmpty
          ? child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                  onDestinationSelected: (index) =>
                      context.go(destinations[index].path),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(),
                Expanded(child: child),
              ],
            ),
    );
  }
}

class _ExpandedShell extends StatelessWidget {
  const _ExpandedShell({
    required this.destinations,
    required this.selectedIndex,
    required this.residenceContext,
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ResidenceContext residenceContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('expanded-shell'),
      body: Row(
        children: [
          Container(
            width: 280,
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppSpacing.xLarge),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(residenceContext),
                  const SizedBox(height: AppSpacing.xxLarge),
                  SpaceSelector(residenceContext, expanded: true),
                  const SizedBox(height: AppSpacing.xLarge),
                  for (var index = 0; index < destinations.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.small),
                      child: _SidebarDestination(
                        destination: destinations[index],
                        selected: index == selectedIndex,
                        onTap: () => context.go(destinations[index].path),
                      ),
                    ),
                  const Spacer(),
                  if (destinations.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizations.notifications,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const _NotificationsAction(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      key: const Key('profile-button'),
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(localizations.profile),
                      selected:
                          GoRouterState.of(context).uri.path ==
                          AppRoutes.profile,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      onTap: () => context.push(AppRoutes.profile),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? destination.color.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: ListTile(
        leading: Icon(
          selected ? destination.selectedIcon : destination.icon,
          color: selected ? destination.color : AppColors.inkMuted,
        ),
        title: Text(
          destination.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? destination.color : AppColors.ink,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand(this.residenceContext, {this.compact = false});

  final ResidenceContext residenceContext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoAsset = compact
        ? 'assets/images/branding/darjar-logo-header-compact.png'
        : 'assets/images/branding/darjar-logo-header.png';

    return MouseRegion(
      key: const Key('brand-home-pointer'),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const Key('brand-home-button'),
        onTap: () => context.go(
          residenceContext.activeProfessionalId == null
              ? AppRoutes.community
              : AppRoutes.professional,
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            DarJarLogo(
              asset: logoAsset,
              size: compact ? 31 : 38,
              imageKey: compact ? const Key('compact-brand') : null,
            ),
            SizedBox(width: compact ? AppSpacing.small : AppSpacing.medium),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دارجار',
                  style: AppTypography.brandArabic.copyWith(
                    color: AppColors.ink,
                    fontSize: compact ? 16 : null,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    'DarJar',
                    style: AppTypography.brandLatin.copyWith(
                      color: AppColors.inkMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsAction extends ConsumerWidget {
  const _NotificationsAction({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final setupReminderUnread = ref.watch(
      residenceSetupReminderProvider.select(
        (reminder) => reminder?.isUnread ?? false,
      ),
    );
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider) +
        (setupReminderUnread ? 1 : 0);
    return IconButton(
      key: const Key('notifications-button'),
      tooltip: localizations.notifications,
      onPressed: () => _showNotifications(context),
      iconSize: compact ? 21 : 24,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: SizedBox.square(
        dimension: 28,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded),
            if (unreadCount > 0)
              PositionedDirectional(
                key: const Key('notifications-unread-badge-position'),
                top: -4,
                end: -5,
                child: Badge(
                  key: const Key('notifications-unread-badge'),
                  label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                  backgroundColor: AppColors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => const _NotificationsSheet(),
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  static const previewLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsProvider);
    final setupReminder = ref.watch(residenceSetupReminderProvider);
    final unreadSetupReminder = setupReminder?.isUnread == true
        ? setupReminder
        : null;
    final hasUnreadNotifications =
        notifications.value?.any((notification) => !notification.isRead) ??
        false;
    final now = ref.watch(notificationTimeNowProvider);
    final apartmentNotAssigned = ref.watch(
      residenceContextProvider.select(
        (state) => state.value?.activeResidence?.apartmentId.isEmpty ?? false,
      ),
    );

    return Material(
      key: const Key('notifications-sheet'),
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          AppSpacing.small,
          AppSpacing.xLarge,
          AppSpacing.xLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.notifications,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  key: const Key('mark-notifications-read-button'),
                  onPressed:
                      hasUnreadNotifications || unreadSetupReminder != null
                      ? () async {
                          if (unreadSetupReminder != null) {
                            await _setSetupVisibility(
                              context,
                              ref,
                              unreadSetupReminder.scope,
                              ResidenceSetupVisibility.hiddenRead,
                            );
                          }
                          if (hasUnreadNotifications && context.mounted) {
                            await ref
                                .read(notificationActionsProvider)
                                .markAllRead();
                          }
                        }
                      : null,
                  child: Text(localizations.markAllNotificationsRead),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            if (setupReminder != null) ...[
              ListTile(
                key: const Key('residence-setup-reminder-notification'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.fact_check_outlined),
                ),
                title: Text(
                  localizations.setupChecklistHiddenNotificationTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                  child: Text(
                    localizations.setupChecklistHiddenNotificationBody,
                  ),
                ),
                trailing: setupReminder.isUnread
                    ? const Badge(
                        smallSize: 8,
                        backgroundColor: AppColors.warning,
                      )
                    : null,
                onTap: () async {
                  final restored = await _setSetupVisibility(
                    context,
                    ref,
                    setupReminder.scope,
                    ResidenceSetupVisibility.visible,
                  );
                  if (!context.mounted ||
                      !restored ||
                      ref.read(residenceSetupScopeProvider) !=
                          setupReminder.scope) {
                    return;
                  }
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.go(AppRoutes.community);
                },
              ),
              if (apartmentNotAssigned ||
                  notifications.value?.isNotEmpty == true)
                const Divider(),
            ],
            if (apartmentNotAssigned) ...[
              ListTile(
                key: const Key('apartment-not-assigned-notification'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.warningSoft,
                  foregroundColor: AppColors.warning,
                  child: Icon(Icons.home_work_outlined),
                ),
                title: Text(
                  localizations.profileApartmentNotAssigned,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                  child: Text(localizations.duesNoApartment),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.residence);
                },
              ),
              const Divider(),
            ],
            notifications.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xLarge),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Text(localizations.notificationsLoadError),
              ),
              data: (items) {
                if (items.isEmpty) {
                  if (setupReminder != null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xLarge),
                    child: Text(
                      localizations.noNotifications,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final previewItems = items
                    .take(_NotificationsSheet.previewLimit)
                    .toList(growable: false);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var index = 0;
                      index < previewItems.length;
                      index++
                    ) ...[
                      _NotificationTile(
                        key: ValueKey('notification-${previewItems[index].id}'),
                        notification: previewItems[index],
                        now: now,
                        onTap: () => _openNotification(
                          context,
                          ref,
                          previewItems[index],
                        ),
                      ),
                      if (index < previewItems.length - 1) const Divider(),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _setSetupVisibility(
    BuildContext context,
    WidgetRef ref,
    ResidenceSetupScope scope,
    ResidenceSetupVisibility visibility,
  ) async {
    try {
      return await ref
          .read(residenceSetupVisibilityProvider(scope).notifier)
          .setVisibility(visibility);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).communityActionFailed),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    DarJarNotification notification,
  ) async {
    await ref.read(notificationActionsProvider).markRead(notification.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.push(notificationRoute(notification));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.now,
    required this.onTap,
    super.key,
  });

  final DarJarNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (icon, color, title, body) = switch (notification.type) {
      DarJarNotificationType.residentJoined => (
        Icons.person_add_alt_1_outlined,
        AppColors.primary,
        localizations.residentJoinedNotificationTitle,
        localizations.residentJoinedNotificationBody(
          abbreviatedPersonName(notification.actorName),
        ),
      ),
      DarJarNotificationType.postCreated => (
        Icons.article_outlined,
        AppColors.residence,
        localizations.newPostNotificationTitle,
        localizations.newPostNotificationBody(
          abbreviatedPersonName(notification.actorName),
        ),
      ),
      DarJarNotificationType.postLiked => (
        Icons.favorite_outline,
        AppColors.warning,
        localizations.postLikedNotificationTitle,
        localizations.postLikedNotificationBody(
          abbreviatedPersonName(notification.actorName),
        ),
      ),
      DarJarNotificationType.postCommented => (
        Icons.chat_bubble_outline_rounded,
        AppColors.residence,
        localizations.postCommentedNotificationTitle,
        localizations.postCommentedNotificationBody(
          abbreviatedPersonName(notification.actorName),
        ),
      ),
      DarJarNotificationType.duesOverdue => (
        Icons.receipt_long_outlined,
        AppColors.warning,
        localizations.duesOverdueNotificationTitle,
        localizations.duesOverdueNotificationBody(notification.periodKey),
      ),
      DarJarNotificationType.duesMarkedPaid => (
        Icons.check_circle_outline_rounded,
        AppColors.primary,
        localizations.duesMarkedPaidNotificationTitle,
        localizations.duesMarkedPaidNotificationBody(notification.periodKey),
      ),
      DarJarNotificationType.paymentRecorded => (
        Icons.check_circle_outline_rounded,
        AppColors.primary,
        localizations.paymentRecordedNotificationTitle,
        switch (notification.amount) {
          final int amount => localizations.paymentRecordedNotificationBody(
            amount.toString(),
          ),
          null => '',
        },
      ),
      DarJarNotificationType.budgetChanged => (
        Icons.account_balance_wallet_outlined,
        AppColors.primary,
        localizations.budgetChangedNotificationTitle,
        localizations.budgetChangedNotificationBody,
      ),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: AppColors.surface,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          if (!notification.isRead)
            PositionedDirectional(
              top: 0,
              start: -2,
              child: Container(
                key: ValueKey('notification-unread-${notification.id}'),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xSmall),
        child: Text(body),
      ),
      trailing: Text(
        _notificationTime(localizations, notification.occurredAt, now),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
      ),
      onTap: onTap,
    );
  }
}

final notificationTimeNowProvider = Provider<DateTime>((ref) => DateTime.now());

String _notificationTime(
  AppLocalizations localizations,
  DateTime occurredAt,
  DateTime now,
) {
  final safeOccurredAt = occurredAt.isAfter(now) ? now : occurredAt;
  final today = DateTime(now.year, now.month, now.day);
  final occurredDay = DateTime(
    safeOccurredAt.year,
    safeOccurredAt.month,
    safeOccurredAt.day,
  );
  final elapsedDays = today.difference(occurredDay).inDays;
  if (elapsedDays == 1) return localizations.notificationTimeYesterday;
  if (elapsedDays > 1 && elapsedDays < 7) {
    return localizations.notificationTimeDays(elapsedDays);
  }
  if (elapsedDays >= 7) {
    return DarJarDateFormat.yMMMd(safeOccurredAt, localizations.localeName);
  }

  final elapsed = now.difference(safeOccurredAt);
  if (elapsed.inMinutes < 1) return localizations.notificationTimeNow;
  if (elapsed.inMinutes < 60) {
    return localizations.notificationTimeMinutes(elapsed.inMinutes);
  }
  return localizations.notificationTimeHours(elapsed.inHours);
}

class _ProfileAction extends ConsumerWidget {
  const _ProfileAction({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    return IconButton(
      key: const Key('profile-button'),
      tooltip: localizations.profile,
      onPressed: () => context.push(AppRoutes.profile),
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline),
        ),
        child: DarJarUserAvatar(
          userId: userId,
          radius: compact ? 15 : 18,
          backgroundColor: AppColors.directorySoft,
        ),
      ),
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity(this.residenceContext);

  final ResidenceContext residenceContext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: Row(
        children: [
          _Brand(residenceContext, compact: true),
          const SizedBox(width: 10),
          const SizedBox(height: 24, child: VerticalDivider()),
          const SizedBox(width: 8),
          Expanded(child: SpaceSelector(residenceContext, compact: true)),
        ],
      ),
    );
  }
}

class SpaceSelector extends ConsumerWidget {
  const SpaceSelector(
    this.residenceContext, {
    this.compact = false,
    this.expanded = false,
    super.key,
  });

  final ResidenceContext residenceContext;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = residenceContext.activeResidence;
    final id = residenceContext.professionalServiceId;
    final listing = id == null
        ? null
        : ref.watch(professionalEntryProvider(id)).value;
    final professional =
        listing?.isOwnedBy(
              ref.watch(authRepositoryProvider).currentUser?.uid,
            ) ==
            true
        ? listing
        : null;
    final localizations = AppLocalizations.of(context);
    return Material(
      key: const Key('residence-selector'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: () => _showResidenceSwitcher(context, ref, professional),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        child: Container(
          padding: expanded
              ? const EdgeInsets.all(AppSpacing.large)
              : const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                  vertical: AppSpacing.xSmall,
                ),
          decoration: expanded
              ? BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                )
              : null,
          child: Row(
            key: compact ? const Key('compact-residence') : null,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expanded && active != null) ...[
                DarJarResidenceAvatar(
                  residenceId: active.id,
                  hasImage: active.hasImage,
                  size: 42,
                ),
                const SizedBox(width: AppSpacing.medium),
              ] else if (expanded && professional != null) ...[
                DirectoryEntryImage(entry: professional, radius: 21),
                const SizedBox(width: AppSpacing.medium),
              ],
              Flexible(
                child: Text(
                  active == null
                      ? professional?.name ?? localizations.selectSpace
                      : localizations.residenceDisplayName(
                          normalizeResidenceName(active.name),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: expanded
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.inkMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResidenceSwitcher(
    BuildContext context,
    WidgetRef ref,
    DirectoryEntry? professional,
  ) async {
    final selection =
        await showModalBottomSheet<({String id, bool professional})>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: AppColors.ink.withValues(alpha: 0.34),
          isScrollControlled: true,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 560),
          builder: (sheetContext) => _ResidenceSwitcherSheet(
            residenceContext: residenceContext,
            professional: professional,
            onNewResidence: () {
              Navigator.of(sheetContext).pop();
              context.go(
                AppRoutes.residenceSetup,
                extra: GoRouterState.of(context).uri.toString(),
              );
            },
          ),
        );
    if (selection == null || !context.mounted) return;
    if (!selection.professional) {
      await _selectResidence(context, ref, selection.id);
      return;
    }
    if (residenceContext.activeProfessionalId == selection.id) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      await ref.read(professionalProfileRepositoryProvider).activate(user);
      if (!context.mounted ||
          ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
        return;
      }
      if (residenceContext.supportResidence != null) {
        ref.read(residenceSupportProvider.notifier).close();
      }
      ref.refresh(residenceContextProvider.future).ignore();
      context.go(AppRoutes.professional);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).professionalProfileUnavailable,
          ),
        ),
      );
    }
  }

  Future<void> _selectResidence(
    BuildContext context,
    WidgetRef ref,
    String residenceId,
  ) async {
    if (residenceId == residenceContext.activeResidence?.id) {
      return;
    }
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      return;
    }
    final localizations = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final transition = OverlayEntry(
      builder: (context) =>
          _ResidenceSwitchingOverlay(label: localizations.switchingResidence),
    );
    overlay.insert(transition);
    final minimumVisibility = Future<void>.delayed(
      const Duration(milliseconds: 550),
    );
    try {
      await ref
          .read(residenceContextRepositoryProvider)
          .setActiveResidence(user: user, residenceId: residenceId);
      if (!context.mounted) return;
      if (residenceContext.supportResidence != null) {
        ref.read(residenceSupportProvider.notifier).close();
      }
      if (residenceContext.activeProfessionalId != null) {
        ref.refresh(residenceContextProvider.future).ignore();
        context.go(AppRoutes.community);
        return;
      }
      final updatedContext = await ref.refresh(residenceContextProvider.future);
      if (updatedContext.activeResidence == null) {
        throw StateError(
          'The refreshed residence context has no active residence.',
        );
      }
      await minimumVisibility;
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(localizations.accountResolutionUnexpectedError),
          ),
        );
    } finally {
      transition.remove();
    }
  }
}

class _ResidenceSwitchingOverlay extends StatelessWidget {
  const _ResidenceSwitchingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.34),
        child: AbsorbPointer(
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: label,
              child: Container(
                key: const Key('residence-switching-overlay'),
                constraints: const BoxConstraints(minWidth: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xLarge,
                  vertical: AppSpacing.large,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2417151D),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResidenceSwitcherSheet extends ConsumerWidget {
  const _ResidenceSwitcherSheet({
    required this.residenceContext,
    required this.onNewResidence,
    this.professional,
  });

  final ResidenceContext residenceContext;
  final VoidCallback onNewResidence;
  final DirectoryEntry? professional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final optionHeight = _ResidenceSwitcherOption.height(context);
    const visibleFullOptionCount = 3;
    final professional = this.professional;
    final categories = professional == null
        ? const <ServiceCategory>[]
        : ref.watch(serviceCategoriesProvider).value ??
              const <ServiceCategory>[];
    final specialty = professional == null
        ? ''
        : categories
                  .where((category) => category.id == professional.categoryId)
                  .firstOrNull
                  ?.localizedLongName(
                    Localizations.localeOf(context).languageCode,
                  ) ??
              professional.profession;
    const residenceGap = AppSpacing.xSmall;
    final support = residenceContext.supportResidence;
    final residences = [
      if (support != null &&
          !residenceContext.residences.any(
            (residence) => residence.id == support.id,
          ))
        support,
      ...residenceContext.residences,
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: DecoratedBox(
        key: const Key('residence-switcher-sheet'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2417151D),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          (visibleFullOptionCount + 0.5) * optionHeight +
                          visibleFullOptionCount * residenceGap,
                    ),
                    child: ListView.separated(
                      key: const Key('residence-switcher-list'),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount:
                          residences.length + (professional == null ? 0 : 1),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: residenceGap),
                      itemBuilder: (context, index) {
                        if (professional != null &&
                            index == residences.length) {
                          return SizedBox(
                            height: optionHeight,
                            child: _ResidenceSwitcherOption(
                              key: ValueKey(
                                'professional-switcher-option-${professional.id}',
                              ),
                              title: professional.name,
                              subtitle: [
                                specialty,
                                localizedMoroccanCityName(
                                  localizations,
                                  professional.city,
                                ),
                              ].where((value) => value.isNotEmpty).join(' • '),
                              avatar: DirectoryEntryImage(
                                entry: professional,
                                radius: 22,
                              ),
                              selected:
                                  residenceContext.activeProfessionalId ==
                                  professional.id,
                              activeLabel: localizations.currentSpace,
                              onTap: () => Navigator.of(
                                context,
                              ).pop((id: professional.id, professional: true)),
                            ),
                          );
                        }
                        final residence = residences[index];
                        return SizedBox(
                          height: optionHeight,
                          child: _ResidenceSwitcherOption(
                            key: ValueKey(
                              'residence-switcher-option-${residence.id}',
                            ),
                            title: localizations.residenceDisplayName(
                              normalizeResidenceName(residence.name),
                            ),
                            subtitle: [
                              residence.address,
                              localizedMoroccanCityName(
                                localizations,
                                residence.city,
                              ),
                            ].where((value) => value.isNotEmpty).join(' • '),
                            avatar: DarJarResidenceAvatar(
                              residenceId: residence.id,
                              hasImage: residence.hasImage,
                              size: 44,
                            ),
                            selected:
                                residence.id ==
                                residenceContext.activeResidence?.id,
                            activeLabel: localizations.currentResidence,
                            onTap: () => Navigator.of(
                              context,
                            ).pop((id: residence.id, professional: false)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                DarJarCard(
                  key: const Key('residence-switcher-new-residence'),
                  padding: const EdgeInsets.all(AppSpacing.large),
                  onTap: onNewResidence,
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          Icons.add_home_work_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.addSpace,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(
                              localizations.addSpaceDescription,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.inkMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResidenceSwitcherOption extends StatelessWidget {
  const _ResidenceSwitcherOption({
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.activeLabel,
    required this.selected,
    super.key,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget avatar;
  final String activeLabel;
  final bool selected;
  final VoidCallback onTap;

  static const _avatarSize = 44.0;
  static const _titleMaxLines = 2;
  static const _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.large,
    vertical: AppSpacing.xSmall,
  );

  static double height(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final title = textTheme.titleMedium!;
    final address = textTheme.bodySmall!;
    final titleHeight =
        _titleMaxLines *
        textScaler.scale(title.fontSize!) *
        (title.height ?? 1);
    final addressHeight =
        textScaler.scale(address.fontSize!) * (address.height ?? 1);
    return _padding.vertical +
        math.max(
          _avatarSize,
          titleHeight.ceilToDouble() +
              AppSpacing.xSmall +
              addressHeight.ceilToDouble(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: _padding,
        color: selected ? AppColors.primarySoft : AppColors.surface,
        child: Row(
          children: [
            avatar,
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: selected ? AppColors.primary : AppColors.inkMuted,
              size: selected ? 24 : 16,
              semanticLabel: selected ? activeLabel : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellRedirect extends StatefulWidget {
  const _ShellRedirect(this.destination, {required this.source, super.key});

  final String destination;
  final String source;

  @override
  State<_ShellRedirect> createState() => _ShellRedirectState();
}

class _ShellRedirectState extends State<_ShellRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      if (router.routeInformationProvider.value.uri.path == widget.source) {
        router.go(widget.destination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
}

List<_ShellDestination> _destinations(
  AppLocalizations localizations, {
  required bool showAdministration,
}) {
  return [
    _ShellDestination(
      label: localizations.community,
      path: AppRoutes.community,
      icon: Icons.dynamic_feed_outlined,
      selectedIcon: Icons.dynamic_feed_rounded,
      color: AppColors.community,
    ),
    _ShellDestination(
      label: localizations.directory,
      path: AppRoutes.directory,
      icon: Icons.home_repair_service_outlined,
      selectedIcon: Icons.home_repair_service_rounded,
      color: AppColors.directory,
    ),
    _ShellDestination(
      label: localizations.residence,
      path: AppRoutes.residence,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      color: AppColors.residence,
    ),
    if (showAdministration)
      _ShellDestination(
        label: localizations.residenceAdministration,
        path: AppRoutes.administration,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        color: AppColors.primary,
      ),
  ];
}
