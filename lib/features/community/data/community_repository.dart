import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CommunityPostKind {
  announcement,
  question,
  complaint,
  suggestion,
  alert,
  general,
  poll,
  event,
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.author,
    required this.body,
    required this.timeLabel,
    this.isAuthor = false,
  });

  final String id;
  final String author;
  final String body;
  final String timeLabel;
  final bool isAuthor;
}

class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.votes,
  });

  final String id;
  final String label;
  final int votes;

  PollOption copyWith({int? votes}) =>
      PollOption(id: id, label: label, votes: votes ?? this.votes);
}

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
    this.authorUnit,
    this.isOfficial = false,
    this.isLiked = false,
    this.isSaved = false,
    this.visualSeed = 0,
    this.pollOptions = const [],
    this.selectedPollOptionId,
    this.eventDate,
    this.eventLocation,
  });

  final String id;
  final String author;
  final String? authorUnit;
  final String timeLabel;
  final String title;
  final String body;
  final CommunityPostKind kind;
  final int likes;
  final List<CommunityComment> comments;
  final bool isOfficial;
  final bool isLiked;
  final bool isSaved;
  final int visualSeed;
  final List<PollOption> pollOptions;
  final String? selectedPollOptionId;
  final String? eventDate;
  final String? eventLocation;

  CommunityPost copyWith({
    int? likes,
    List<CommunityComment>? comments,
    bool? isLiked,
    bool? isSaved,
    List<PollOption>? pollOptions,
    String? selectedPollOptionId,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      authorUnit: authorUnit,
      timeLabel: timeLabel,
      title: title,
      body: body,
      kind: kind,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isOfficial: isOfficial,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      visualSeed: visualSeed,
      pollOptions: pollOptions ?? this.pollOptions,
      selectedPollOptionId: selectedPollOptionId ?? this.selectedPollOptionId,
      eventDate: eventDate,
      eventLocation: eventLocation,
    );
  }
}

abstract interface class CommunityRepository {
  List<CommunityPost> getPosts();

  CommunityPost? getPost(String id);

  CommunityPost createPost({
    required String title,
    required String body,
    CommunityPostKind kind,
    List<String> pollOptions,
    String? eventDate,
    String? eventLocation,
  });

  void toggleLike(String postId);

  void toggleSaved(String postId);

  void addComment(String postId, String body);

  void vote(String postId, String optionId);
}

