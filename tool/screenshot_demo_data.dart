import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darjar/core/images/storage_image_provider.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:darjar/features/directory/presentation/directory_entry_image.dart';
// In-memory fixtures shared by local preview and screenshots. Never initialize Firebase.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/data/feed_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/notifications/data/notifications_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';

final now = DateTime.now();
final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
const names = [
  'أمين العلوي',
  'سلمى بناني',
  'يوسف الإدريسي',
  'مريم المنصوري',
  'عمر التازي',
  'نادية الفاسي',
  'كريم المريني',
  'هند العلمي',
];
final members = ResidenceMembersData(
  buildings: [
    ResidenceBuilding(
      id: 'b',
      nameAr: 'عمارة الياسمين',
      nameEn: 'Yasmeen',
      floors: [
        for (var f = 0; f < 6; f++)
          ResidenceFloor(
            id: 'f$f',
            nameAr: 'الطابق ${f + 1}',
            nameEn: 'Floor',
            apartments: [
              for (var j = 1; j <= 4; j++)
                ResidenceApartment(
                  id: 'a${f * 4 + j}',
                  number: '${f * 4 + j}',
                  floorId: 'f$f',
                  buildingId: 'b',
                ),
            ],
          ),
      ],
    ),
  ],
  members: [
    for (var i = 1; i <= 24; i++)
      ResidenceMember(
        id: 'u$i',
        name: names[(i - 1) % 8],
        phone: '',
        role: i == 1
            ? ResidenceMemberRole.president
            : ResidenceMemberRole.resident,
        apartmentId: 'a$i',
        hasProfileImage: true,
      ),
  ],
);
final dues = ResidenceDuesOverview(
  dues: [
    for (var m = 1; m <= now.month; m++)
      for (var i = 1; i <= 24; i++)
        ResidenceDue(
          id: '${m}_a$i',
          apartmentId: 'a$i',
          apartmentNumber: '$i',
          periodKey: '${now.year}-${m.toString().padLeft(2, '0')}',
          amountDue: 350,
          amountPaid: i % 6 != 0 || m < now.month - 1
              ? 350
              : i == 6
              ? 150
              : 0,
          status: i % 6 != 0 || m < now.month - 1
              ? ResidenceDueStatus.paid
              : i == 6
              ? ResidenceDueStatus.partial
              : ResidenceDueStatus.unpaid,
        ),
  ],
  payments: [
    for (var i = 1; i % 6 != 0; i++)
      ResidenceDuePayment(
        id: 'p$i',
        dueId: '${period}_a$i',
        apartmentId: 'a$i',
        apartmentNumber: '$i',
        amount: 350,
        paidAt: now.subtract(Duration(days: i ~/ 3)),
        note: 'اشتراك شهر ${now.month}',
        recordedBy: 'أمين العلوي',
        paymentGroupId: 'g$i',
      ),
  ],
);
final finances = ResidenceFinances.fromTransactions(
  transactions: [
    ResidenceTransaction(
      id: 'opening',
      type: ResidenceTransactionType.income,
      amount: 18500,
      date: DateTime(now.year),
      name: 'الرصيد الافتتاحي',
      source: ResidenceTransactionSource.openingBalance,
    ),
    for (var m = 1; m <= now.month; m++) ...[
      ResidenceTransaction(
        id: 'income$m',
        type: ResidenceTransactionType.income,
        amount: 7150,
        date: DateTime(now.year, m, 5),
        name: 'اشتراكات السكان الشهرية',
        source: ResidenceTransactionSource.dues,
      ),
      for (var i = 0; i < 4; i++)
        ResidenceTransaction(
          id: 'expense$m$i',
          type: ResidenceTransactionType.expense,
          amount: [1200, 850, 650, 400][i],
          date: DateTime(now.year, m, [12, 10, 8, 6][i]),
          name: [
            'صيانة المصعد الدورية',
            'تنظيف الأجزاء المشتركة',
            'فاتورة الماء والكهرباء',
            'العناية بالحديقة',
          ][i],
          source: ResidenceTransactionSource.manual,
          expenseCategory: [
            ResidenceExpenseCategory.maintenance,
            ResidenceExpenseCategory.cleaning,
            ResidenceExpenseCategory.utilities,
            ResidenceExpenseCategory.custom,
          ][i],
          note: 'تمت مراجعة الفاتورة واعتمادها',
        ),
    ],
  ],
  paidResidents: 20,
  totalResidents: 24,
);

class DemoFinance extends ResidenceFinanceController {
  @override
  Future<ResidenceFinances> build() async => finances;
}

