import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _initialActivities = <ResidenceActivity>[
  ResidenceActivity(
    id: 'activity-cleaning-expense',
    activityType: ResidenceActivityType.expenseAdded,
    category: FeedCategory.finance,
    descriptionAr: 'أضاف أحمد مصروفاً للتنظيف بقيمة 450 د',
    descriptionEn: 'Ahmed added a cleaning expense of 450 MAD',
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

class FeedActivities extends Notifier<List<ResidenceActivity>> {
  @override
  List<ResidenceActivity> build() {
    final communityRepository = ref.watch(communityRepositoryProvider);
    return communityRepository is MockCommunityRepository
        ? _initialActivities
        : const [];
  }

  void toggleLike(String activityId) {
    state = [
      for (final activity in state)
        if (activity.id == activityId)
          activity.copyWith(
            isLiked: !activity.isLiked,
            likes: activity.likes + (activity.isLiked ? -1 : 1),
          )
        else
          activity,
    ];
  }
}

final feedActivitiesProvider =
    NotifierProvider.autoDispose<FeedActivities, List<ResidenceActivity>>(
      FeedActivities.new,
    );

final feedItemsProvider = Provider.autoDispose<AsyncValue<List<FeedItem>>>((
  ref,
) {
  final postsState = ref.watch(communityPostsProvider);
  final activities = ref.watch(feedActivitiesProvider);
  return postsState.whenData((posts) => _mergeFeed(posts, activities));
});

List<FeedItem> _mergeFeed(
  List<CommunityPost> posts,
  List<ResidenceActivity> activities,
) {
  final items = <FeedItem>[];
  var activityIndex = 0;
  for (var index = 0; index < posts.length; index++) {
    items.add(PostFeedItem(posts[index]));
    if (index.isEven && activityIndex < activities.length) {
      items.add(activities[activityIndex]);
      activityIndex++;
    }
  }
  if (posts.isEmpty) items.addAll(activities);
  if (activityIndex < activities.length) {
    items.addAll(activities.skip(activityIndex));
  }
  return items;
}
