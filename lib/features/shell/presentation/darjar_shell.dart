import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
        toolbarHeight: 70,
        centerTitle: true,
        leadingWidth: 154,
        leading: const _CompactResidenceLeading(),
        title: const _Brand(compact: true, centered: true),
        actions: const [
          _GalleryAction(asNotification: true),
          SizedBox(width: AppSpacing.xSmall),
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
    if (centered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'دارجار ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DarJar ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFamily: 'Cairo',
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              height: 1,
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
              colors: [Color(0xFF16988D), Color(0xFF0A5F59)],
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
              'دارجار',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(
                'DarJar',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.5,
                ),
              ),
            ],
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
      iconSize: asNotification ? 32 : 24,
      padding: EdgeInsets.all(asNotification ? 10 : 8),
      icon: Badge(
        isLabelVisible: asNotification,
        smallSize: asNotification ? 10 : 8,
        offset: asNotification ? const Offset(2, -2) : null,
        backgroundColor: AppColors.warning,
        child: Icon(
          asNotification ? CupertinoIcons.bell : Icons.palette_outlined,
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
          color: AppColors.directorySoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(Icons.apartment_rounded, size: 20),
      ),
    );
  }
}

class _CompactResidenceLeading extends StatelessWidget {
  const _CompactResidenceLeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ProfileAction(),
        Expanded(child: _ResidenceAction()),
      ],
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
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
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
