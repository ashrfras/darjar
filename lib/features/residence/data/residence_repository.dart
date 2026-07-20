import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MaintenanceStatus { processing, completed }

class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.title,
    required this.location,
    required this.timeLabel,
    required this.status,
  });

  final String id;
  final String title;
  final String location;
  final String timeLabel;
  final MaintenanceStatus status;
}

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
    required this.maintenanceCompleted,
    required this.maintenanceProcessing,
    required this.maintenanceOpen,
    required this.extraordinaryExpense,
    required this.notifications,
    required this.documents,
    required this.buildingCount,
    required this.unitCount,
    required this.constructionYear,
  });

  final int monthlyDue;
  final int lastPayment;
  final String lastPaymentDate;
  final String paidThrough;
  final int maintenanceCompleted;
  final int maintenanceProcessing;
  final int maintenanceOpen;
  final ExtraordinaryExpense extraordinaryExpense;
  final List<AdministrativeNotification> notifications;
  final List<ResidenceDocument> documents;
  final int buildingCount;
  final int unitCount;
  final int constructionYear;
}

class ExtraordinaryExpense {
  const ExtraordinaryExpense({
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.residentShare,
    required this.progress,
    required this.imagePath,
  });

  final String title;
  final String description;
  final int totalAmount;
  final int residentShare;
  final double progress;
  final String imagePath;
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
  List<MaintenanceRequest> getMaintenanceRequests();

  MaintenanceRequest createMaintenanceRequest({
    required String title,
    required String location,
  });

  List<DuesRecord> getDuesRecords();

  ManagementInfo getManagementInfo();

  ResidenceDashboardData getDashboardData();
}

class MockResidenceRepository implements ResidenceRepository {
  final List<MaintenanceRequest> _requests = [
    const MaintenanceRequest(
      id: 'elevator-b',
      title: 'المصعد لا يعمل في الطابق B',
      location: 'العمارة B — الطابق 3',
      timeLabel: 'منذ ساعة',
      status: MaintenanceStatus.processing,
    ),
    const MaintenanceRequest(
      id: 'garage-light',
      title: 'مصباح المرآب لا يعمل',
      location: 'المرآب — المدخل الشرقي',
      timeLabel: 'أمس',
      status: MaintenanceStatus.completed,
    ),
  ];

  @override
  List<MaintenanceRequest> getMaintenanceRequests() {
    return List.unmodifiable(_requests);
  }

  @override
  MaintenanceRequest createMaintenanceRequest({
    required String title,
    required String location,
  }) {
    final request = MaintenanceRequest(
      id: 'request-${_requests.length + 1}',
      title: title,
      location: location,
      timeLabel: 'الآن',
      status: MaintenanceStatus.processing,
    );
    _requests.insert(0, request);
    return request;
  }

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
    return const ResidenceDashboardData(
      monthlyDue: 350,
      lastPayment: 350,
      lastPaymentDate: '05 مايو 2026',
      paidThrough: 'مايو 2026',
      maintenanceCompleted: 5,
      maintenanceProcessing: 1,
      maintenanceOpen: 2,
      extraordinaryExpense: ExtraordinaryExpense(
        title: 'مشروع إصلاح المصعد',
        description: 'مساهمة موحّدة لتحديث مصعد العمارة',
        totalAmount: 42000,
        residentShare: 350,
        progress: .35,
        imagePath: 'assets/images/community/elevator-corridor.jpg',
      ),
      notifications: [
        AdministrativeNotification(
          title: 'إنذار لعدم سداد الاشتراك',
          age: 'منذ يومين',
        ),
        AdministrativeNotification(title: 'مخالفة إزعاج', age: 'منذ 5 أيام'),
        AdministrativeNotification(
          title: 'تنبيه خاص بالصيانة',
          age: 'منذ 8 أيام',
        ),
      ],
      documents: [
        ResidenceDocument(title: 'القانون الداخلي', size: '2.4 MB'),
        ResidenceDocument(title: 'محضر اجتماع 2025-04', size: '1.8 MB'),
        ResidenceDocument(title: 'الميزانية السنوية 2025', size: '3.1 MB'),
      ],
      buildingCount: 6,
      unitCount: 96,
      constructionYear: 2018,
    );
  }
}

final residenceRepositoryProvider = Provider<ResidenceRepository>(
  (ref) => MockResidenceRepository(),
);

final maintenanceRequestsProvider =
    NotifierProvider<MaintenanceRequestsController, List<MaintenanceRequest>>(
      MaintenanceRequestsController.new,
    );

class MaintenanceRequestsController extends Notifier<List<MaintenanceRequest>> {
  @override
  List<MaintenanceRequest> build() {
    return ref.read(residenceRepositoryProvider).getMaintenanceRequests();
  }

  void create({required String title, required String location}) {
    ref
        .read(residenceRepositoryProvider)
        .createMaintenanceRequest(title: title, location: location);
    state = ref.read(residenceRepositoryProvider).getMaintenanceRequests();
  }
}

final duesRecordsProvider = Provider<List<DuesRecord>>(
  (ref) => ref.read(residenceRepositoryProvider).getDuesRecords(),
);

final managementInfoProvider = Provider<ManagementInfo>(
  (ref) => ref.read(residenceRepositoryProvider).getManagementInfo(),
);

final residenceDashboardProvider = Provider<ResidenceDashboardData>(
  (ref) => ref.read(residenceRepositoryProvider).getDashboardData(),
);
