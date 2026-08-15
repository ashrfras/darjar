import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/utils/person_name.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const feedActivitiesPageSize = 5;
const feedItemsPageSize = 10;

abstract interface class FeedActivityRepository {
  Stream<List<ResidenceActivity>> watchActivities({
    required String residenceId,
    required String userId,
    required int limit,
  });

  Future<void> toggleLike({
    required String residenceId,
    required String userId,
    required String activityId,
  });
}

class FirebaseFeedActivityRepository implements FeedActivityRepository {
  FirebaseFeedActivityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ResidenceActivity>> watchActivities({
    required String residenceId,
    required String userId,
    required int limit,
  }) {
    return _activities(residenceId)
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => _fromDocument(document, userId))
              .whereType<ResidenceActivity>()
              .toList(growable: false),
        );
  }

  @override
  Future<void> toggleLike({
    required String residenceId,
    required String userId,
    required String activityId,
  }) async {
    final reference = _activities(residenceId).doc(activityId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) {
          throw const CommunityFailure('activity-not-found');
        }
        final likedBy = List<String>.from(
          snapshot.data()?['likedBy'] as List? ?? const [],
        );
        likedBy.contains(userId) ? likedBy.remove(userId) : likedBy.add(userId);
        transaction.update(reference, {
          'likedBy': likedBy,
          'likesCount': likedBy.length,
        });
      });
    } catch (error) {
      if (error is CommunityFailure) rethrow;
      throw CommunityFailure('activity-like-failed', error.toString());
    }
  }

  CollectionReference<Map<String, dynamic>> _activities(String residenceId) {
    return _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('feedActivities');
  }

  ResidenceActivity? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String userId,
  ) {
    final data = document.data();
    final type = _activityType(data['type']);
    if (type == null) return null;
    final payload = Map<String, Object?>.from(
      data['payload'] as Map? ?? const {},
    );
    final actorName = data['actorName'] as String? ?? '';
    final occurredAt = (data['occurredAt'] as Timestamp?)?.toDate();
    final likedBy = List<String>.from(data['likedBy'] as List? ?? const []);
    final copy = _activityCopy(type, payload, actorName);
    final referenceType = _entityType(data['referenceType']);
    return ResidenceActivity(
      id: document.id,
      activityType: type,
      category: _category(data['category']) ?? _categoryFor(type),
      descriptionAr: copy.descriptionAr,
      descriptionEn: copy.descriptionEn,
      timeLabelAr: _timeLabel(occurredAt, arabic: true),
      timeLabelEn: _timeLabel(occurredAt, arabic: false),
      classificationAr: copy.classificationAr,
      classificationEn: copy.classificationEn,
      likes: data['likesCount'] as int? ?? likedBy.length,
      isLiked: likedBy.contains(userId),
      reference: referenceType == null
          ? null
          : FeedEntityReference(
              type: referenceType,
              entityId: data['referenceId'] as String?,
            ),
    );
  }
}

class MockFeedActivityRepository implements FeedActivityRepository {
  final _changes = StreamController<List<ResidenceActivity>>.broadcast();
  final _activities = [..._initialActivities];

  @override
  Stream<List<ResidenceActivity>> watchActivities({
    required String residenceId,
    required String userId,
    required int limit,
  }) async* {
    yield _activities.take(limit).toList(growable: false);
    yield* _changes.stream.map(
      (activities) => activities.take(limit).toList(growable: false),
    );
  }

  @override
  Future<void> toggleLike({
    required String residenceId,
    required String userId,
    required String activityId,
  }) async {
    final index = _activities.indexWhere((item) => item.id == activityId);
    if (index < 0) throw const CommunityFailure('activity-not-found');
    final activity = _activities[index];
    _activities[index] = activity.copyWith(
      isLiked: !activity.isLiked,
      likes: activity.likes + (activity.isLiked ? -1 : 1),
    );
    _changes.add(List.unmodifiable(_activities));
  }

  void dispose() => _changes.close();
}

final feedActivityRepositoryProvider = Provider<FeedActivityRepository>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  if (communityRepository is MockCommunityRepository) {
    final repository = MockFeedActivityRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirebaseFeedActivityRepository(ref.watch(firebaseFirestoreProvider));
});

class FeedActivitiesLimit extends Notifier<int> {
  @override
  int build() => feedActivitiesPageSize;

  void loadMore() => state += feedActivitiesPageSize;
}

final feedActivitiesLimitProvider =
    NotifierProvider.autoDispose<FeedActivitiesLimit, int>(
      FeedActivitiesLimit.new,
    );

