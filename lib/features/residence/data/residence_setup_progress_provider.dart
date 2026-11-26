import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ResidenceSetupProgress = ({
  bool hasUpperFloor,
  bool hasApartment,
  bool hasNeighbor,
  bool hasPresident,
});

typedef ResidenceSetupScope = ({
  String residenceId,
  String userId,
  String? phoneNumber,
});

final residenceSetupProgressProvider = Provider.autoDispose
    .family<ResidenceSetupProgress?, ResidenceSetupScope>((ref, scope) {
      final residence = ref
          .watch(residenceContextProvider)
          .value
          ?.activeResidence;
      if (residence == null ||
          residence.id != scope.residenceId ||
          residence.createdBy != scope.userId) {
        return null;
      }
      final path = 'residences/${scope.residenceId}';
      final president = ref.watch(_presidencyProvider(path)).value;
      final members = ref.watch(_activeMembersProvider(path)).value;
      final buildings = ref.watch(_childPathsProvider('$path/buildings')).value;
      if (president == null || members == null || buildings == null) {
        return null;
      }

      final floors = [
        for (final building in buildings)
          ref.watch(_childPathsProvider('$building/floors')).value,
      ];
      final loadedFloors = floors.whereType<List<String>>();
      final hasUpperFloor = loadedFloors.any(
        (buildingFloors) =>
            ResidenceBuildingConfiguration.upperFloorCountFromStoredFloors(
              buildingFloors.length,
            ) >
            0,
      );
      final apartments = [
        for (final floor in loadedFloors.expand((f) => f))
          ref.watch(_hasApartmentProvider('$floor/apartments')).value,
      ];
      final hasApartment = apartments.contains(true);
      if ((floors.contains(null) && (!hasUpperFloor || !hasApartment)) ||
          (!hasApartment && apartments.contains(null))) {
        return null;
      }

      final hasJoinedNeighbor = members.any(
        (member) => member.id != scope.userId,
      );
      // Pending invitations are readable only with existing setup permissions.
      final hasInvitedNeighbor =
          !hasJoinedNeighbor && residence.canManageApartmentsAndResidents
          ? ref
                .watch(_pendingInvitationIdsProvider(path))
                .value
                ?.any((id) => id != scope.phoneNumber)
          : false;
      if (hasInvitedNeighbor == null) return null;

      return (
        hasUpperFloor: hasUpperFloor,
        hasApartment: hasApartment,
        hasNeighbor: hasJoinedNeighbor || hasInvitedNeighbor,
        hasPresident:
            president.id?.isNotEmpty == true ||
            (!president.hasPresidentField &&
                members.any((member) {
                  final role = member.data()['role'];
                  return role == 'president' || role == 'owner';
                })),
      );
    });

final _presidencyProvider = StreamProvider.autoDispose
    .family<({String? id, bool hasPresidentField}), String>((ref, path) {
      return ref.watch(firebaseFirestoreProvider).doc(path).snapshots().map((
        doc,
      ) {
        final data = doc.data();
        return (
          id: data?['presidentId'] as String?,
          hasPresidentField: data?.containsKey('presidentId') ?? false,
        );
      });
    });

final _activeMembersProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((
      ref,
      path,
    ) {
      return ref
          .watch(firebaseFirestoreProvider)
          .collection('$path/members')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });

final _pendingInvitationIdsProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, path) {
      return ref
          .watch(firebaseFirestoreProvider)
          .collection('$path/invitations')
          .where('status', isEqualTo: 'pending')
          .limit(2)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.id]);
    });

final _childPathsProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, path) {
      return ref
          .watch(firebaseFirestoreProvider)
          .collection(path)
          .snapshots()
          .map(
            (snapshot) => [for (final doc in snapshot.docs) doc.reference.path],
          );
    });

final _hasApartmentProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  path,
) {
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(path)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);
});
