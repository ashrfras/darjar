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

enum ResidenceExpenseCategory { maintenance, utilities, cleaning, security }

enum ResidenceTransactionType { income, expense }

class ResidenceTransaction {
  const ResidenceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.descriptionAr,
    required this.descriptionEn,
    this.expenseCategory,
    this.supportingDocument,
  });

  final String id;
  final ResidenceTransactionType type;
  final int amount;
  final DateTime date;
  final String descriptionAr;
  final String descriptionEn;
  final ResidenceExpenseCategory? expenseCategory;
  final String? supportingDocument;
}

class ResidenceExpenseBreakdown {
  const ResidenceExpenseBreakdown({
    required this.category,
    required this.amount,
  });

  final ResidenceExpenseCategory category;
  final int amount;
}

class ResidenceExpense {
  const ResidenceExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.descriptionAr,
    required this.descriptionEn,
    this.supportingDocument,
  });

  final String id;
  final int amount;
  final ResidenceExpenseCategory category;
  final DateTime date;
  final String descriptionAr;
  final String descriptionEn;
  final String? supportingDocument;
}

class ResidenceFinances {
  const ResidenceFinances({
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.paidResidents,
    required this.totalResidents,
    required this.breakdown,
    required this.recentExpenses,
    required this.transactions,
  });

  final int totalIncome;
  final int totalExpenses;
  final int currentBalance;
  final int paidResidents;
  final int totalResidents;
  final List<ResidenceExpenseBreakdown> breakdown;
  final List<ResidenceExpense> recentExpenses;
  final List<ResidenceTransaction> transactions;

  double get collectionRate {
    if (totalResidents == 0) return 0;
    return paidResidents / totalResidents;
  }
}

class ResidenceDashboardData {
  const ResidenceDashboardData({
    required this.monthlyDue,
    required this.lastPayment,
    required this.lastPaymentDate,
    required this.paidThrough,
    required this.finances,
    required this.notifications,
    required this.documents,
  });

  final int monthlyDue;
  final int lastPayment;
  final String lastPaymentDate;
  final String paidThrough;
  final ResidenceFinances finances;
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

