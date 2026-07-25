import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceBuildingConfiguration {
  const ResidenceBuildingConfiguration({
    required this.id,
    required this.name,
    required this.floorCount,
  });

  final String id;
  final String name;
  final int floorCount;

  ResidenceBuildingConfiguration copyWith({String? name, int? floorCount}) {
    return ResidenceBuildingConfiguration(
      id: id,
      name: name ?? this.name,
      floorCount: floorCount ?? this.floorCount,
    );
  }
}

class ResidenceSettings {
  const ResidenceSettings({
    required this.residenceId,
    required this.name,
    required this.address,
    required this.establishmentYear,
    required this.defaultSubscriptionAmount,
    required this.invitationUrl,
    required this.joinRequestsEnabled,
    required this.hasImage,
    required this.buildings,
    required this.managementOrganization,
    required this.managementPhone,
    required this.managementOfficeHours,
    required this.bankName,
    required this.bankAccount,
  });

  final String residenceId;
  final String name;
  final String address;
  final int establishmentYear;
  final int defaultSubscriptionAmount;
  final String invitationUrl;
  final bool joinRequestsEnabled;
  final bool hasImage;
  final List<ResidenceBuildingConfiguration> buildings;
  final String managementOrganization;
  final String managementPhone;
  final String managementOfficeHours;
  final String bankName;
  final String bankAccount;

  ResidenceSettings copyWith({
    String? name,
    String? address,
    int? establishmentYear,
    int? defaultSubscriptionAmount,
    String? invitationUrl,
    bool? joinRequestsEnabled,
    bool? hasImage,
    List<ResidenceBuildingConfiguration>? buildings,
    String? managementOrganization,
    String? managementPhone,
    String? managementOfficeHours,
    String? bankName,
    String? bankAccount,
  }) {
    return ResidenceSettings(
      residenceId: residenceId,
      name: name ?? this.name,
      address: address ?? this.address,
      establishmentYear: establishmentYear ?? this.establishmentYear,
      defaultSubscriptionAmount:
          defaultSubscriptionAmount ?? this.defaultSubscriptionAmount,
      invitationUrl: invitationUrl ?? this.invitationUrl,
      joinRequestsEnabled: joinRequestsEnabled ?? this.joinRequestsEnabled,
      hasImage: hasImage ?? this.hasImage,
      buildings: buildings ?? this.buildings,
      managementOrganization:
          managementOrganization ?? this.managementOrganization,
      managementPhone: managementPhone ?? this.managementPhone,
      managementOfficeHours:
          managementOfficeHours ?? this.managementOfficeHours,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }
}

abstract interface class ResidenceSettingsRepository {
  ResidenceSettings getSettings();

  void saveSettings(ResidenceSettings settings);
}

class MockResidenceSettingsRepository implements ResidenceSettingsRepository {
  ResidenceSettings _settings = ResidenceSettings(
    residenceId: '10284736',
    name: 'إقامة الياسمين',
    address: '12 شارع الياسمين، المعاريف، الدار البيضاء',
    establishmentYear: 2018,
    defaultSubscriptionAmount: 300,
    invitationUrl: 'https://darjar.app/join/yasmeen-7f3k',
    joinRequestsEnabled: true,
    hasImage: false,
    managementOrganization: 'شركة الياسمين لإدارة الإقامات',
    managementPhone: '+212 5 22 00 00 00',
    managementOfficeHours: 'الإثنين إلى الجمعة، 09:00–17:00',
    bankName: 'البنك المغربي للتجارة',
    bankAccount: '007 810 0000000000000000 00',
    buildings: const [
      ResidenceBuildingConfiguration(
        id: 'main-building',
        name: 'المبنى الرئيسي',
        floorCount: 3,
      ),
    ],
  );

  @override
  ResidenceSettings getSettings() => _settings;

  @override
  void saveSettings(ResidenceSettings settings) {
    _settings = settings;
  }
}

final residenceSettingsRepositoryProvider =
    Provider<ResidenceSettingsRepository>(
      (ref) => MockResidenceSettingsRepository(),
    );

class ResidenceSettingsController extends Notifier<ResidenceSettings> {
  @override
  ResidenceSettings build() {
    return ref.read(residenceSettingsRepositoryProvider).getSettings();
  }

  void save(ResidenceSettings settings) {
    ref.read(residenceSettingsRepositoryProvider).saveSettings(settings);
    state = settings;
  }

  void setJoinRequestsEnabled(bool enabled) {
    save(state.copyWith(joinRequestsEnabled: enabled));
  }

  void setHasImage(bool hasImage) {
    save(state.copyWith(hasImage: hasImage));
  }
}

final residenceSettingsProvider =
    NotifierProvider<ResidenceSettingsController, ResidenceSettings>(
      ResidenceSettingsController.new,
    );