class DemoDues extends ResidenceDuesManagementController {
  @override
  Future<ResidenceDuesOverview> build() async => dues;
}

class DemoSettings extends ResidenceSettingsController {
  @override
  Future<ResidenceSettings> build() async => const ResidenceSettings(
    residenceId: 'demo',
    joinCode: 'DEMO',
    name: 'إقامة الياسمين',
    address: 'شارع النخيل، حي الرياض',
    city: '4421010',
    establishmentYear: 2020,
    defaultSubscriptionAmount: 350,
    invitationUrl: '',
    joinRequestsEnabled: true,
    hasImage: false,
    buildings: [
      ResidenceBuildingConfiguration(
        id: 'b',
        name: 'عمارة الياسمين',
        floorCount: 5,
      ),
    ],
    managementOrganization: 'مكتب اتحاد الملاك',
    managementPhone: '',
    bankName: 'البنك الشعبي',
    bankAccount: '',
  );
}

class DemoAuth implements AuthRepository {
  @override
  AuthUser? get currentUser => const AuthUser(uid: 'u1', phoneNumber: null);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Capture is read only');
}

ProviderScope screenshotDemoScope({required Widget child}) => ProviderScope(
  overrides: [
    firebaseFirestoreProvider.overrideWith(
      (ref) => throw StateError('Demo mode: database disabled'),
    ),
    firebaseStorageProvider.overrideWith(
      (ref) => throw StateError('Demo mode: storage disabled'),
    ),
    directoryEntriesProvider.overrideWith(DemoDirectory.new),
    serviceCategoriesProvider.overrideWith(
      (ref) => Stream.value(demoCategories),
    ),
    directoryEntryImageProvider.overrideWith((ref, id) {
      final index = int.tryParse(id.replaceFirst('service', '')) ?? 0;
      return AssetImage(
        'assets/images/community/${['plumber.jpg', 'elevator-tools.jpg', 'elevator-maintenance.jpg', 'tree-saplings.jpg'][index % 4]}',
      );
    }),
    storageImageBytesProvider.overrideWith((ref, path) async {
      final parts = path.split('/');
      final userNumber = parts.length > 1 && parts.first == 'users'
          ? int.tryParse(parts[1].replaceFirst('u', ''))
          : null;
      if (userNumber == null) throw StateError('No demo image');
      final index = ((userNumber - 1) % 8) + 1;
      final data = await rootBundle.load(
        'assets/images/community/demo-avatar-$index.jpg',
      );
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }),
    authRepositoryProvider.overrideWithValue(DemoAuth()),
    residenceContextProvider.overrideWith(
      (ref) async => const ResidenceContext(
        residences: [
          UserResidence(
            id: 'demo',
            name: 'إقامة الياسمين',
            address: 'شارع النخيل، حي الرياض',
            city: '4421010',
            role: 'owner',
            apartmentId: 'a1',
          ),
        ],
        activeResidenceId: 'demo',
      ),
    ),
    residenceFinancesProvider.overrideWith(DemoFinance.new),
    residenceDuesManagementProvider.overrideWith(DemoDues.new),
    residenceSettingsProvider.overrideWith(DemoSettings.new),
    residentDuesProvider.overrideWith(
      (ref) async => ResidenceDuesOverview(
        dues: dues.dues.where((d) => d.apartmentId == 'a1').toList(),
        payments: dues.payments.where((p) => p.apartmentId == 'a1').toList(),
      ),
    ),
    residenceDirectoryProvider.overrideWith((ref) async => members),
    residenceDocumentsProvider.overrideWith(
      (ref) => Stream.value([
        for (var i = 0; i < 3; i++)
          ResidenceDocument(
            id: 'doc$i',
            title: [
              'محضر الجمع العام السنوي',
              'النظام الداخلي للإقامة',
              'تقرير الصيانة الدورية',
            ][i],
            originalFileName: 'document.pdf',
            storagePath: '',
            contentType: 'application/pdf',
            sizeBytes: 245000,
            uploadedBy: 'u1',
            createdAt: now,
            updatedAt: now,
          ),
      ]),
    ),
    residenceTransactionAttachmentsProvider.overrideWith((ref) async => []),
    notificationsProvider.overrideWith((ref) => Stream.value([])),
    feedActivitiesProvider.overrideWith((ref) => Stream.value([])),
    communityPostsProvider.overrideWith(
      (ref) => Stream.value([
        for (var i = 0; i < 8; i++)
          CommunityPost(
            id: 'post$i',
            author: names[i],
            authorId: 'u${i + 1}',
            imagePaths: i == 1
                ? ['assets/images/community/elevator-maintenance.jpg']
                : i == 2
                ? ['assets/images/community/tree-saplings.jpg']
                : [],
            timeLabel: 'منذ ${i + 1} ساعات',
            createdAt: now.subtract(Duration(hours: i + 1)),
            content: [
              'يسر مكتب اتحاد الملاك دعوتكم للجمع العام السنوي يوم الأحد على الساعة العاشرة صباحًا بفضاء الإقامة.\nسنناقش حصيلة السنة وبرنامج تحسين المساحات المشتركة. حضوركم يهمنا جميعًا.',
              'اكتملت صيانة المصعد وتجديد إضاءة المدخل\nشكرًا لكل الجيران على تعاونهم وحرصهم على جمالية إقامتنا.',
              'اقتراح لتنظيم يوم لزراعة الورود في حديقة الإقامة\nمن يرغب في المشاركة صباح السبت المقبل؟',
              'تذكير ودي بأداء الاشتراك الشهري للمساهمة في النظافة والصيانة. شكرًا لالتزامكم.',
              'هل لديكم توصية بسباك موثوق في الحي؟ شكرًا لمساعدتكم.',
              'شكرًا لفريق النظافة على العناية اليومية بالمرافق المشتركة.',
              'لقاء الجيران نهاية الأسبوع في حديقة الإقامة. مرحبًا بالجميع!',
              'تم توفير نسخة من محضر الاجتماع ضمن وثائق الإقامة.',
            ][i],
            kind: i == 0
                ? CommunityPostKind.announcement
                : CommunityPostKind.general,
            likes: [24, 18, 12, 9, 6, 15, 8, 11][i],
            comments: [
              const CommunityComment(
                id: 'c',
                author: 'سلمى بناني',
                body: 'شكرًا على المجهودات، بالتوفيق للجميع',
                timeLabel: 'منذ ساعة',
              ),
            ],
            isOfficial: i == 0,
            authorRole: i == 0 ? 'owner' : 'resident',
          ),
      ]),
    ),
  ],
  child: child,
);