  ResidenceFinances getResidenceFinances();

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
  ResidenceFinances getResidenceFinances() {
    return ResidenceFinances(
      totalIncome: 128400,
      totalExpenses: 96500,
      currentBalance: 31900,
      paidResidents: 78,
      totalResidents: 96,
      breakdown: const [
        ResidenceExpenseBreakdown(
          category: ResidenceExpenseCategory.maintenance,
          amount: 38600,
        ),
        ResidenceExpenseBreakdown(
          category: ResidenceExpenseCategory.utilities,
          amount: 27100,
        ),
        ResidenceExpenseBreakdown(
          category: ResidenceExpenseCategory.cleaning,
          amount: 18400,
        ),
        ResidenceExpenseBreakdown(
          category: ResidenceExpenseCategory.security,
          amount: 12400,
        ),
      ],
      recentExpenses: [
        ResidenceExpense(
          id: 'elevator-service-july',
          amount: 4800,
          category: ResidenceExpenseCategory.maintenance,
          date: DateTime(2026, 7, 14),
          descriptionAr: 'الصيانة الدورية للمصعدين',
          descriptionEn: 'Scheduled maintenance for both elevators',
          supportingDocument: 'فاتورة-صيانة-المصاعد.pdf',
        ),
        ResidenceExpense(
          id: 'electricity-june',
          amount: 3260,
          category: ResidenceExpenseCategory.utilities,
          date: DateTime(2026, 7, 8),
          descriptionAr: 'فاتورة كهرباء المرافق المشتركة لشهر يونيو',
          descriptionEn: 'Common-area electricity bill for June',
          supportingDocument: 'فاتورة-الكهرباء-يونيو.pdf',
        ),
        ResidenceExpense(
          id: 'cleaning-supplies',
          amount: 1450,
          category: ResidenceExpenseCategory.cleaning,
          date: DateTime(2026, 7, 3),
          descriptionAr: 'مواد تنظيف المداخل والممرات',
          descriptionEn: 'Cleaning supplies for entrances and corridors',
        ),
        ResidenceExpense(
          id: 'security-june',
          amount: 6200,
          category: ResidenceExpenseCategory.security,
          date: DateTime(2026, 6, 30),
          descriptionAr: 'خدمة الحراسة لشهر يونيو',
          descriptionEn: 'Security service for June',
          supportingDocument: 'وصل-الحراسة-يونيو.pdf',
        ),
      ],
      transactions: [
        ResidenceTransaction(
          id: 'dues-july',
          type: ResidenceTransactionType.income,
          amount: 27300,
          date: DateTime(2026, 7, 18),
          descriptionAr: 'واجبات السكان المحصلة لشهر يوليو',
          descriptionEn: 'Resident dues collected for July',
        ),
        ResidenceTransaction(
          id: 'elevator-service-july',
          type: ResidenceTransactionType.expense,
          amount: 4800,
          date: DateTime(2026, 7, 14),
          descriptionAr: 'الصيانة الدورية للمصعدين',
          descriptionEn: 'Scheduled maintenance for both elevators',
          expenseCategory: ResidenceExpenseCategory.maintenance,
          supportingDocument: 'فاتورة-صيانة-المصاعد.pdf',
        ),
        ResidenceTransaction(
          id: 'electricity-june',
          type: ResidenceTransactionType.expense,
          amount: 3260,
          date: DateTime(2026, 7, 8),
          descriptionAr: 'فاتورة كهرباء المرافق المشتركة لشهر يونيو',
          descriptionEn: 'Common-area electricity bill for June',
          expenseCategory: ResidenceExpenseCategory.utilities,
          supportingDocument: 'فاتورة-الكهرباء-يونيو.pdf',
        ),
        ResidenceTransaction(
          id: 'cleaning-supplies',
          type: ResidenceTransactionType.expense,
          amount: 1450,
          date: DateTime(2026, 7, 3),
          descriptionAr: 'مواد تنظيف المداخل والممرات',
          descriptionEn: 'Cleaning supplies for entrances and corridors',
          expenseCategory: ResidenceExpenseCategory.cleaning,
        ),
        ResidenceTransaction(
          id: 'dues-june',
          type: ResidenceTransactionType.income,
          amount: 30100,
          date: DateTime(2026, 7, 1),
          descriptionAr: 'واجبات السكان المحصلة لشهر يونيو',
          descriptionEn: 'Resident dues collected for June',
        ),
        ResidenceTransaction(
          id: 'security-june',
          type: ResidenceTransactionType.expense,
          amount: 6200,
          date: DateTime(2026, 6, 30),
          descriptionAr: 'خدمة الحراسة لشهر يونيو',
          descriptionEn: 'Security service for June',
          expenseCategory: ResidenceExpenseCategory.security,
          supportingDocument: 'وصل-الحراسة-يونيو.pdf',
        ),
        ResidenceTransaction(
          id: 'dues-may',
          type: ResidenceTransactionType.income,
          amount: 26600,
          date: DateTime(2026, 6, 2),
          descriptionAr: 'واجبات السكان المحصلة لشهر مايو',
          descriptionEn: 'Resident dues collected for May',
        ),
        ResidenceTransaction(
          id: 'water-may',
          type: ResidenceTransactionType.expense,
          amount: 2180,
          date: DateTime(2026, 5, 27),
          descriptionAr: 'فاتورة ماء المرافق المشتركة',
          descriptionEn: 'Common-area water bill',
          expenseCategory: ResidenceExpenseCategory.utilities,
          supportingDocument: 'فاتورة-الماء-مايو.pdf',
        ),
        ResidenceTransaction(
          id: 'dues-april',
          type: ResidenceTransactionType.income,
          amount: 24400,
          date: DateTime(2026, 5, 3),
          descriptionAr: 'واجبات السكان المحصلة لشهر أبريل',
          descriptionEn: 'Resident dues collected for April',
        ),
        ResidenceTransaction(
          id: 'entrance-repair',
          type: ResidenceTransactionType.expense,
          amount: 3650,
          date: DateTime(2026, 4, 19),
          descriptionAr: 'إصلاح باب المدخل الرئيسي',
          descriptionEn: 'Main entrance door repair',
          expenseCategory: ResidenceExpenseCategory.maintenance,
          supportingDocument: 'فاتورة-إصلاح-المدخل.pdf',
        ),
        ResidenceTransaction(
          id: 'dues-march',
          type: ResidenceTransactionType.income,
          amount: 20000,
          date: DateTime(2026, 4, 2),
          descriptionAr: 'واجبات السكان المحصلة لشهر مارس',
          descriptionEn: 'Resident dues collected for March',
        ),
      ],
    );
  }

  @override
  ResidenceDashboardData getDashboardData() {
    return ResidenceDashboardData(
      monthlyDue: 350,
      lastPayment: 350,
      lastPaymentDate: '05 مايو 2026',
      paidThrough: 'مايو 2026',
      finances: getResidenceFinances(),
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

final residenceFinancesProvider = Provider<ResidenceFinances>(
  (ref) => ref.read(residenceRepositoryProvider).getResidenceFinances(),
);

final residenceDashboardProvider = Provider<ResidenceDashboardData>(
  (ref) => ref.read(residenceRepositoryProvider).getDashboardData(),
);
