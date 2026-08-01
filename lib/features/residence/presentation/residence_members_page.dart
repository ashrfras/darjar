import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceMembersPage extends ConsumerWidget {
  const ResidenceMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(residenceDirectoryProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const Key('residence-members-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.residenceResidents,
                description: compact
                    ? null
                    : localizations.residenceResidentsDescription,
                fallbackLocation: AppRoutes.residence,
              ),
              const SizedBox(height: AppSpacing.large),
              membersState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => _LoadError(
                  onRetry: () => ref.invalidate(residenceDirectoryProvider),
                ),
                data: (data) => _MembersList(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({required this.data});

  final ResidenceMembersData data;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final members = [...data.members]..sort(compareResidenceMembersByRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.residenceResidentsCount(members.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.medium),
        if (members.isEmpty)
          DarJarCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xLarge),
              child: Column(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 38,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(localizations.residenceNoResidents),
                ],
              ),
            ),
          )
        else
          for (final member in members) ...[
            _MemberCard(
              member: member,
              location: _locationFor(data, member.apartmentId),
              showBuilding: data.buildings.length > 1,
            ),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }

  _MemberLocation? _locationFor(
    ResidenceMembersData data,
    String? apartmentId,
  ) {
    if (apartmentId == null) return null;
    for (final building in data.buildings) {
      for (final floor in building.floors) {
        for (final apartment in floor.apartments) {
          if (apartment.id == apartmentId) {
            return _MemberLocation(
              building: building,
              floor: floor,
              apartment: apartment,
            );
          }
        }
      }
    }
    return null;
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.location,
    required this.showBuilding,
  });

  final ResidenceMember member;
  final _MemberLocation? location;
  final bool showBuilding;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final location = this.location;

    return DarJarCard(
      key: ValueKey('residence-member-${member.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarJarUserAvatar(
            userId: member.id,
            name: member.name,
            showImage: member.hasProfileImage,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.xSmall,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      abbreviatedPersonName(member.name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DarJarBadge(
                      label: _roleLabel(localizations, member.role),
                      tone: member.role == ResidenceMemberRole.resident
                          ? DarJarBadgeTone.neutral
                          : DarJarBadgeTone.info,
                    ),
                  ],
                ),
                if (member.phone.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 17,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Flexible(
                        child: DarJarPhoneNumber(
                          member.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.small),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      location == null
                          ? Icons.link_off_rounded
                          : Icons.door_front_door_outlined,
                      size: 17,
                      color: location == null
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        location == null
                            ? localizations.profileApartmentNotAssigned
                            : _locationLabel(
                                localizations,
                                location,
                                languageCode,
                              ),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _locationLabel(
    AppLocalizations localizations,
    _MemberLocation location,
    String languageCode,
  ) {
    final buildingName = languageCode == 'ar'
        ? location.building.nameAr
        : location.building.nameEn;
    final floorName = languageCode == 'ar'
        ? location.floor.nameAr
        : location.floor.nameEn;
    return [
      localizations.residentApartment(location.apartment.number),
      if (showBuilding && buildingName.isNotEmpty) buildingName,
      if (floorName.isNotEmpty) floorName,
    ].join(' · ');
  }

  String _roleLabel(AppLocalizations localizations, ResidenceMemberRole role) =>
      switch (role) {
        ResidenceMemberRole.president => localizations.profileRolePresident,
        ResidenceMemberRole.deputy => localizations.profileRoleDeputy,
        ResidenceMemberRole.treasurer => localizations.profileRoleTreasurer,
        ResidenceMemberRole.resident => localizations.profileRoleResident,
      };
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppLocalizations.of(context).residenceResidentsLoadError,
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _MemberLocation {
  const _MemberLocation({
    required this.building,
    required this.floor,
    required this.apartment,
  });

  final ResidenceBuilding building;
  final ResidenceFloor floor;
  final ResidenceApartment apartment;
}
