import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DirectoryCategory { all, craftsman, restaurant, cafe, pharmacy, facility }

class DirectoryReview {
  const DirectoryReview({
    required this.author,
    required this.residence,
    required this.comment,
    required this.timeLabel,
  });

  final String author;
  final String residence;
  final String comment;
  final String timeLabel;
}

class DirectoryEntry {
  const DirectoryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.profession,
    required this.phone,
    required this.score,
    required this.recommendationCount,
    required this.localRecommendationCount,
    required this.workedResidences,
    required this.reviews,
    this.neighborhood = 'المعاريف',
  });

  final String id;
  final String name;
  final DirectoryCategory category;
  final String profession;
  final String phone;
  final double score;
  final int recommendationCount;
  final int localRecommendationCount;
  final List<String> workedResidences;
  final List<DirectoryReview> reviews;
  final String neighborhood;

  DirectoryEntry copyWith({
    int? recommendationCount,
    int? localRecommendationCount,
    List<DirectoryReview>? reviews,
  }) {
    return DirectoryEntry(
      id: id,
      name: name,
      category: category,
      profession: profession,
      phone: phone,
      score: score,
      recommendationCount: recommendationCount ?? this.recommendationCount,
      localRecommendationCount:
          localRecommendationCount ?? this.localRecommendationCount,
      workedResidences: workedResidences,
      reviews: reviews ?? this.reviews,
      neighborhood: neighborhood,
    );
  }
}

abstract interface class DirectoryRepository {
  List<DirectoryEntry> getEntries();

  DirectoryEntry? getEntry(String id);

  DirectoryEntry recommend({required String id, required String comment});
}

