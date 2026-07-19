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

abstract interface class ServicesRepository {
  List<MaintenanceRequest> getMaintenanceRequests();

  MaintenanceRequest createMaintenanceRequest({
    required String title,
    required String location,
  });

  List<DuesRecord> getDuesRecords();

  ManagementInfo getManagementInfo();
}

class MockServicesRepository implements ServicesRepository {
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
}

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (ref) => MockServicesRepository(),
);

final maintenanceRequestsProvider =
    NotifierProvider<MaintenanceRequestsController, List<MaintenanceRequest>>(
      MaintenanceRequestsController.new,
    );

class MaintenanceRequestsController extends Notifier<List<MaintenanceRequest>> {
  @override
  List<MaintenanceRequest> build() {
    return ref.read(servicesRepositoryProvider).getMaintenanceRequests();
  }

  void create({required String title, required String location}) {
    ref
        .read(servicesRepositoryProvider)
        .createMaintenanceRequest(title: title, location: location);
    state = ref.read(servicesRepositoryProvider).getMaintenanceRequests();
  }
}

final duesRecordsProvider = Provider<List<DuesRecord>>(
  (ref) => ref.read(servicesRepositoryProvider).getDuesRecords(),
);

final managementInfoProvider = Provider<ManagementInfo>(
  (ref) => ref.read(servicesRepositoryProvider).getManagementInfo(),
);
