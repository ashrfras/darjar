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
    required this.notifications,
    required this.documents,
  });

  final int monthlyDue;
  final int lastPayment;
  final String lastPaymentDate;
  final String paidThrough;
  final List<AdministrativeNotification> notifications;
  final List<ResidenceDocument> documents;
}

class AdministrativeNotification {
  const AdministrativeNotification({required this.title, required this.age});

  final String title;
  final String age;
}

class ResidenceDocument {
  const ResidenceDocument({required this.title, required this.size});

  final String title;
  final String size;
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
        amountLabel: '300 درهم',
        statusLabel: 'في انتظار التحقق',
        isPaid: false,
      ),
      DuesRecord(
        period: 'يونيو 2026',
        amountLabel: '300 درهم',
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
      notifications: const [
        AdministrativeNotification(
          title: 'إنذار لعدم سداد الاشتراك',
          age: 'منذ يومين',
        ),
        AdministrativeNotification(title: 'مخالفة إزعاج', age: 'منذ 5 أيام'),
        AdministrativeNotification(
          title: 'تنبيه خاص بالمرافق',
          age: 'منذ 8 أيام',
        ),
      ],
      documents: const [
        ResidenceDocument(title: 'القانون الداخلي', size: '2.4 MB'),
        ResidenceDocument(title: 'محضر اجتماع 2025-04', size: '1.8 MB'),
        ResidenceDocument(title: 'الميزانية السنوية 2025', size: '3.1 MB'),
      ],
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
