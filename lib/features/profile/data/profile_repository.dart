import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProfilePermission { manageResidence }

class ResidentProfile {
  const ResidentProfile({
    required this.name,
    required this.phone,
    required this.residence,
    required this.unit,
    required this.role,
    this.permissions = const {},
  });

  final String name;
  final String phone;
  final String residence;
  final String unit;
  final String role;
  final Set<ProfilePermission> permissions;

  bool get canManageResidence =>
      permissions.contains(ProfilePermission.manageResidence);
}

abstract interface class ProfileRepository {
  ResidentProfile getProfile();
}

class MockProfileRepository implements ProfileRepository {
  @override
  ResidentProfile getProfile() {
    return const ResidentProfile(
      name: 'أحمد العلوي',
      phone: '+212 6 12 34 56 78',
      residence: 'إقامة الياسمين',
      unit: 'العمارة B — الشقة 12',
      role: 'ساكن',
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(),
);

final residentProfileProvider = Provider<ResidentProfile>(
  (ref) => ref.read(profileRepositoryProvider).getProfile(),
);
