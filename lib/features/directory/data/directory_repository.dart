import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DirectoryCategory { all, craftsman, restaurant, cafe, pharmacy, facility }

class DirectoryReview {
  const DirectoryReview({
    required this.author,
    required this.residence,
    required this.comment,
    required this.timeLabel,
    this.userId = '',
  });

  final String author;
  final String residence;
  final String comment;
  final String timeLabel;
  final String userId;
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

class DirectoryRecommendation {
  const DirectoryRecommendation({
    required this.entryId,
    required this.userId,
    required this.residenceId,
    required this.author,
    required this.residence,
    required this.comment,
    required this.createdAt,
  });

  final String entryId;
  final String userId;
  final String residenceId;
  final String author;
  final String residence;
  final String comment;
  final DateTime createdAt;
}

class DirectoryRecommendationFailure implements Exception {
  const DirectoryRecommendationFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class DirectoryRecommendationsRepository {
  Stream<List<DirectoryRecommendation>> watch();

  Future<void> recommend({
    required String entryId,
    required String residenceId,
    required String userId,
    required String comment,
  });
}

class FirestoreDirectoryRecommendationsRepository
    implements DirectoryRecommendationsRepository {
  FirestoreDirectoryRecommendationsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DirectoryRecommendation>> watch() {
    return _firestore
        .collection('directoryRecommendations')
        .snapshots()
        .map(
          (snapshot) =>
              [for (final document in snapshot.docs) _fromDocument(document)]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        )
        .handleError((Object error) => throw _failure(error));
  }

  @override
  Future<void> recommend({
    required String entryId,
    required String residenceId,
    required String userId,
    required String comment,
  }) async {
    final normalizedComment = comment.trim();
    if (normalizedComment.isEmpty || normalizedComment.length > 1000) {
      throw const DirectoryRecommendationFailure('invalid-comment');
    }
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final results = await Future.wait([
        residence.get(),
        residence.collection('members').doc(userId).get(),
      ]);
      final residenceData = results[0].data();
      final memberData = results[1].data();
      if (!results[1].exists || memberData?['status'] != 'active') {
        throw const DirectoryRecommendationFailure('not-a-member');
      }
      final author =
          '${memberData?['firstName'] ?? ''} ${memberData?['lastName'] ?? ''}'
              .trim();
      final documentId = '${entryId}_${residenceId}_$userId';
      await _firestore
          .collection('directoryRecommendations')
          .doc(documentId)
          .set({
            'entryId': entryId,
            'residenceId': residenceId,
            'userId': userId,
            'authorName': author.isEmpty ? userId : author,
            'residenceName': residenceData?['name'] as String? ?? residenceId,
            'comment': normalizedComment,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      throw _failure(error);
    }
  }

  DirectoryRecommendation _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return DirectoryRecommendation(
      entryId: data['entryId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      residenceId: data['residenceId'] as String? ?? '',
      author: data['authorName'] as String? ?? '',
      residence: data['residenceName'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  DirectoryRecommendationFailure _failure(Object error) => switch (error) {
    DirectoryRecommendationFailure failure => failure,
    FirebaseException(:final code, :final message) =>
      DirectoryRecommendationFailure(code, message),
    _ => DirectoryRecommendationFailure('unknown', error.toString()),
  };
}

class MockDirectoryRecommendationsRepository
    implements DirectoryRecommendationsRepository {
  final _recommendations =
      StreamController<List<DirectoryRecommendation>>.broadcast();
  final List<DirectoryRecommendation> values = [];

  @override
  Stream<List<DirectoryRecommendation>> watch() async* {
    yield List.unmodifiable(values);
    yield* _recommendations.stream;
  }

  @override
  Future<void> recommend({
    required String entryId,
    required String residenceId,
    required String userId,
    required String comment,
  }) async {
    values.removeWhere(
      (value) =>
          value.entryId == entryId &&
          value.residenceId == residenceId &&
          value.userId == userId,
    );
    values.insert(
      0,
      DirectoryRecommendation(
        entryId: entryId,
        userId: userId,
        residenceId: residenceId,
        author: 'أنت',
        residence: 'إقامة الاختبار',
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
    _recommendations.add(List.unmodifiable(values));
  }

  void dispose() => _recommendations.close();
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

final directoryRecommendationsRepositoryProvider =
    Provider<DirectoryRecommendationsRepository>(
      (ref) => FirestoreDirectoryRecommendationsRepository(
        ref.watch(firebaseFirestoreProvider),
      ),
    );

final directoryEntriesProvider =
    NotifierProvider<DirectoryController, List<DirectoryEntry>>(
      DirectoryController.new,
    );

class DirectoryController extends Notifier<List<DirectoryEntry>> {
  StreamSubscription<List<DirectoryRecommendation>>? _subscription;
  late List<DirectoryEntry> _baseEntries;
  String? _activeResidenceId;

  @override
  List<DirectoryEntry> build() {
    _baseEntries = ref.read(directoryRepositoryProvider).getEntries();
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_bindRecommendations());
    return _baseEntries;
  }

  DirectoryEntry? find(String id) {
    for (final entry in state) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<void> recommend({required String id, required String comment}) async {
    final context = await ref.read(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (residence == null || user == null) {
      throw const DirectoryRecommendationFailure('missing-residence');
    }
    await ref
        .read(directoryRecommendationsRepositoryProvider)
        .recommend(
          entryId: id,
          residenceId: residence.id,
          userId: user.uid,
          comment: comment,
        );
  }

  Future<void> _bindRecommendations() async {
    final context = await ref.read(residenceContextProvider.future);
    _activeResidenceId = context.activeResidence?.id;
    await _subscription?.cancel();
    _subscription = ref
        .read(directoryRecommendationsRepositoryProvider)
        .watch()
        .listen(_applyRecommendations);
  }

  void _applyRecommendations(List<DirectoryRecommendation> recommendations) {
    state = [
      for (final entry in _baseEntries)
        _mergeEntry(
          entry,
          recommendations
              .where((recommendation) => recommendation.entryId == entry.id)
              .toList(growable: false),
        ),
    ];
  }

  DirectoryEntry _mergeEntry(
    DirectoryEntry entry,
    List<DirectoryRecommendation> recommendations,
  ) {
    final localCount = recommendations
        .where(
          (recommendation) => recommendation.residenceId == _activeResidenceId,
        )
        .length;
    return entry.copyWith(
      recommendationCount: entry.recommendationCount + recommendations.length,
      localRecommendationCount: entry.localRecommendationCount + localCount,
      reviews: [
        for (final recommendation in recommendations)
          DirectoryReview(
            userId: recommendation.userId,
            author: recommendation.author,
            residence: recommendation.residence,
            comment: recommendation.comment,
            timeLabel: _recommendationTimeLabel(recommendation.createdAt),
          ),
        ...entry.reviews,
      ],
    );
  }
}

String _recommendationTimeLabel(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'الآن';
  if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
  if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
  if (difference.inDays == 1) return 'أمس';
  return 'منذ ${difference.inDays} أيام';
}
