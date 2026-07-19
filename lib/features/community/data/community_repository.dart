import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CommunityPostKind { announcement, resident }

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.timeLabel,
    required this.title,
    required this.body,
    required this.kind,
    required this.likes,
    required this.comments,
  });

  final String id;
  final String author;
  final String timeLabel;
  final String title;
  final String body;
  final CommunityPostKind kind;
  final int likes;
  final int comments;
}

abstract interface class CommunityRepository {
  List<CommunityPost> getPosts();

  CommunityPost createPost({required String title, required String body});
}

class MockCommunityRepository implements CommunityRepository {
  final List<CommunityPost> _posts = [
    const CommunityPost(
      id: 'announcement-water',
      author: 'إدارة الإقامة',
      timeLabel: 'منذ 10 دقائق',
      title: 'انقطاع الماء غداً',
      body:
          'سيتم قطع الماء يوم غد الأربعاء من 10:00 صباحاً إلى 4:00 مساءً. نرجو أخذ الاحتياطات اللازمة.',
      kind: CommunityPostKind.announcement,
      likes: 12,
      comments: 8,
    ),
    const CommunityPost(
      id: 'resident-welcome',
      author: 'سلمى الإدريسي',
      timeLabel: 'منذ ساعة',
      title: 'مرحباً بالجيران الجدد',
      body:
          'يسعدنا انضمام سكان الطابق الرابع. أهلاً وسهلاً بكم في إقامة الياسمين.',
      kind: CommunityPostKind.resident,
      likes: 7,
      comments: 3,
    ),
  ];

  @override
  List<CommunityPost> getPosts() => List.unmodifiable(_posts);

  @override
  CommunityPost createPost({required String title, required String body}) {
    final post = CommunityPost(
      id: 'post-${_posts.length + 1}',
      author: 'أحمد من العمارة',
      timeLabel: 'الآن',
      title: title,
      body: body,
      kind: CommunityPostKind.resident,
      likes: 0,
      comments: 0,
    );
    _posts.insert(0, post);
    return post;
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => MockCommunityRepository(),
);

final communityPostsProvider =
    NotifierProvider<CommunityPostsController, List<CommunityPost>>(
      CommunityPostsController.new,
    );

class CommunityPostsController extends Notifier<List<CommunityPost>> {
  @override
  List<CommunityPost> build() {
    return ref.read(communityRepositoryProvider).getPosts();
  }

  void createPost({required String title, required String body}) {
    ref.read(communityRepositoryProvider).createPost(title: title, body: body);
    state = ref.read(communityRepositoryProvider).getPosts();
  }
}
