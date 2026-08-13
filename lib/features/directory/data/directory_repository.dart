import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/foundation.dart';
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
    required this.subcategoryIds,
    required this.profession,
    required this.phone,
    required this.score,
    required this.recommendationCount,
    required this.localRecommendationCount,
    required this.workedResidences,
    required this.reviews,
    this.neighborhood = 'المعاريف',
    this.createdBy = '',
    this.city = '',
  });

  final String id;
  final String name;
  final String categoryId;
  final List<String> subcategoryIds;
  final String profession;
  final String phone;
  final double score;
  final int recommendationCount;
  final int localRecommendationCount;
  final List<String> workedResidences;
  final List<DirectoryReview> reviews;
  final String neighborhood;
  final String createdBy;
  final String city;

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
      subcategoryIds: subcategoryIds,
      profession: profession,
      phone: phone,
      score: score,
      recommendationCount: recommendationCount ?? this.recommendationCount,
      localRecommendationCount:
          localRecommendationCount ?? this.localRecommendationCount,
      workedResidences: workedResidences ?? this.workedResidences,
      reviews: reviews ?? this.reviews,
      neighborhood: neighborhood,
      createdBy: createdBy,
      city: city,
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
  Stream<List<DirectoryEntry>> watchEntries({
    required String city,
    required int limit,
  });

  Future<String> createService({
    required String residenceId,
    required String userId,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
    required String profession,
    required String phone,
    required String neighborhood,
  });

  Future<void> updateService({
    required String serviceId,
    required String userId,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
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
  Stream<List<DirectoryEntry>> watchEntries({
    required String city,
    required int limit,
  }) {
    return _firestore
        .collection('services')
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .where((document) => document.data()['status'] == 'active')
              .map(_fromDocument)
              .toList();
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
    required List<String> subcategoryIds,
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
        subcategoryIds.isEmpty ||
        subcategoryIds.length > 8 ||
        subcategoryIds.toSet().length != subcategoryIds.length ||
        normalizedProfession.length > 160 ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalizedPhone) ||
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
      final validSubcategoryIds = List<String>.from(
        categoryData?['subcategoryIds'] as List? ?? const [],
      );
      final city = residenceData?['city'] as String? ?? '';
      if (!results[1].exists || memberData?['status'] != 'active') {
        throw const DirectoryFailure('not-a-member');
      }
      if (!RegExp(r'^[0-9]{7,10}$').hasMatch(city)) {
        throw const DirectoryFailure('invalid-city');
      }
      if (!results[2].exists ||
          !subcategoryIds.every(validSubcategoryIds.contains)) {
        throw const DirectoryFailure('invalid-category');
      }
      final service = _firestore.collection('services').doc();
      await service.set({
        'name': normalizedName,
        'categoryId': categoryId,
        'subcategoryIds': subcategoryIds,
        'profession': normalizedProfession,
        'phone': normalizedPhone,
        'neighborhood': normalizedNeighborhood,
        'city': city,
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

  @override
  Future<void> updateService({
    required String serviceId,
    required String userId,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    final normalizedName = name.trim();
    final normalizedProfession = profession.trim();
    final normalizedPhone = phone.trim();
    final normalizedNeighborhood = neighborhood.trim();
    if (serviceId.isEmpty ||
        normalizedName.isEmpty ||
        normalizedName.length > 120 ||
        categoryId.isEmpty ||
        subcategoryIds.isEmpty ||
        subcategoryIds.length > 8 ||
        subcategoryIds.toSet().length != subcategoryIds.length ||
        normalizedProfession.length > 160 ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalizedPhone) ||
        normalizedNeighborhood.length > 120) {
      throw const DirectoryFailure('invalid-service');
    }
    try {
      final service = _firestore.collection('services').doc(serviceId);
      final results = await Future.wait([
        service.get(),
        _firestore.collection('serviceCategories').doc(categoryId).get(),
      ]);
      final serviceData = results[0].data();
      final categoryData = results[1].data();
      final validSubcategoryIds = List<String>.from(
        categoryData?['subcategoryIds'] as List? ?? const [],
      );
      if (!results[0].exists || serviceData?['createdBy'] != userId) {
        throw const DirectoryFailure('not-service-owner');
      }
      if (!results[1].exists ||
          !subcategoryIds.every(validSubcategoryIds.contains)) {
        throw const DirectoryFailure('invalid-category');
      }
      await service.update({
        'name': normalizedName,
        'categoryId': categoryId,
        'subcategoryIds': subcategoryIds,
        'profession': normalizedProfession,
        'phone': normalizedPhone,
        'neighborhood': normalizedNeighborhood,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
      subcategoryIds: data['subcategoryIds'] is List
          ? List<String>.from(data['subcategoryIds'] as List)
          : [if (data['subcategoryId'] case final String legacyId) legacyId],
      profession: data['profession'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      score: 0,
      recommendationCount: 0,
      localRecommendationCount: 0,
      workedResidences: const [],
      reviews: const [],
      neighborhood: data['neighborhood'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      city: data['city'] as String? ?? '',
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
  static const pageSize = 20;

  StreamSubscription<List<DirectoryEntry>>? _entriesSubscription;
  StreamSubscription<List<DirectoryRecommendation>>?
  _recommendationsSubscription;
  Timer? _entriesRetryTimer;
  List<DirectoryEntry> _baseEntries = const [];
  List<DirectoryRecommendation> _recommendations = const [];
  String? _activeResidenceId;
  String? _activeCity;
  int _entryLimit = pageSize;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  List<DirectoryEntry> build() {
    final activeCity = ref.watch(
      residenceContextProvider.select(
        (state) => state.value?.activeResidence?.city,
      ),
    );
    ref.onDispose(() {
      _entriesRetryTimer?.cancel();
      _entriesSubscription?.cancel();
      _recommendationsSubscription?.cancel();
    });
    unawaited(_bindEntries(activeCity));
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
    required List<String> subcategoryIds,
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
    final id = await ref
        .read(directoryRepositoryProvider)
        .createService(
          residenceId: residence.id,
          userId: user.uid,
          name: name,
          categoryId: categoryId,
          subcategoryIds: subcategoryIds,
          profession: profession,
          phone: phone,
          neighborhood: neighborhood,
        );
    if (!_baseEntries.any((entry) => entry.id == id)) {
      _baseEntries = [
        DirectoryEntry(
          id: id,
          name: name.trim(),
          categoryId: categoryId,
          subcategoryIds: List.unmodifiable(subcategoryIds),
          profession: profession.trim(),
          phone: phone.trim(),
          score: 0,
          recommendationCount: 0,
          localRecommendationCount: 0,
          workedResidences: const [],
          reviews: const [],
          neighborhood: neighborhood.trim(),
          createdBy: user.uid,
          city: residence.city,
        ),
        ..._baseEntries,
      ];
      _rebuild();
    }
    return id;
  }

  Future<void> updateService({
    required String id,
    required String name,
    required String categoryId,
    required List<String> subcategoryIds,
    required String profession,
    required String phone,
    required String neighborhood,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const DirectoryFailure('missing-user');
    }
    await ref
        .read(directoryRepositoryProvider)
        .updateService(
          serviceId: id,
          userId: user.uid,
          name: name,
          categoryId: categoryId,
          subcategoryIds: subcategoryIds,
          profession: profession,
          phone: phone,
          neighborhood: neighborhood,
        );
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _entryLimit += pageSize;
    await _bindEntries(_activeCity);
  }

  Future<void> refresh() async {
    final context = await ref.read(residenceContextProvider.future);
    await _bindEntries(context.activeResidence?.city);
  }

  Future<void> _bindEntries(String? city) async {
    _entriesRetryTimer?.cancel();
    await _entriesSubscription?.cancel();
    if (_activeCity != city) _entryLimit = pageSize;
    _activeCity = city;
    if (city == null || city.isEmpty) {
      _baseEntries = const [];
      _hasMore = false;
      _loadingMore = false;
      _rebuild();
      return;
    }
    final firstSnapshot = Completer<void>();
    _entriesSubscription = ref
        .read(directoryRepositoryProvider)
        .watchEntries(city: city, limit: _entryLimit)
        .listen(
          (entries) {
            if (_activeCity != city) return;
            _baseEntries = entries;
            _hasMore = entries.length == _entryLimit;
            _loadingMore = false;
            _rebuild();
            if (!firstSnapshot.isCompleted) firstSnapshot.complete();
          },
          onError: (Object error) {
            _loadingMore = false;
            if (kDebugMode) {
              debugPrint('DarJar directory services: $error');
            }
            if (!firstSnapshot.isCompleted) firstSnapshot.complete();
            if (_activeCity == city) {
              _entriesRetryTimer = Timer(
                const Duration(seconds: 2),
                () => unawaited(_bindEntries(city)),
              );
            }
          },
        );
    await firstSnapshot.future;
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
