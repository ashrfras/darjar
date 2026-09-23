import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApartmentDuesReportData {
  const ApartmentDuesReportData(this.residence, this.apartments, this.dues);
  final UserResidence residence;
  final List<ResidenceApartment> apartments;
  final ResidenceDuesOverview dues;
}

// Exporting only reads recorded dues; it never creates monthly charges.
final apartmentDuesReportDataProvider =
    FutureProvider.autoDispose<ApartmentDuesReportData>((ref) async {
      final residence = (await ref.watch(
        residenceContextProvider.future,
      )).activeResidence;
      if (residence == null || !residence.canManageResidence) {
        throw const ResidenceDuesFailure('permission-denied');
      }
      final members = await ref.watch(residenceMembersProvider.future);
      final dues = await ref
          .watch(residenceDuesRepositoryProvider)
          .load(residenceId: residence.id);
      return ApartmentDuesReportData(residence, members.apartments, dues);
    });
