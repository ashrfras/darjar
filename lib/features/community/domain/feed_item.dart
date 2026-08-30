import 'package:darjar/features/community/data/community_repository.dart';

enum FeedItemType { post, activity }

enum FeedCategory { posts, finance, announcements, polls, documents, services }

enum ResidenceActivityType {
  expenseAdded,
  duePaid,
  monthlyDueChanged,
  documentAdded,
  serviceAdded,
  announcementPublished,
  pollCreated,
}

enum FeedEntityType { transaction, dues, document, service, post }

class FeedEntityReference {
  const FeedEntityReference({required this.type, this.entityId});

  final FeedEntityType type;
  final String? entityId;
}

sealed class FeedItem {
  const FeedItem({
    required this.id,
    required this.type,
    required this.category,
    required this.occurredAt,
  });

  final String id;
  final FeedItemType type;
  final FeedCategory category;
  final DateTime? occurredAt;
}

class PostFeedItem extends FeedItem {
  PostFeedItem(this.post)
    : super(
        id: 'post-${post.id}',
        type: FeedItemType.post,
        occurredAt: post.createdAt,
        category: post.kind == CommunityPostKind.poll
            ? FeedCategory.polls
            : post.kind == CommunityPostKind.announcement ||
                  post.kind == CommunityPostKind.alert
            ? FeedCategory.announcements
            : FeedCategory.posts,
      );

  final CommunityPost post;
}

class ResidenceActivity extends FeedItem {
  const ResidenceActivity({
    required super.id,
    required this.activityType,
    required super.category,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionZgh,
    required this.timeLabelAr,
    required this.timeLabelEn,
    required this.timeLabelZgh,
    required this.likes,
    this.isLiked = false,
    this.classificationAr,
    this.classificationEn,
    this.classificationZgh,
    this.reference,
    this.apartmentNumber,
    this.periodKey,
    super.occurredAt,
  }) : super(type: FeedItemType.activity);

  final ResidenceActivityType activityType;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionZgh;
  final String timeLabelAr;
  final String timeLabelEn;
  final String timeLabelZgh;
  final int likes;
  final bool isLiked;
  final String? classificationAr;
  final String? classificationEn;
  final String? classificationZgh;
  final FeedEntityReference? reference;
  final String? apartmentNumber;
  final String? periodKey;

  ResidenceActivity copyWith({
    int? likes,
    bool? isLiked,
    String? descriptionAr,
    String? descriptionEn,
    String? descriptionZgh,
    String? periodKey,
  }) {
    return ResidenceActivity(
      id: id,
      activityType: activityType,
      category: category,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionZgh: descriptionZgh ?? this.descriptionZgh,
      timeLabelAr: timeLabelAr,
      timeLabelEn: timeLabelEn,
      timeLabelZgh: timeLabelZgh,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      classificationAr: classificationAr,
      classificationEn: classificationEn,
      classificationZgh: classificationZgh,
      reference: reference,
      apartmentNumber: apartmentNumber,
      periodKey: periodKey ?? this.periodKey,
      occurredAt: occurredAt,
    );
  }
}
