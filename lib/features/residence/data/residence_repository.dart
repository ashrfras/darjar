import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuesRecord {
  const DuesRecord({
    required this.period,
    required this.amountLabel,
    required this.statusLabel,
    required this.isPaid,
  });

  final String period;
  final String amountLabel;
  final String statusLabel;
  final bool isPaid;
}

class ManagementInfo {
  const ManagementInfo({
    required this.managerName,
    required this.phone,
    required this.officeHours,
    required this.bankName,
    required this.bankAccount,
  });

  final String managerName;
  final String phone;
  final String officeHours;
  final String bankName;
  final String bankAccount;
}

class ResidenceDashboardData {
  const ResidenceDashboardData({
    required this.monthlyDue,
    required this.lastPayment,
    required this.lastPaymentDate,
    required this.paidThrough,
  });

  final int monthlyDue;
  final int lastPayment;
  final String lastPaymentDate;
  final String paidThrough;
}

abstract interface class ResidenceRepository {
  List<DuesRecord> getDuesRecords();

  ManagementInfo getManagementInfo();

  ResidenceDashboardData getDashboardData();
}

class MockResidenceRepository implements ResidenceRepository {
  @override
  List<DuesRecord> getDuesRecords() {
    return const [
      DuesRecord(
        period: 'يوليو 2026',
        amountLabel: '300 د',
        statusLabel: 'في انتظار التحقق',
        isPaid: false,
      ),
      DuesRecord(
        period: 'يونيو 2026',
        amountLabel: '300 د',
        statusLabel: 'تم الأداء',
        isPaid: true,
      ),
    ];
  }

  @override
  ManagementInfo getManagementInfo() {
    return const ManagementInfo(
      managerName: 'شركة الياسمين لإدارة الإقامات',
      phone: '+212 5 22 00 00 00',
      officeHours: 'الإثنين إلى الجمعة، 09:00–17:00',
      bankName: 'البنك المغربي للتجارة',
      bankAccount: '007 810 0000000000000000 00',
    );
  }

  @override
  ResidenceDashboardData getDashboardData() {
    return ResidenceDashboardData(
      monthlyDue: 350,
      lastPayment: 350,
      lastPaymentDate: '05 مايو 2026',
      paidThrough: 'مايو 2026',
    );
  }
}

final residenceRepositoryProvider = Provider<ResidenceRepository>(
  (ref) => MockResidenceRepository(),
);

final duesRecordsProvider = Provider<List<DuesRecord>>(
  (ref) => ref.read(residenceRepositoryProvider).getDuesRecords(),
);

final managementInfoProvider = Provider<ManagementInfo>(
  (ref) => ref.read(residenceRepositoryProvider).getManagementInfo(),
);

final residenceDashboardProvider = Provider<ResidenceDashboardData>(
  (ref) => ref.read(residenceRepositoryProvider).getDashboardData(),
);