final feedActivitiesProvider =
    StreamProvider.autoDispose<List<ResidenceActivity>>((ref) async* {
      final limit = ref.watch(feedActivitiesLimitProvider);
      final context = await ref.watch(residenceContextProvider.future);
      final residence = context.activeResidence;
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (residence == null || user == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(feedActivityRepositoryProvider)
          .watchActivities(
            residenceId: residence.id,
            userId: user.uid,
            limit: limit,
          );
    });

final feedActivityActionsProvider = Provider(FeedActivityActions.new);

class FeedActivityActions {
  FeedActivityActions(this._ref);

  final Ref _ref;

  Future<void> toggleLike(String activityId) async {
    final context = await _ref.read(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (residence == null || user == null) {
      throw const CommunityFailure('missing-feed-context');
    }
    await _ref
        .read(feedActivityRepositoryProvider)
        .toggleLike(
          residenceId: residence.id,
          userId: user.uid,
          activityId: activityId,
        );
  }
}

final feedItemsProvider = Provider.autoDispose<AsyncValue<List<FeedItem>>>((
  ref,
) {
  final postsState = ref.watch(communityPostsProvider);
  final activitiesState = ref.watch(feedActivitiesProvider);
  final posts = postsState.value;
  final activities = activitiesState.value;
  if (posts != null) {
    return AsyncData(_mergeFeed(posts, activities ?? const []));
  }
  if (postsState.hasError) {
    return AsyncError(postsState.error!, postsState.stackTrace!);
  }
  if (activitiesState.hasError) {
    return AsyncError(activitiesState.error!, activitiesState.stackTrace!);
  }
  return const AsyncLoading();
});

List<FeedItem> _mergeFeed(
  List<CommunityPost> posts,
  List<ResidenceActivity> activities,
) {
  final items = <FeedItem>[];
  final regularPosts = posts.where((post) => !post.isSystem).toList();
  final systemPosts = posts.where((post) => post.isSystem).toList();
  var activityIndex = 0;
  for (var index = 0; index < regularPosts.length; index++) {
    items.add(PostFeedItem(regularPosts[index]));
    if (index.isEven && activityIndex < activities.length) {
      items.add(activities[activityIndex++]);
    }
  }
  if (regularPosts.isEmpty) items.addAll(activities);
  if (activityIndex < activities.length) {
    items.addAll(activities.skip(activityIndex));
  }
  items.addAll(systemPosts.map(PostFeedItem.new));
  return items;
}

const _initialActivities = <ResidenceActivity>[
  ResidenceActivity(
    id: 'activity-cleaning-expense',
    activityType: ResidenceActivityType.expenseAdded,
    category: FeedCategory.finance,
    descriptionAr: 'أضاف أحمد م. مصروفاً للتنظيف بقيمة 450 د',
    descriptionEn: 'Ahmed M. added a cleaning expense of 450 MAD',
    timeLabelAr: 'منذ 35 دقيقة',
    timeLabelEn: '35 min ago',
    classificationAr: 'مصروف',
    classificationEn: 'Expense',
    likes: 3,
    reference: FeedEntityReference(type: FeedEntityType.transaction),
  ),
  ResidenceActivity(
    id: 'activity-august-due',
    activityType: ResidenceActivityType.duePaid,
    category: FeedCategory.finance,
    descriptionAr: 'تم تسجيل أداء اشتراك شهر أغسطس للشقة 12',
    descriptionEn: 'The August due was recorded for apartment 12',
    timeLabelAr: 'منذ ساعتين',
    timeLabelEn: '2 hours ago',
    classificationAr: 'الاشتراكات',
    classificationEn: 'Dues',
    likes: 1,
    reference: FeedEntityReference(type: FeedEntityType.dues),
  ),
  ResidenceActivity(
    id: 'activity-meeting-document',
    activityType: ResidenceActivityType.documentAdded,
    category: FeedCategory.documents,
    descriptionAr: 'تمت إضافة وثيقة جديدة: محضر الجمع العام',
    descriptionEn: 'A new document was added: General assembly minutes',
    timeLabelAr: 'منذ يوم',
    timeLabelEn: 'Yesterday',
    classificationAr: 'وثيقة',
    classificationEn: 'Document',
    likes: 5,
    reference: FeedEntityReference(
      type: FeedEntityType.document,
      entityId: 'general-assembly-minutes',
    ),
  ),
  ResidenceActivity(
    id: 'activity-new-poll',
    activityType: ResidenceActivityType.pollCreated,
    category: FeedCategory.polls,
    descriptionAr: 'تم إنشاء استطلاع جديد حول تهيئة الحديقة',
    descriptionEn: 'A new poll was created about improving the garden',
    timeLabelAr: 'منذ يومين',
    timeLabelEn: '2 days ago',
    classificationAr: 'استطلاع',
    classificationEn: 'Poll',
    likes: 2,
    reference: FeedEntityReference(
      type: FeedEntityType.post,
      entityId: 'poll-garden',
    ),
  ),
];

ResidenceActivityType? _activityType(Object? value) => ResidenceActivityType
    .values
    .where((type) => type.name == value)
    .firstOrNull;

FeedCategory? _category(Object? value) =>
    FeedCategory.values.where((category) => category.name == value).firstOrNull;

FeedEntityType? _entityType(Object? value) =>
    FeedEntityType.values.where((type) => type.name == value).firstOrNull;

FeedCategory _categoryFor(ResidenceActivityType type) => switch (type) {
  ResidenceActivityType.expenseAdded ||
  ResidenceActivityType.duePaid ||
  ResidenceActivityType.monthlyDueChanged => FeedCategory.finance,
  ResidenceActivityType.documentAdded => FeedCategory.documents,
  ResidenceActivityType.serviceAdded => FeedCategory.services,
  ResidenceActivityType.announcementPublished => FeedCategory.announcements,
  ResidenceActivityType.pollCreated => FeedCategory.polls,
};

({
  String descriptionAr,
  String descriptionEn,
  String classificationAr,
  String classificationEn,
})
_activityCopy(
  ResidenceActivityType type,
  Map<String, Object?> payload,
  String actorName,
) {
  final abbreviatedActor = abbreviatedPersonName(actorName);
  final actorAr = actorName.isEmpty ? 'المسؤول' : abbreviatedActor;
  final actorEn = actorName.isEmpty ? 'Management' : abbreviatedActor;
  final title = payload['title']?.toString() ?? '';
  final expenseTitleAr = _localizedExpenseTitle(payload, arabic: true);
  final expenseTitleEn = _localizedExpenseTitle(payload, arabic: false);
  final expensePurposeAr = expenseTitleAr.startsWith('ال')
      ? 'ل${expenseTitleAr.substring(1)}'
      : 'لـ$expenseTitleAr';
  final amount = payload['amount']?.toString() ?? '';
  final apartment = payload['apartmentNumber']?.toString() ?? '';
  final period = payload['periodKey']?.toString() ?? '';
  final previousAmount = payload['previousAmount']?.toString() ?? '';
  final newAmount = payload['newAmount']?.toString() ?? '';
  return switch (type) {
    ResidenceActivityType.expenseAdded => (
      descriptionAr: 'أضاف $actorAr مصروفاً $expensePurposeAr بقيمة $amount د',
      descriptionEn: '$actorEn added a $expenseTitleEn expense of $amount MAD',
      classificationAr: 'مصروف',
      classificationEn: 'Expense',
    ),
    ResidenceActivityType.duePaid => (
      descriptionAr: 'تم تسجيل أداء اشتراك $period للشقة $apartment',
      descriptionEn: 'The $period due was recorded for apartment $apartment',
      classificationAr: 'الاشتراكات',
      classificationEn: 'Dues',
    ),
    ResidenceActivityType.monthlyDueChanged => (
      descriptionAr:
          'تم تعديل قيمة الاشتراك الشهري من $previousAmount إلى $newAmount د',
      descriptionEn:
          'The monthly due changed from $previousAmount to $newAmount MAD',
      classificationAr: 'الاشتراكات',
      classificationEn: 'Dues',
    ),
    ResidenceActivityType.documentAdded => (
      descriptionAr: 'تمت إضافة وثيقة جديدة: $title',
      descriptionEn: 'A new document was added: $title',
      classificationAr: 'وثيقة',
      classificationEn: 'Document',
    ),
    ResidenceActivityType.serviceAdded => (
      descriptionAr: 'أضاف $actorAr خدمة جديدة: $title',
      descriptionEn: '$actorEn added a new service: $title',
      classificationAr: 'خدمة',
      classificationEn: 'Service',
    ),
    ResidenceActivityType.announcementPublished => (
      descriptionAr: 'نشر المسؤول تنبيهاً جديداً: $title',
      descriptionEn: 'Management published a new announcement: $title',
      classificationAr: 'إعلان',
      classificationEn: 'Announcement',
    ),
    ResidenceActivityType.pollCreated => (
      descriptionAr: 'تم إنشاء استطلاع جديد: $title',
      descriptionEn: 'A new poll was created: $title',
      classificationAr: 'استطلاع',
      classificationEn: 'Poll',
    ),
  };
}

String _localizedExpenseTitle(
  Map<String, Object?> payload, {
  required bool arabic,
}) {
  final title = payload['title']?.toString() ?? '';
  final category =
      (payload['expenseCategory']?.toString().trim().isNotEmpty ?? false)
      ? payload['expenseCategory']!.toString()
      : title;
  final normalized = category.trim().toLowerCase();
  final localized = arabic
      ? const {
          'maintenance': 'الصيانة والإصلاحات',
          'utilities': 'الماء والكهرباء',
          'cleaning': 'النظافة',
          'security': 'الحراسة',
          'custom': 'مصروف مخصص',
        }
      : const {
          'maintenance': 'maintenance and repairs',
          'utilities': 'water and electricity',
          'cleaning': 'cleaning',
          'security': 'security',
          'custom': 'custom',
        };
  return localized[normalized] ?? title;
}

String _timeLabel(DateTime? value, {required bool arabic}) {
  if (value == null) return arabic ? 'الآن' : 'Now';
  final elapsed = DateTime.now().difference(value);
  if (elapsed.inMinutes < 1) return arabic ? 'الآن' : 'Now';
  if (elapsed.inMinutes < 60) {
    return arabic
        ? 'منذ ${elapsed.inMinutes} دقيقة'
        : '${elapsed.inMinutes} min ago';
  }
  if (elapsed.inHours < 24) {
    return arabic ? 'منذ ${elapsed.inHours} س' : '${elapsed.inHours} h ago';
  }
  return arabic ? 'منذ ${elapsed.inDays} يوم' : '${elapsed.inDays} d ago';
}
