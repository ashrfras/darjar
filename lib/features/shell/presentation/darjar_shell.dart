import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
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
    return residenceContext.when(
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
        if (data.activeResidence == null) {
          return const _ResidenceSetupRedirect();
        }
        return _buildShell(context, data);
      },
    );
  }

  String _residenceContextErrorDetails(Object error) {
    return switch (error) {
      ResidenceContextFailure(:final code, :final details) =>
        details == null || details.isEmpty ? code : '$code\n$details',
      _ => error.toString(),
    };
  }

  Widget _buildShell(BuildContext context, ResidenceContext residenceContext) {
    final localizations = AppLocalizations.of(context);
    final destinations = _destinations(localizations);
    final selectedIndex = destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );

    return ResponsiveBuilder(
      builder: (context, sizeClass) {
        return switch (sizeClass) {
          WindowSizeClass.compact => _CompactShell(
            destinations: destinations,
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
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
        };
      },
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
        leadingWidth: 218,
        leading: _CompactIdentity(residenceContext),
        title: const SizedBox.shrink(),
        actions: [
          _NotificationsAction(
            compact: true,
            invitationCount: residenceContext.invitations.length,
          ),
          _ProfileAction(compact: true),
          const SizedBox(width: 6),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(destinations[index].path),
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
            const _Brand(compact: true),
            const SizedBox(width: AppSpacing.large),
            Flexible(child: _ResidenceSelector(residenceContext)),
          ],
        ),
        actions: [
          _NotificationsAction(
            invitationCount: residenceContext.invitations.length,
          ),
          _ProfileAction(),
          const SizedBox(width: AppSpacing.large),
        ],
      ),
      body: Row(
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
                  const _Brand(),
                  const SizedBox(height: AppSpacing.xxLarge),
                  _ResidenceSelector(residenceContext, expanded: true),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.notifications,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      _NotificationsAction(
                        invitationCount: residenceContext.invitations.length,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
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
                      onTap: () => context.go(AppRoutes.profile),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      key: const Key('gallery-button'),
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(localizations.componentGallery),
                      selected: locationIsGallery(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      onTap: () => context.go(AppRoutes.gallery),
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

  bool locationIsGallery(BuildContext context) {
    return GoRouterState.of(context).uri.path == AppRoutes.gallery;
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
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Image.asset(
          'assets/images/branding/darjar-logo.png',
          key: compact ? const Key('compact-brand') : null,
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          semanticLabel: 'DarJar',
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
    );
  }
}

class _NotificationsAction extends StatelessWidget {
  const _NotificationsAction({
    required this.invitationCount,
    this.compact = false,
  });

  final bool compact;
  final int invitationCount;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return IconButton(
      key: const Key('notifications-button'),
      tooltip: localizations.notifications,
      onPressed: () => _showNotifications(context),
      iconSize: compact ? 21 : 24,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Badge(
        isLabelVisible: invitationCount > 0,
        label: invitationCount > 0 ? Text('$invitationCount') : null,
        smallSize: 7,
        offset: Offset(1, -1),
        backgroundColor: AppColors.warning,
        child: const Icon(Icons.notifications_none_rounded),
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

class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();

  @override
  ConsumerState<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
  String? _acceptingPath;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final invitations =
        ref.watch(residenceContextProvider).value?.invitations ??
        const <ResidenceInvitation>[];
    final notifications = [
      (
        icon: Icons.water_drop_outlined,
        color: AppColors.residence,
        title: localizations.waterInterruptionNotificationTitle,
        body: localizations.waterInterruptionNotificationBody,
        time: localizations.notificationTimeMinutes,
      ),
      (
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
        title: localizations.duesReminderNotificationTitle,
        body: localizations.duesReminderNotificationBody,
        time: localizations.notificationTimeHours,
      ),
      (
        icon: Icons.engineering_outlined,
        color: AppColors.warning,
        title: localizations.maintenanceNotificationTitle,
        body: localizations.maintenanceNotificationBody,
        time: localizations.notificationTimeYesterday,
      ),
    ];

    return Material(
      key: const Key('notifications-sheet'),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations.markAllNotificationsRead),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            for (final invitation in invitations) ...[
              ListTile(
                key: ValueKey('in-app-invitation-${invitation.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.mark_email_unread_outlined),
                ),
                title: Text(
                  localizations.residenceDisplayName(
                    normalizeResidenceName(invitation.residenceName),
                  ),
                ),
                subtitle: Text(
                  invitation.residenceAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: FilledButton(
                  key: ValueKey('accept-in-app-invitation-${invitation.id}'),
                  onPressed: _acceptingPath == null
                      ? () => _acceptInvitation(invitation)
                      : null,
                  child: _acceptingPath == invitation.path
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.acceptInvitation),
                ),
              ),
              const Divider(),
            ],
            for (var index = 0; index < notifications.length; index++) ...[
              _NotificationTile(
                key: ValueKey('notification-$index'),
                icon: notifications[index].icon,
                color: notifications[index].color,
                title: notifications[index].title,
                body: notifications[index].body,
                time: notifications[index].time,
              ),
              if (index < notifications.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(ResidenceInvitation invitation) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      return;
    }
    setState(() => _acceptingPath = invitation.path);
    try {
      final repository = ref.read(accountOnboardingRepositoryProvider);
      final resolution = await repository.loadResolution(user);
      final currentInvitation = resolution.invitations
          .where((item) => item.path == invitation.path)
          .firstOrNull;
      if (currentInvitation == null) {
        return;
      }
      await repository.acceptInvitations(
        user: user,
        resolution: resolution,
        invitations: [currentInvitation],
      );
      ref.invalidate(residenceContextProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).accountResolutionUnexpectedError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingPath = null);
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xSmall),
        child: Text(body),
      ),
      trailing: Text(
        time,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return IconButton(
      key: const Key('profile-button'),
      tooltip: localizations.profile,
      onPressed: () => context.go(AppRoutes.profile),
      icon: Container(
        width: compact ? 32 : 38,
        height: compact ? 32 : 38,
        decoration: BoxDecoration(
          color: AppColors.directorySoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline),
        ),
        child: Icon(Icons.person_outline_rounded, size: compact ? 18 : 20),
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
          const _Brand(compact: true),
          const SizedBox(width: 10),
          const SizedBox(height: 24, child: VerticalDivider()),
          const SizedBox(width: 8),
          Expanded(child: _ResidenceSelector(residenceContext, compact: true)),
        ],
      ),
    );
  }
}

class _ResidenceSelector extends ConsumerWidget {
  const _ResidenceSelector(
    this.residenceContext, {
    this.compact = false,
    this.expanded = false,
  });

  final ResidenceContext residenceContext;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = residenceContext.activeResidence!;
    final localizations = AppLocalizations.of(context);
    return Material(
      key: const Key('residence-selector'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: () => _showResidenceSwitcher(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.medium),
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
              if (expanded) ...[
                const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.apartment_rounded),
                ),
                const SizedBox(width: AppSpacing.medium),
              ],
              Flexible(
                child: Text(
                  localizations.residenceDisplayName(
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
              const Icon(
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
  ) async {
    final residenceId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) =>
          _ResidenceSwitcherSheet(residenceContext: residenceContext),
    );
    if (residenceId != null) {
      await _select(ref, residenceId);
    }
  }

  Future<void> _select(WidgetRef ref, String residenceId) async {
    if (residenceId == residenceContext.activeResidenceId) {
      return;
    }
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      return;
    }
    try {
      await ref
          .read(residenceContextRepositoryProvider)
          .setActiveResidence(user: user, residenceId: residenceId);
      ref.invalidate(residenceContextProvider);
    } catch (_) {
      final context = ref.context;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).accountResolutionUnexpectedError,
            ),
          ),
        );
      }
    }
  }
}

