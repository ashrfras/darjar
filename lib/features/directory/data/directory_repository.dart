import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.categoryId,
    required this.subcategoryId,
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
  final String categoryId;
  final String subcategoryId;
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
    List<String>? workedResidences,
    List<DirectoryReview>? reviews,
  }) {
    return DirectoryEntry(
      id: id,
      name: name,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      profession: profession,
      phone: phone,
      score: score,
      recommendationCount: recommendationCount ?? this.recommendationCount,
      localRecommendationCount:
          localRecommendationCount ?? this.localRecommendationCount,
      workedResidences: workedResidences ?? this.workedResidences,
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
  Stream<List<DirectoryEntry>> watchEntries();

  Future<String> createService({
    required String residenceId,
    required String userId,
    required String name,
    required String categoryId,
    required String subcategoryId,
    required String profession,
    required String phone,
    required String neighborhood,
  });
}

class DirectoryFailure implements Exception {
  const DirectoryFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

class FirestoreDirectoryRepository implements DirectoryRepository {
  FirestoreDirectoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DirectoryEntry>> watchEntries() {
    return _firestore
        .collection('services')
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .where((document) => document.data()['status'] == 'active')
              .map(_fromDocument)
              .toList();
          entries.sort((a, b) => a.name.compareTo(b.name));
          return entries;
        })
        .handleError((Object error) => throw _failure(error));
  }

  @override
  Future<String> createService({
    required String residenceId,
    required String userId,
    required String name,
    required String categoryId,
    required String subcategoryId,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    final normalizedName = name.trim();
    final normalizedProfession = profession.trim();
    final normalizedPhone = phone.trim();
    final normalizedNeighborhood = neighborhood.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > 120 ||
        categoryId.isEmpty ||
        subcategoryId.isEmpty ||
        normalizedProfession.isEmpty ||
        normalizedProfession.length > 500 ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalizedPhone) ||
        normalizedNeighborhood.isEmpty ||
        normalizedNeighborhood.length > 120) {
      throw const DirectoryFailure('invalid-service');
    }
    try {
      final residence = _firestore.collection('residences').doc(residenceId);
      final results = await Future.wait([
        residence.get(),
        residence.collection('members').doc(userId).get(),
        _firestore.collection('serviceCategories').doc(categoryId).get(),
      ]);
      final residenceData = results[0].data();
      final memberData = results[1].data();
      final categoryData = results[2].data();
      final subcategoryIds = List<String>.from(
        categoryData?['subcategoryIds'] as List? ?? const [],
      );
      if (!results[1].exists || memberData?['status'] != 'active') {
        throw const DirectoryFailure('not-a-member');
      }
      if (!results[2].exists || !subcategoryIds.contains(subcategoryId)) {
        throw const DirectoryFailure('invalid-category');
      }
      final service = _firestore.collection('services').doc();
      await service.set({
        'name': normalizedName,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'profession': normalizedProfession,
        'phone': normalizedPhone,
        'neighborhood': normalizedNeighborhood,
        'createdBy': userId,
        'createdFromResidenceId': residenceId,
        'createdFromResidenceName':
            residenceData?['name'] as String? ?? residenceId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return service.id;
    } catch (error) {
      throw _failure(error);
    }
  }

  DirectoryEntry _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return DirectoryEntry(
      id: document.id,
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      subcategoryId: data['subcategoryId'] as String? ?? '',
      profession: data['profession'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      score: 0,
      recommendationCount: 0,
      localRecommendationCount: 0,
      workedResidences: const [],
      reviews: const [],
      neighborhood: data['neighborhood'] as String? ?? '',
    );
  }

  DirectoryFailure _failure(Object error) => switch (error) {
    DirectoryFailure failure => failure,
    FirebaseException(:final code, :final message) => DirectoryFailure(
      code,
      message,
    ),
    _ => DirectoryFailure('unknown', error.toString()),
  };
}

final directoryRepositoryProvider = Provider<DirectoryRepository>(
  (ref) => FirestoreDirectoryRepository(ref.watch(firebaseFirestoreProvider)),
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
  StreamSubscription<List<DirectoryEntry>>? _entriesSubscription;
  StreamSubscription<List<DirectoryRecommendation>>?
  _recommendationsSubscription;
  List<DirectoryEntry> _baseEntries = const [];
  List<DirectoryRecommendation> _recommendations = const [];
  String? _activeResidenceId;

  @override
  List<DirectoryEntry> build() {
    ref.onDispose(() {
      _entriesSubscription?.cancel();
      _recommendationsSubscription?.cancel();
    });
    _entriesSubscription = ref
        .read(directoryRepositoryProvider)
        .watchEntries()
        .listen((entries) {
          _baseEntries = entries;
          _rebuild();
        });
    unawaited(_bindRecommendations());
    return const [];
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

  Future<String> createService({
    required String name,
    required String categoryId,
    required String subcategoryId,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    final context = await ref.read(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (residence == null || user == null) {
      throw const DirectoryFailure('missing-residence');
    }
    return ref
        .read(directoryRepositoryProvider)
        .createService(
          residenceId: residence.id,
          userId: user.uid,
          name: name,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          profession: profession,
          phone: phone,
          neighborhood: neighborhood,
        );
  }

  Future<void> _bindRecommendations() async {
    final context = await ref.read(residenceContextProvider.future);
    _activeResidenceId = context.activeResidence?.id;
    await _recommendationsSubscription?.cancel();
    _recommendationsSubscription = ref
        .read(directoryRecommendationsRepositoryProvider)
        .watch()
        .listen((recommendations) {
          _recommendations = recommendations;
          _rebuild();
        });
  }

  void _rebuild() {
    state = [
      for (final entry in _baseEntries)
        _mergeEntry(
          entry,
          _recommendations
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
      workedResidences: {
        ...entry.workedResidences,
        ...recommendations.map((recommendation) => recommendation.residence),
      }.toList(),
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
