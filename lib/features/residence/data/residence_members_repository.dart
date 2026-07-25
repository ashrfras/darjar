import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResidenceMemberRole { president, deputy, treasurer, resident }

class ResidenceMember {
  const ResidenceMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.apartmentId,
  });

  final String id;
  final String name;
  final String phone;
  final ResidenceMemberRole role;
  final String? apartmentId;

  ResidenceMember copyWith({
    ResidenceMemberRole? role,
    String? apartmentId,
    bool clearApartment = false,
  }) {
    return ResidenceMember(
      id: id,
      name: name,
      phone: phone,
      role: role ?? this.role,
      apartmentId: clearApartment ? null : apartmentId ?? this.apartmentId,
    );
  }
}

class ResidenceApartment {
  const ResidenceApartment({
    required this.id,
    required this.number,
    required this.floorId,
  });

  final String id;
  final String number;
  final String floorId;
}

class ResidenceFloor {
  const ResidenceFloor({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.apartments,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<ResidenceApartment> apartments;

  ResidenceFloor copyWith({List<ResidenceApartment>? apartments}) {
    return ResidenceFloor(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      apartments: apartments ?? this.apartments,
    );
  }
}

class ResidenceBuilding {
  const ResidenceBuilding({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.floors,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<ResidenceFloor> floors;

  ResidenceBuilding copyWith({List<ResidenceFloor>? floors}) {
    return ResidenceBuilding(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      floors: floors ?? this.floors,
    );
  }
}

class ResidenceMembersData {
  const ResidenceMembersData({required this.buildings, required this.members});

  final List<ResidenceBuilding> buildings;
  final List<ResidenceMember> members;

  ResidenceMembersData copyWith({
    List<ResidenceBuilding>? buildings,
    List<ResidenceMember>? members,
  }) {
    return ResidenceMembersData(
      buildings: buildings ?? this.buildings,
      members: members ?? this.members,
    );
  }

  List<ResidenceApartment> get apartments => [
    for (final building in buildings)
      for (final floor in building.floors) ...floor.apartments,
  ];
}

abstract interface class ResidenceMembersRepository {
  ResidenceMembersData getData();
}

class MockResidenceMembersRepository implements ResidenceMembersRepository {
  const MockResidenceMembersRepository();

  @override
  ResidenceMembersData getData() {
    return const ResidenceMembersData(
      buildings: [
        ResidenceBuilding(
          id: 'main-building',
          nameAr: 'العمارة الرئيسية',
          nameEn: 'Main building',
          floors: [
            ResidenceFloor(
              id: 'ground-floor',
              nameAr: 'الطابق الأرضي',
              nameEn: 'Ground floor',
              apartments: [
                ResidenceApartment(
                  id: 'apartment-01',
                  number: '01',
                  floorId: 'ground-floor',
                ),
                ResidenceApartment(
                  id: 'apartment-02',
                  number: '02',
                  floorId: 'ground-floor',
                ),
              ],
            ),
            ResidenceFloor(
              id: 'first-floor',
              nameAr: 'الطابق الأول',
              nameEn: 'First floor',
              apartments: [
                ResidenceApartment(
                  id: 'apartment-11',
                  number: '11',
                  floorId: 'first-floor',
                ),
                ResidenceApartment(
                  id: 'apartment-12',
                  number: '12',
                  floorId: 'first-floor',
                ),
                ResidenceApartment(
                  id: 'apartment-13',
                  number: '13',
                  floorId: 'first-floor',
                ),
              ],
            ),
            ResidenceFloor(
              id: 'second-floor',
              nameAr: 'الطابق الثاني',
              nameEn: 'Second floor',
              apartments: [
                ResidenceApartment(
                  id: 'apartment-21',
                  number: '21',
                  floorId: 'second-floor',
                ),
                ResidenceApartment(
                  id: 'apartment-22',
                  number: '22',
                  floorId: 'second-floor',
                ),
                ResidenceApartment(
                  id: 'apartment-23',
                  number: '23',
                  floorId: 'second-floor',
                ),
              ],
            ),
          ],
        ),
      ],
      members: [
        ResidenceMember(
          id: 'member-youssef',
          name: 'يوسف العلوي',
          phone: '+212 6 12 34 56 78',
          role: ResidenceMemberRole.president,
          apartmentId: 'apartment-12',
        ),
        ResidenceMember(
          id: 'member-salma',
          name: 'سلمى بنعمر',
          phone: '+212 6 23 45 67 89',
          role: ResidenceMemberRole.deputy,
          apartmentId: 'apartment-12',
        ),
        ResidenceMember(
          id: 'member-hamza',
          name: 'حمزة الإدريسي',
          phone: '+212 6 34 56 78 90',
          role: ResidenceMemberRole.treasurer,
          apartmentId: 'apartment-21',
        ),
        ResidenceMember(
          id: 'member-amina',
          name: 'أمينة المريني',
          phone: '+212 6 45 67 89 01',
          role: ResidenceMemberRole.resident,
          apartmentId: 'apartment-01',
        ),
        ResidenceMember(
          id: 'member-karim',
          name: 'كريم التازي',
          phone: '+212 6 56 78 90 12',
          role: ResidenceMemberRole.resident,
        ),
      ],
    );
  }
}

final residenceMembersRepositoryProvider = Provider<ResidenceMembersRepository>(
  (ref) => const MockResidenceMembersRepository(),
);

class ResidenceMembersController extends Notifier<ResidenceMembersData> {
  @override
  ResidenceMembersData build() {
    return ref.read(residenceMembersRepositoryProvider).getData();
  }

  void assignApartment(String memberId, String? apartmentId) {
    state = state.copyWith(
      members: [
        for (final member in state.members)
          if (member.id == memberId)
            member.copyWith(
              apartmentId: apartmentId,
              clearApartment: apartmentId == null,
            )
          else
            member,
      ],
    );
  }

  void changeRole(String memberId, ResidenceMemberRole role) {
    state = state.copyWith(
      members: [
        for (final member in state.members)
          if (member.id == memberId) member.copyWith(role: role) else member,
      ],
    );
  }

  void removeMember(String memberId) {
    state = state.copyWith(
      members: state.members
          .where((member) => member.id != memberId)
          .toList(growable: false),
    );
  }

  void addResident({
    required String firstName,
    required String lastName,
    required String phone,
    required String apartmentId,
  }) {
    final normalizedPhone = phone.trim();
    final phoneIdentity = normalizedPhone.replaceAll(RegExp(r'\s'), '');
    if (state.members.any(
      (member) => member.phone.replaceAll(RegExp(r'\s'), '') == phoneIdentity,
    )) {
      return;
    }
    final idSuffix = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(
      members: [
        ...state.members,
        ResidenceMember(
          id: 'member-$idSuffix',
          name: '${firstName.trim()} ${lastName.trim()}',
          phone: normalizedPhone,
          role: ResidenceMemberRole.resident,
          apartmentId: apartmentId,
        ),
      ],
    );
  }

  void addApartment({
    required String buildingId,
    required String floorId,
    required String number,
  }) {
    final normalizedNumber = number.trim();
    final id = 'apartment-$floorId-${normalizedNumber.toLowerCase()}';
    state = state.copyWith(
      buildings: [
        for (final building in state.buildings)
          if (building.id == buildingId)
            building.copyWith(
              floors: [
                for (final floor in building.floors)
                  if (floor.id == floorId)
                    floor.copyWith(
                      apartments: [
                        ...floor.apartments,
                        ResidenceApartment(
                          id: id,
                          number: normalizedNumber,
                          floorId: floorId,
                        ),
                      ],
                    )
                  else
                    floor,
              ],
            )
          else
            building,
      ],
    );
  }

  void deleteApartment(String apartmentId) {
    state = state.copyWith(
      buildings: [
        for (final building in state.buildings)
          building.copyWith(
            floors: [
              for (final floor in building.floors)
                floor.copyWith(
                  apartments: floor.apartments
                      .where((apartment) => apartment.id != apartmentId)
                      .toList(growable: false),
                ),
            ],
          ),
      ],
      members: [
        for (final member in state.members)
          if (member.apartmentId == apartmentId)
            member.copyWith(clearApartment: true)
          else
            member,
      ],
    );
  }
}

final residenceMembersProvider =
    NotifierProvider<ResidenceMembersController, ResidenceMembersData>(
      ResidenceMembersController.new,
    );