class MockCommunityRepository implements CommunityRepository {
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: 'announcement-elevator',
      author: 'السانديك',
      authorUnit: 'إدارة الإقامة',
      timeLabel: 'منذ 30 دقيقة',
      title: 'صيانة المصاعد يوم الخميس القادم',
      body:
          'سيتم إجراء صيانة دورية للمصاعد يوم الخميس 25 يوليو من الساعة 9 صباحاً إلى 1 ظهراً. يرجى استعمال الدرج خلال هذه الفترة.',
      kind: CommunityPostKind.announcement,
      likes: 12,
      isOfficial: true,
      visualSeed: 1,
      comments: const [
        CommunityComment(
          id: 'c1',
          author: 'أمينة ب.',
          body: 'شكراً على الإخبار المسبق.',
          timeLabel: 'منذ 12 دقيقة',
        ),
        CommunityComment(
          id: 'c2',
          author: 'يونس العلوي',
          body: 'هل ستشمل الصيانة مصعد العمارة ب أيضاً؟',
          timeLabel: 'منذ 5 دقائق',
        ),
      ],
    ),
    CommunityPost(
      id: 'question-plumber',
      author: 'أحمد م.',
      authorUnit: 'العمارة أ · شقة 12',
      timeLabel: 'منذ ساعة',
      title: 'هل أحد لديه رقم سبّاك موثوق؟',
      body:
          'عندي تسرّب في المطبخ وأبحث عن سبّاك موثوق وبسعر مناسب. يفضّل أن يكون متاحاً اليوم.',
      kind: CommunityPostKind.question,
      likes: 4,
      visualSeed: 2,
      comments: const [
        CommunityComment(
          id: 'c3',
          author: 'سارة المنصوري',
          body: 'أنصحك بعبد الرحيم، تعاملنا معه أكثر من مرة.',
          timeLabel: 'منذ 40 دقيقة',
        ),
      ],
    ),
    CommunityPost(
      id: 'complaint-noise',
      author: 'نورة س.',
      authorUnit: 'العمارة ج · الطابق 2',
      timeLabel: 'منذ ساعتين',
      title: 'ضجيج في الحديقة ليلاً',
      body:
          'الرجاء من الجميع مراعاة الهدوء بعد الساعة 11 ليلاً في الحديقة، خصوصاً خلال أيام الأسبوع.',
      kind: CommunityPostKind.complaint,
      likes: 5,
      visualSeed: 3,
      comments: const [
        CommunityComment(
          id: 'c4',
          author: 'محمد ك.',
          body: 'متفق، الهدوء مهم خصوصاً للأطفال.',
          timeLabel: 'منذ ساعة',
        ),
        CommunityComment(
          id: 'c5',
          author: 'ليلى أ.',
          body: 'سنذكّر الأطفال بموعد إغلاق الحديقة.',
          timeLabel: 'منذ 45 دقيقة',
        ),
      ],
    ),
    const CommunityPost(
      id: 'suggestion-trees',
      author: 'محمد ك.',
      authorUnit: 'العمارة ب · شقة 7',
      timeLabel: 'منذ 3 ساعات',
      title: 'زراعة المزيد من الأشجار',
      body:
          'أقترح على السانديك زراعة المزيد من الأشجار في المنطقة الشرقية للحديقة وتخصيص يوم تطوعي للسكان.',
      kind: CommunityPostKind.suggestion,
      likes: 15,
      visualSeed: 4,
      comments: [],
    ),
    const CommunityPost(
      id: 'alert-water',
      author: 'السانديك',
      authorUnit: 'إدارة الإقامة',
      timeLabel: 'منذ 4 ساعات',
      title: 'انقطاع الماء غداً صباحاً',
      body:
          'حسب إشعار الشركة، سيكون هناك انقطاع للماء غداً من 6 صباحاً إلى 10 صباحاً بسبب أشغال في الحي.',
      kind: CommunityPostKind.alert,
      likes: 18,
      isOfficial: true,
      visualSeed: 5,
      comments: [],
    ),
    CommunityPost(
      id: 'poll-garden',
      author: 'سلمى الإدريسي',
      authorUnit: 'العمارة أ · شقة 5',
      timeLabel: 'أمس',
      title: 'ما الموعد الأنسب ليوم نظافة الحديقة؟',
      body: 'نريد تنظيم مبادرة خفيفة بمشاركة الجيران. اختاروا الموعد الأنسب.',
      kind: CommunityPostKind.poll,
      likes: 9,
      comments: const [],
      pollOptions: const [
        PollOption(id: 'friday', label: 'الجمعة بعد العصر', votes: 8),
        PollOption(id: 'saturday', label: 'السبت صباحاً', votes: 13),
        PollOption(id: 'sunday', label: 'الأحد صباحاً', votes: 5),
      ],
    ),
    const CommunityPost(
      id: 'event-football',
      author: 'أيوب بناني',
      authorUnit: 'العمارة د · شقة 3',
      timeLabel: 'أمس',
      title: 'مباراة ودّية بين سكان الإقامة',
      body:
          'موعدنا نهاية الأسبوع لمباراة ودية. الجميع مرحب به، وسنكوّن الفرق في عين المكان.',
      kind: CommunityPostKind.event,
      likes: 21,
      comments: [],
      eventDate: 'السبت، 27 يوليو · 18:00',
      eventLocation: 'ملعب الحي قرب البوابة الجنوبية',
    ),
    const CommunityPost(
      id: 'general-books',
      author: 'مريم الزهراء',
      authorUnit: 'العمارة ب · شقة 16',
      timeLabel: 'منذ يومين',
      title: 'كتب أطفال للمشاركة',
      body:
          'لدي مجموعة قصص مناسبة للأطفال بين 6 و10 سنوات. يسعدني إعارتها للعائلات المهتمة داخل الإقامة.',
      kind: CommunityPostKind.general,
      likes: 11,
      comments: [],
    ),
  ];

  @override
  List<CommunityPost> getPosts() => List.unmodifiable(_posts);

  @override
  CommunityPost? getPost(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  @override
  CommunityPost createPost({
    required String title,
    required String body,
    CommunityPostKind kind = CommunityPostKind.general,
    List<String> pollOptions = const [],
    String? eventDate,
    String? eventLocation,
  }) {
    final post = CommunityPost(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}',
      author: 'أحمد من العمارة',
      authorUnit: 'العمارة أ · شقة 12',
      timeLabel: 'الآن',
      title: title,
      body: body,
      kind: kind,
      likes: 0,
      comments: const [],
      pollOptions: [
        for (var index = 0; index < pollOptions.length; index++)
          PollOption(id: 'option-$index', label: pollOptions[index], votes: 0),
      ],
      eventDate: eventDate,
      eventLocation: eventLocation,
    );
    _posts.insert(0, post);
    return post;
  }

  @override
  void toggleLike(String postId) {
    _update(postId, (post) {
      return post.copyWith(
        isLiked: !post.isLiked,
        likes: post.likes + (post.isLiked ? -1 : 1),
      );
    });
  }

  @override
  void toggleSaved(String postId) {
    _update(postId, (post) => post.copyWith(isSaved: !post.isSaved));
  }

  @override
  void addComment(String postId, String body) {
    _update(
      postId,
      (post) => post.copyWith(
        comments: [
          ...post.comments,
          CommunityComment(
            id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
            author: 'أحمد من العمارة',
            body: body,
            timeLabel: 'الآن',
            isAuthor: true,
          ),
        ],
      ),
    );
  }

  @override
  void vote(String postId, String optionId) {
    _update(postId, (post) {
      if (post.kind != CommunityPostKind.poll ||
          post.selectedPollOptionId != null) {
        return post;
      }
      return post.copyWith(
        selectedPollOptionId: optionId,
        pollOptions: [
          for (final option in post.pollOptions)
            option.id == optionId
                ? option.copyWith(votes: option.votes + 1)
                : option,
        ],
      );
    });
  }

  void _update(String id, CommunityPost Function(CommunityPost) update) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index >= 0) _posts[index] = update(_posts[index]);
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
  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  List<CommunityPost> build() => _repository.getPosts();

  CommunityPost? post(String id) {
    for (final post in state) {
      if (post.id == id) return post;
    }
    return null;
  }

  String createPost({
    required String title,
    required String body,
    CommunityPostKind kind = CommunityPostKind.general,
    List<String> pollOptions = const [],
    String? eventDate,
    String? eventLocation,
  }) {
    final post = _repository.createPost(
      title: title,
      body: body,
      kind: kind,
      pollOptions: pollOptions,
      eventDate: eventDate,
      eventLocation: eventLocation,
    );
    _refresh();
    return post.id;
  }

  void toggleLike(String postId) {
    _repository.toggleLike(postId);
    _refresh();
  }

  void toggleSaved(String postId) {
    _repository.toggleSaved(postId);
    _refresh();
  }

  void addComment(String postId, String body) {
    _repository.addComment(postId, body);
    _refresh();
  }

  void vote(String postId, String optionId) {
    _repository.vote(postId, optionId);
    _refresh();
  }

  void _refresh() => state = _repository.getPosts();
}