class _ResidenceSwitcherSheet extends StatelessWidget {
  const _ResidenceSwitcherSheet({required this.residenceContext});

  final ResidenceContext residenceContext;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: DecoratedBox(
        key: const Key('residence-switcher-sheet'),
        decoration: BoxDecoration(
          color: AppColors.canvas,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.selectResidence,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(
                            localizations.residenceSwitcherDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    IconButton(
                      key: const Key('close-residence-switcher'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.inkMuted,
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: residenceContext.residences.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.medium),
                    itemBuilder: (context, index) {
                      final residence = residenceContext.residences[index];
                      return _ResidenceSwitcherOption(
                        residence: residence,
                        selected:
                            residence.id == residenceContext.activeResidenceId,
                        onTap: () => Navigator.of(context).pop(residence.id),
                      );
                    },
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
    required this.residence,
    required this.selected,
    required this.onTap,
  });

  final UserResidence residence;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final address = [
      residence.address,
      residence.city,
    ].where((value) => value.isNotEmpty).join(' • ');
    return DarJarCard(
      key: ValueKey('residence-switcher-option-${residence.id}'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.large),
        color: selected ? AppColors.primarySoft : AppColors.surface,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                Icons.apartment_outlined,
                color: selected ? Colors.white : AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          localizations.residenceDisplayName(
                            normalizeResidenceName(residence.name),
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.ink,
                              ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: AppSpacing.small),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                            vertical: AppSpacing.xSmall,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            localizations.currentResidence,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      address,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidenceSetupRedirect extends StatefulWidget {
  const _ResidenceSetupRedirect();

  @override
  State<_ResidenceSetupRedirect> createState() =>
      _ResidenceSetupRedirectState();
}

class _ResidenceSetupRedirectState extends State<_ResidenceSetupRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(AppRoutes.residenceSetup);
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

List<_ShellDestination> _destinations(AppLocalizations localizations) {
  return [
    _ShellDestination(
      label: localizations.community,
      path: AppRoutes.community,
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      color: AppColors.community,
    ),
    _ShellDestination(
      label: localizations.directory,
      path: AppRoutes.directory,
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on_rounded,
      color: AppColors.directory,
    ),
    _ShellDestination(
      label: localizations.residence,
      path: AppRoutes.residence,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      color: AppColors.residence,
    ),
  ];
}
