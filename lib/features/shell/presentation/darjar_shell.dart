import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DarJarShell extends StatelessWidget {
  const DarJarShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            child: child,
          ),
          WindowSizeClass.medium => _MediumShell(
            destinations: destinations,
            selectedIndex: selectedIndex,
            child: child,
          ),
          WindowSizeClass.expanded => _ExpandedShell(
            destinations: destinations,
            selectedIndex: selectedIndex,
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
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('compact-shell'),
      appBar: AppBar(
        toolbarHeight: 58,
        titleSpacing: 0,
        leadingWidth: 218,
        leading: const _CompactIdentity(),
        title: const SizedBox.shrink(),
        actions: const [
          _NotificationsAction(compact: true),
          _ProfileAction(compact: true),
          SizedBox(width: 6),
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
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('medium-shell'),
      appBar: AppBar(
        title: const _Brand(compact: true),
        actions: const [
          _NotificationsAction(),
          _ProfileAction(),
          SizedBox(width: AppSpacing.large),
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
    required this.child,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          child: Icon(Icons.apartment_rounded),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Text(
                            localizations.demoResidence,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded),
                      ],
                    ),
                  ),
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
        Container(
          key: compact ? const Key('compact-brand') : null,
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF16988D), Color(0xFF0A5F59)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: compact ? 19 : 24,
          ),
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
  const _NotificationsAction({this.compact = false});

  final bool compact;

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
      icon: const Badge(
        smallSize: 7,
        offset: Offset(1, -1),
        backgroundColor: AppColors.warning,
        child: Icon(Icons.notifications_none_rounded),
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

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
  const _CompactIdentity();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 12),
      child: Row(
        children: [
          _Brand(compact: true),
          SizedBox(width: 10),
          SizedBox(height: 24, child: VerticalDivider()),
          SizedBox(width: 8),
          Expanded(child: _ResidenceAction()),
        ],
      ),
    );
  }
}

class _ResidenceAction extends StatelessWidget {
  const _ResidenceAction();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Row(
        key: const Key('compact-residence'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              localizations.demoResidence,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
        ],
      ),
    );
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
