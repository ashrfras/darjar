import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidentProfile {
  const ResidentProfile({
    required this.name,
    required this.email,
    required this.residence,
    required this.unit,
    required this.role,
  });

  final String name;
  final String email;
  final String residence;
  final String unit;
  final String role;
}

abstract interface class ProfileRepository {
  ResidentProfile getProfile();
}

class MockProfileRepository implements ProfileRepository {
  @override
  ResidentProfile getProfile() {
    return const ResidentProfile(
      name: 'أحمد العلوي',
      email: 'ahmed@example.com',
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