class MockDirectoryRepository implements DirectoryRepository {
  final List<DirectoryEntry> _entries = [
    const DirectoryEntry(
      id: 'mohamed-electrician',
      name: 'محمد الكهربائي',
      category: DirectoryCategory.craftsman,
      profession: 'كهربائي · إصلاح الأعطال والتركيبات',
      phone: '06 12 34 56 78',
      score: 4.8,
      recommendationCount: 19,
      localRecommendationCount: 12,
      workedResidences: ['إقامة الياسمين', 'إقامة النخيل', 'إقامة الأندلس'],
      reviews: [
        DirectoryReview(
          author: 'سارة ب.',
          residence: 'إقامة الياسمين',
          comment: 'دقيق في الموعد وعالج عطل الكهرباء بسرعة.',
          timeLabel: 'منذ أسبوع',
        ),
        DirectoryReview(
          author: 'أمين ر.',
          residence: 'إقامة النخيل',
          comment: 'عمل نظيف وشرح المشكلة قبل البدء بالإصلاح.',
          timeLabel: 'منذ شهر',
        ),
      ],
    ),
    const DirectoryEntry(
      id: 'ahmed-plumber',
      name: 'أحمد السباك',
      category: DirectoryCategory.craftsman,
      profession: 'سباكة · تسربات وسخانات',
      phone: '06 23 45 67 89',
      score: 4.9,
      recommendationCount: 28,
      localRecommendationCount: 18,
      workedResidences: ['إقامة الياسمين', 'إقامة الزهراء'],
      reviews: [
        DirectoryReview(
          author: 'ليلى م.',
          residence: 'إقامة الياسمين',
          comment: 'أنهى إصلاح التسرب في نفس اليوم وبسعر واضح.',
          timeLabel: 'منذ 3 أيام',
        ),
      ],
    ),
    const DirectoryEntry(
      id: 'yassine-ac',
      name: 'ياسين للتكييف',
      category: DirectoryCategory.craftsman,
      profession: 'تكييف وتبريد',
      phone: '06 34 56 78 90',
      score: 4.9,
      recommendationCount: 32,
      localRecommendationCount: 25,
      workedResidences: ['إقامة الياسمين', 'إقامة الهدى', 'إقامة الفردوس'],
      reviews: [
        DirectoryReview(
          author: 'يوسف ك.',
          residence: 'إقامة الياسمين',
          comment: 'خدمة ممتازة والتكييف يعمل بكفاءة منذ الزيارة.',
          timeLabel: 'منذ أسبوعين',
        ),
      ],
    ),
    const DirectoryEntry(
      id: 'noura-cleaning',
      name: 'نورا للتنظيف',
      category: DirectoryCategory.craftsman,
      profession: 'تنظيف منازل ومكاتب',
      phone: '06 45 67 89 01',
      score: 4.8,
      recommendationCount: 27,
      localRecommendationCount: 21,
      workedResidences: ['إقامة الياسمين', 'إقامة النخيل'],
      reviews: [],
    ),
    const DirectoryEntry(
      id: 'dar-restaurant',
      name: 'مطعم الدار',
      category: DirectoryCategory.restaurant,
      profession: 'مطبخ مغربي وعائلي',
      phone: '05 22 33 44 55',
      score: 4.7,
      recommendationCount: 42,
      localRecommendationCount: 36,
      workedResidences: [],
      reviews: [
        DirectoryReview(
          author: 'مريم أ.',
          residence: 'إقامة الياسمين',
          comment: 'قريب ومناسب للعائلات، والطاجين ممتاز.',
          timeLabel: 'منذ 5 أيام',
        ),
      ],
      neighborhood: 'بوركون',
    ),
    const DirectoryEntry(
      id: 'olive-cafe',
      name: 'مقهى الزيتون',
      category: DirectoryCategory.cafe,
      profession: 'قهوة وفطور',
      phone: '05 22 44 55 66',
      score: 4.6,
      recommendationCount: 24,
      localRecommendationCount: 16,
      workedResidences: [],
      reviews: [],
      neighborhood: 'المعاريف',
    ),
    const DirectoryEntry(
      id: 'chifae-pharmacy',
      name: 'صيدلية الشفاء',
      category: DirectoryCategory.pharmacy,
      profession: 'صيدلية مناوبة وخدمة الحي',
      phone: '05 22 55 66 77',
      score: 4.8,
      recommendationCount: 31,
      localRecommendationCount: 20,
      workedResidences: [],
      reviews: [],
      neighborhood: 'الوازيس',
    ),
    const DirectoryEntry(
      id: 'sports-center',
      name: 'المركب الرياضي للقرب',
      category: DirectoryCategory.facility,
      profession: 'ملاعب وأنشطة للأطفال',
      phone: '05 22 66 77 88',
      score: 4.5,
      recommendationCount: 18,
      localRecommendationCount: 11,
      workedResidences: [],
      reviews: [],
      neighborhood: 'الحي الحسني',
    ),
  ];

  @override
  List<DirectoryEntry> getEntries() => List.unmodifiable(_entries);

  @override
  DirectoryEntry? getEntry(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  DirectoryEntry recommend({required String id, required String comment}) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) throw StateError('Directory entry not found: $id');
    final current = _entries[index];
    final updated = current.copyWith(
      recommendationCount: current.recommendationCount + 1,
      localRecommendationCount: current.localRecommendationCount + 1,
      reviews: [
        DirectoryReview(
          author: 'أنت',
          residence: 'إقامة الياسمين',
          comment: comment,
          timeLabel: 'الآن',
        ),
        ...current.reviews,
      ],
    );
    _entries[index] = updated;
    return updated;
  }
}

final directoryRepositoryProvider = Provider<DirectoryRepository>(
  (ref) => MockDirectoryRepository(),
);

final directoryEntriesProvider =
    NotifierProvider<DirectoryController, List<DirectoryEntry>>(
      DirectoryController.new,
    );

class DirectoryController extends Notifier<List<DirectoryEntry>> {
  @override
  List<DirectoryEntry> build() {
    return ref.read(directoryRepositoryProvider).getEntries();
  }

  DirectoryEntry? find(String id) {
    return ref.read(directoryRepositoryProvider).getEntry(id);
  }

  void recommend({required String id, required String comment}) {
    ref.read(directoryRepositoryProvider).recommend(id: id, comment: comment);
    state = ref.read(directoryRepositoryProvider).getEntries();
  }
}
