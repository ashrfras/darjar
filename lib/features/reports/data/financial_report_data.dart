import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialReportData {
  const FinancialReportData(this.residence, this.finances, this.dues);
  final UserResidence residence;
  final ResidenceFinances finances;
  final ResidenceDuesOverview dues;
}

// Read only: exporting a report never generates dues or publishes receipts.
final financialReportDataProvider =
    FutureProvider.autoDispose<FinancialReportData>((ref) async {
      final residence = (await ref.watch(
        residenceContextProvider.future,
      )).activeResidence;
      if (residence == null || !residence.canManageResidence) {
        throw const ResidenceFinanceFailure('permission-denied');
      }
      final members = await ref.watch(residenceMembersProvider.future);
      final apartmentIds = {
        for (final apartment in members.apartments)
          if (apartment.isDuesTrackingActive) apartment.id,
      };
      final financeRepository = ref.watch(residenceFinanceRepositoryProvider);
      final duesRepository = ref.watch(residenceDuesRepositoryProvider);
      final results = await Future.wait<Object>([
        financeRepository.load(
          residence.id,
          activeTrackedApartmentIds: apartmentIds,
        ),
        duesRepository.load(residenceId: residence.id),
      ]);
      return FinancialReportData(
        residence,
        results[0] as ResidenceFinances,
        (results[1] as ResidenceDuesOverview).forActiveApartments(apartmentIds),
      );
    });
