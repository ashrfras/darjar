import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
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
        toolbarHeight: 76,
        centerTitle: true,
        leadingWidth: 58,
        leading: const _GalleryAction(asNotification: true),
        title: const _Brand(compact: true, centered: true),
        actions: const [_ResidenceAction(), _ProfileAction()],
        bottom: _CompactSectionTabs(
          destinations: destinations,
          selectedIndex: selectedIndex,
        ),
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
          _GalleryAction(),
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
  const _Brand({this.compact = false, this.centered = false});

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (centered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.brandLatin,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.ink,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3D8A78), Color(0xFF256758)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(Icons.apartment_rounded, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.medium),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!compact)
              Text(
                localizations.brandLatin,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ],
    );
  }
}

class _GalleryAction extends StatelessWidget {
  const _GalleryAction({this.asNotification = false});

  final bool asNotification;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return IconButton(
      key: const Key('gallery-button'),
      tooltip: localizations.componentGallery,
      onPressed: () => context.go(AppRoutes.gallery),
      icon: Badge(
        isLabelVisible: asNotification,
        smallSize: 8,
        backgroundColor: AppColors.warning,
        child: Icon(
          asNotification
              ? Icons.notifications_none_rounded
              : Icons.palette_outlined,
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return IconButton(
      key: const Key('profile-button'),
      tooltip: localizations.profile,
      onPressed: () => context.go(AppRoutes.profile),
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.marketplaceSoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(Icons.apartment_rounded, size: 20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.demoResidence,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _CompactSectionTabs extends StatelessWidget
    implements PreferredSizeWidget {
  const _CompactSectionTabs({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++) ...[
            if (index > 0)
              Container(width: 1, height: 40, color: AppColors.outline),
            Expanded(
              child: _CompactSectionTab(
                destination: destinations[index],
                selected: index == selectedIndex,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactSectionTab extends StatelessWidget {
  const _CompactSectionTab({required this.destination, required this.selected});

  final _ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(destination.path),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected ? destination.color : AppColors.inkMuted,
                  size: 25,
                ),
                const SizedBox(height: 5),
                Text(
                  '${destination.label}\u200F',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? destination.color : AppColors.ink,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: selected ? destination.color : Colors.transparent,
          ),
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
      label: localizations.marketplace,
      path: AppRoutes.marketplace,
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      color: AppColors.marketplace,
    ),
    _ShellDestination(
      label: localizations.services,
      path: AppRoutes.services,
      icon: Icons.home_repair_service_outlined,
      selectedIcon: Icons.home_repair_service_rounded,
      color: AppColors.services,
    ),
  ];
}