final demoCategories = [
  for (final item in [
    ('plumbing', 'السباكة'),
    ('electricity', 'الكهرباء'),
    ('maintenance', 'الصيانة'),
    ('gardening', 'البستنة'),
  ])
    ServiceCategory(
      id: item.$1,
      shortNameAr: item.$2,
      longNameAr: item.$2,
      shortNameEn: item.$1,
      longNameEn: item.$1,
      subcategories: [],
      order: 0,
    ),
];
final demoServices = [
  for (var i = 0; i < 12; i++)
    DirectoryEntry(
      id: 'service$i',
      name: [
        'رشيد للسباكة',
        'نور للكهرباء',
        'أطلس لصيانة المصاعد',
        'حدائق الياسمين',
        'مصطفى لخدمات السباكة',
        'الأمان للكهرباء',
        'خبراء الصيانة',
        'الواحة للبستنة',
        'ياسين للسباكة',
        'حلول الإنارة',
        'تقنيات المصاعد',
        'روائع الحدائق',
      ][i],
      categoryId: demoCategories[i % 4].id,
      subcategoryIds: [],
      profession: [
        'إصلاح التسربات وتركيب التجهيزات الصحية',
        'تركيب وصيانة الشبكات الكهربائية',
        'صيانة المصاعد والمرافق المشتركة',
        'تنسيق الحدائق والعناية بالمساحات الخضراء',
      ][i % 4],
      phone: '',
      score: 4.9 - (i % 3) * 0.1,
      recommendationCount: 36 - i,
      localRecommendationCount: 24 - i,
      workedResidences: ['إقامة الياسمين', 'إقامة النخيل'],
      reviews: [
        DirectoryReview(
          author: 'سلمى بناني',
          userId: 'u2',
          residence: 'إقامة الياسمين',
          comment: 'خدمة ممتازة والتزام بالمواعيد. أنصح بالتعامل معه.',
          timeLabel: 'منذ يومين',
        ),
        DirectoryReview(
          author: 'أمين العلوي',
          userId: 'u1',
          residence: 'إقامة الياسمين',
          comment: 'عمل متقن وتعامل احترافي، شكرًا على المجهود.',
          timeLabel: 'منذ أسبوع',
        ),
      ],
      neighborhood: 'حي الرياض',
      city: '4421010',
      createdBy: 'u${i % 8 + 1}',
    ),
];

class DemoDirectory extends DirectoryController {
  @override
  List<DirectoryEntry> build() => demoServices;
  @override
  bool get hasMore => false;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadMore() async {}
}
