import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter/material.dart';

ResidenceMember? residencePresidentMember(
  UserResidence residence,
  ResidenceMembersData data,
) {
  final presidentId = residence.presidentId;
  return data.members.where((member) {
    return presidentId == null
        ? member.role == ResidenceMemberRole.president
        : member.id == presidentId;
  }).firstOrNull;
}

bool hasRecordedResidencePresident(UserResidence residence) =>
    residence.presidentId != null ||
    residence.role == 'president' ||
    residence.role == 'owner';

bool hasAvailablePresidentProfile(ResidenceMember president) =>
    president.name.trim().isNotEmpty && president.name != president.id;

({ResidenceMember? president, bool canAppoint, bool canTransfer})
residencePresidency(
  UserResidence residence,
  ResidenceMembersData data,
  String? userId,
) {
  final president = residencePresidentMember(residence, data);
  return (
    president: president,
    canAppoint:
        president == null &&
        residence.presidentId == null &&
        residence.isCreatorAwaitingPresident &&
        data.members.any((member) => member.id == userId),
    canTransfer:
        president != null &&
        president.id == userId &&
        (residence.role == 'president' || residence.role == 'owner'),
  );
}

class ResidencePresidentProfile extends StatelessWidget {
  const ResidencePresidentProfile({
    required this.president,
    required this.apartmentNumber,
    this.onChangePresident,
    super.key,
  });

  final ResidenceMember president;
  final String? apartmentNumber;
  final VoidCallback? onChangePresident;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final name = Text(
      president.name,
      style: Theme.of(context).textTheme.titleLarge,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DarJarUserAvatar(
          userId: president.id,
          name: president.name,
          showImage: president.hasProfileImage,
          radius: 30,
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onChangePresident == null)
                name
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: name),
                    const SizedBox(width: AppSpacing.xSmall),
                    Flexible(
                      flex: 2,
                      child: TextButton(
                        key: const Key('change-residence-president'),
                        onPressed: onChangePresident,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xSmall,
                          ),
                          textStyle: Theme.of(context).textTheme.labelMedium,
                        ),
                        child: Text(
                          strings.residencePresidentChange,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.small),
              DarJarBadge(
                label: strings.residencePresidentTitle,
                tone: DarJarBadgeTone.info,
              ),
              if (apartmentNumber case final String number
                  when number.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(strings.residentApartment(number)),
              ],
              if (president.phone.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Semantics(
                  label: strings.phone,
                  child: DarJarPhoneNumber(president.phone),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
