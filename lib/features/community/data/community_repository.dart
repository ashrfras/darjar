import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/core/images/app_image_processing.dart';
import 'package:darjar/core/performance/data_load_timer.dart';
import 'package:darjar/core/providers/provider_cache.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const communityImageMaxSourceSizeBytes = appImageMaxSourceSizeBytes;
const communityImageMaxStoredSizeBytes = appImageMaxStoredSizeBytes;
const communityImageMaxDimension = appImageMaxDimension;
const communityImageTargetSizeBytes = appImageTargetSizeBytes;
const communityPostsPageSize = 10;
const communityWelcomePostId = 'darjar-welcome';

const communityWelcomePost = CommunityPost(
  id: communityWelcomePostId,
  author: 'دارجار',
  authorRole: 'platformAdmin',
  timeLabel: 'مرحباً بك',
  content:
      'أهلاً بك في إقامتك الرقمية\n\n'
      'الموجز: تابع نشاط الإقامة وتواصل مع جيرانك.\n'
      'الخدمات: اعثر على مقدمي الخدمات الموصى بهم من السكان.\n'
      'الإقامة: تابع اشتراكاتك ووثائقك واطّلع على ميزانية الإقامة.',
  kind: CommunityPostKind.announcement,
  likes: 0,
  comments: [],
  isOfficial: true,
  isSystem: true,
  imagePaths: ['assets/images/branding/darjar-logo.png'],
);

Uint8List compressCommunityImageBytes(Uint8List sourceBytes) {
  try {
    return compressAppImageBytes(sourceBytes);
  } on FormatException {
    throw const CommunityFailure('invalid-image-data');
  }
}

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
    this.authorId = '',
    this.isAuthor = false,
  });

  final String id;
  final String author;
  final String authorId;
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
    required this.content,
    required this.kind,
    required this.likes,
    required this.comments,
    this.authorId = '',
    this.authorUnit,
    this.authorRole = 'resident',
    this.isOfficial = false,
    this.isCurrentUser = false,
    this.isLiked = false,
    this.isSaved = false,
    this.imagePaths = const [],
    this.pollOptions = const [],
    this.selectedPollOptionId,
    this.eventDate,
    this.eventLocation,
    this.commentCountOverride,
    this.isSystem = false,
    this.createdAt,
  });

  final String id;
  final String author;
  final String authorId;
  final String? authorUnit;
  final String authorRole;
  final String timeLabel;
  final String content;
  final CommunityPostKind kind;
  final int likes;
  final List<CommunityComment> comments;
  final bool isOfficial;
  final bool isCurrentUser;
  final bool isLiked;
  final bool isSaved;
  final List<String> imagePaths;
  final List<PollOption> pollOptions;
  final String? selectedPollOptionId;
  final String? eventDate;
  final String? eventLocation;
  final int? commentCountOverride;
  final bool isSystem;
  final DateTime? createdAt;

  int get commentCount => commentCountOverride ?? comments.length;

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
      authorId: authorId,
      authorUnit: authorUnit,
      authorRole: authorRole,
      timeLabel: timeLabel,
      content: content,
      kind: kind,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isOfficial: isOfficial,
      isCurrentUser: isCurrentUser,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      imagePaths: imagePaths,
      pollOptions: pollOptions ?? this.pollOptions,
      selectedPollOptionId: selectedPollOptionId ?? this.selectedPollOptionId,
      eventDate: eventDate,
      eventLocation: eventLocation,
      commentCountOverride: commentCountOverride,
      isSystem: isSystem,
      createdAt: createdAt,
    );
  }
}

class CommunityPostImageUpload {
  const CommunityPostImageUpload({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

class CommunityFailure implements Exception {
  const CommunityFailure(this.code, [this.details]);

  final String code;
  final String? details;
}

abstract interface class CommunityRepository {
  Stream<List<CommunityPost>> watchPosts({
    required String residenceId,
    required String userId,
    required int limit,
  });

  Stream<CommunityPost?> watchPost({
    required String residenceId,
    required String userId,
    required String postId,
  });

  Future<String> createPost({
    required String residenceId,
    required String userId,
    required String content,
    CommunityPostKind kind,
    List<String> pollOptions,
    List<CommunityPostImageUpload> images,
    String? eventDate,
    String? eventLocation,
  });

  Future<void> toggleLike({
    required String residenceId,
    required String userId,
    required String postId,
  });

  Future<void> toggleSaved({
    required String residenceId,
    required String userId,
    required String postId,
  });

  Future<void> addComment({
    required String residenceId,
    required String userId,
    required String postId,
    required String body,
  });

  Future<void> vote({
    required String residenceId,
    required String userId,
    required String postId,
    required String optionId,
  });

  Future<void> archivePost({
    required String residenceId,
    required String userId,
    required String postId,
  });

  Future<Uint8List> downloadImage(String storagePath);
}

class MockCommunityRepository implements CommunityRepository {
  final _changes = StreamController<List<CommunityPost>>.broadcast();
  Completer<void>? createBarrier;

  final List<CommunityPost> _posts = [
    CommunityPost(
      id: 'announcement-elevator',
      author: 'السانديك',
      authorUnit: 'إدارة الإقامة',
      authorRole: 'president',
      timeLabel: 'منذ 30 دقيقة',
      content:
          'صيانة المصاعد يوم الخميس القادم\n\nسيتم إجراء صيانة دورية للمصاعد يوم الخميس 25 يوليو من الساعة 9 صباحاً إلى 1 ظهراً. يرجى استعمال الدرج خلال هذه الفترة.',
      kind: CommunityPostKind.announcement,
      likes: 12,
      isOfficial: true,
      imagePaths: const [
        'assets/images/community/elevator-maintenance.jpg',
        'assets/images/community/elevator-panel.jpg',
        'assets/images/community/elevator-corridor.jpg',
        'assets/images/community/elevator-tools.jpg',
      ],
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
      content:
          'هل أحد لديه رقم سبّاك موثوق؟\n\nعندي تسرّب في المطبخ وأبحث عن سبّاك موثوق وبسعر مناسب. يفضّل أن يكون متاحاً اليوم.',
      kind: CommunityPostKind.question,
      likes: 4,
      isCurrentUser: true,
      imagePaths: const ['assets/images/community/plumber.jpg'],
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
      content:
          'ضجيج في الحديقة ليلاً\n\nالرجاء من الجميع مراعاة الهدوء بعد الساعة 11 ليلاً في الحديقة، خصوصاً خلال أيام الأسبوع.',
      kind: CommunityPostKind.complaint,
      likes: 5,
      imagePaths: const ['assets/images/community/garden-night.jpg'],
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
      content:
          'زراعة المزيد من الأشجار\n\nأقترح على السانديك زراعة المزيد من الأشجار في المنطقة الشرقية للحديقة وتخصيص يوم تطوعي للسكان.',
      kind: CommunityPostKind.suggestion,
      likes: 15,
      isSaved: true,
      imagePaths: ['assets/images/community/tree-saplings.jpg'],
      comments: [],
    ),
    const CommunityPost(
      id: 'alert-water',
      author: 'السانديك',
      authorUnit: 'إدارة الإقامة',
      authorRole: 'president',
      timeLabel: 'منذ 4 ساعات',
      content:
          'انقطاع الماء غداً صباحاً\n\nحسب إشعار الشركة، سيكون هناك انقطاع للماء غداً من 6 صباحاً إلى 10 صباحاً بسبب أشغال في الحي.',
      kind: CommunityPostKind.alert,
      likes: 18,
      isOfficial: true,
      comments: [],
    ),
    CommunityPost(
      id: 'poll-garden',
      author: 'سلمى الإدريسي',
      authorUnit: 'العمارة أ · شقة 5',
      timeLabel: 'أمس',
      content:
          'ما الموعد الأنسب ليوم نظافة الحديقة؟\n\nنريد تنظيم مبادرة خفيفة بمشاركة الجيران. اختاروا الموعد الأنسب.',
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
      content:
          'مباراة ودّية بين سكان الإقامة\n\nموعدنا نهاية الأسبوع لمباراة ودية. الجميع مرحب به، وسنكوّن الفرق في عين المكان.',
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
      content:
          'كتب أطفال للمشاركة\n\nلدي مجموعة قصص مناسبة للأطفال بين 6 و10 سنوات. يسعدني إعارتها للعائلات المهتمة داخل الإقامة.',
      kind: CommunityPostKind.general,
      likes: 11,
      comments: [],
    ),
  ];

  List<CommunityPost> getPosts() => List.unmodifiable(_posts);

  CommunityPost? getPost(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  @override
  Stream<List<CommunityPost>> watchPosts({
    required String residenceId,
    required String userId,
    int limit = communityPostsPageSize,
  }) async* {
    yield getPosts().take(limit).toList(growable: false);
    yield* _changes.stream.map(
      (posts) => posts.take(limit).toList(growable: false),
    );
  }

  @override
  Stream<CommunityPost?> watchPost({
    required String residenceId,
    required String userId,
    required String postId,
  }) async* {
    yield getPost(postId);
    await for (final posts in _changes.stream) {
      yield posts.where((post) => post.id == postId).firstOrNull;
    }
  }

  @override
  Future<String> createPost({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String content,
    CommunityPostKind kind = CommunityPostKind.general,
    List<String> pollOptions = const [],
    List<CommunityPostImageUpload> images = const [],
    List<String> imagePaths = const [],
    String? eventDate,
    String? eventLocation,
  }) async {
    await createBarrier?.future;
    final post = CommunityPost(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}',
      author: 'أحمد من العمارة',
      authorUnit: 'العمارة أ · شقة 12',
      timeLabel: 'الآن',
      content: content,
      kind: kind,
      likes: 0,
      comments: const [],
      isCurrentUser: true,
      imagePaths: imagePaths.take(4).toList(growable: false),
      pollOptions: [
        for (var index = 0; index < pollOptions.length; index++)
          PollOption(id: 'option-$index', label: pollOptions[index], votes: 0),
      ],
      eventDate: eventDate,
      eventLocation: eventLocation,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    _notify();
    return post.id;
  }

  @override
  Future<void> toggleLike({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String postId,
  }) async {
    _update(postId, (post) {
      return post.copyWith(
        isLiked: !post.isLiked,
        likes: post.likes + (post.isLiked ? -1 : 1),
      );
    });
  }

  @override
  Future<void> toggleSaved({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String postId,
  }) async {
    _update(postId, (post) => post.copyWith(isSaved: !post.isSaved));
  }

  @override
  Future<void> addComment({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String postId,
    required String body,
  }) async {
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
  Future<void> vote({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String postId,
    required String optionId,
  }) async {
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

  @override
  Future<void> archivePost({
    String residenceId = 'mock-residence',
    String userId = 'mock-user',
    required String postId,
  }) async {
    _posts.removeWhere((post) => post.id == postId);
    _notify();
  }

  void _update(String id, CommunityPost Function(CommunityPost) update) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index >= 0) {
      _posts[index] = update(_posts[index]);
      _notify();
    }
  }

  void _notify() => _changes.add(getPosts());

  @override
  Future<Uint8List> downloadImage(String storagePath) {
    throw const CommunityFailure('mock-image-unavailable');
  }

  void dispose() => _changes.close();
}

class FirebaseCommunityRepository implements CommunityRepository {
  FirebaseCommunityRepository(this._firestore, this._storage);

  static const maxImages = 4;
  static const maxImageSizeBytes = communityImageMaxStoredSizeBytes;
  static const acceptedImageTypes = {'image/jpeg'};

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<CommunityPost>> watchPosts({
    required String residenceId,
    required String userId,
    required int limit,
  }) {
    return _posts(residenceId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          return Future.wait([
            for (final document in snapshot.docs)
              if (document.data()['archivedAt'] == null)
                _postFromDocument(document, userId, includeComments: false),
          ]);
        })
        .handleError((Object error) => throw _failure(error));
  }

  @override
  Stream<CommunityPost?> watchPost({
    required String residenceId,
    required String userId,
    required String postId,
  }) {
    return _posts(residenceId)
        .doc(postId)
        .snapshots()
        .asyncMap((document) async {
          if (!document.exists || document.data()?['archivedAt'] != null) {
            return null;
          }
          return _postFromDocument(document, userId, includeComments: true);
        })
        .handleError((Object error) => throw _failure(error));
  }

  @override
  Future<String> createPost({
    required String residenceId,
    required String userId,
    required String content,
    CommunityPostKind kind = CommunityPostKind.general,
    List<String> pollOptions = const [],
    List<CommunityPostImageUpload> images = const [],
    String? eventDate,
    String? eventLocation,
  }) async {
    final normalizedContent = content.trim();
    final normalizedPollOptions = pollOptions
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList(growable: false);
    if (normalizedContent.isEmpty || normalizedContent.length > 5000) {
      throw const CommunityFailure('invalid-post');
    }
    if (kind == CommunityPostKind.announcement) {
      throw const CommunityFailure('official-post-not-available');
    }
    if (kind == CommunityPostKind.poll &&
        (normalizedPollOptions.length < 2 ||
            normalizedPollOptions.length > 5)) {
      throw const CommunityFailure('invalid-poll');
    }
    if (kind == CommunityPostKind.event &&
        ((eventDate?.trim().isEmpty ?? true) ||
            (eventLocation?.trim().isEmpty ?? true))) {
      throw const CommunityFailure('invalid-event');
    }
    if (images.length > maxImages ||
        images.any(
          (image) =>
              !acceptedImageTypes.contains(image.contentType) ||
              image.bytes.isEmpty ||
              image.bytes.lengthInBytes > maxImageSizeBytes,
        )) {
      throw const CommunityFailure('invalid-images');
    }

    final post = _posts(residenceId).doc();
    final uploadedPaths = <String>[];
    try {
      final member = await _member(residenceId, userId).get();
      if (!member.exists || member.data()?['status'] != 'active') {
        throw const CommunityFailure('not-a-member');
      }
      final memberData = member.data()!;
      final authorName =
          '${memberData['firstName'] ?? ''} ${memberData['lastName'] ?? ''}'
              .trim();
      final apartmentId = memberData['apartmentId'] as String? ?? '';
      final authorRole = memberData['role'] as String? ?? 'resident';
      final isOfficial = authorRole == 'president' || authorRole == 'owner';

      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final storagePath =
            'residences/$residenceId/community/${post.id}/image-$index';
        await _storage
            .ref(storagePath)
            .putData(
              image.bytes,
              SettableMetadata(
                contentType: image.contentType,
                cacheControl: 'private,max-age=3600',
                customMetadata: {
                  'residenceId': residenceId,
                  'postId': post.id,
                  'uploadedBy': userId,
                },
              ),
            );
        uploadedPaths.add(storagePath);
      }

      await post.set({
        'authorId': userId,
        'authorName': authorName.isEmpty ? userId : authorName,
        'authorUnit': apartmentId,
        'authorRole': authorRole,
        'content': normalizedContent,
        'kind': kind.name,
        'isOfficial': isOfficial,
        'imagePaths': uploadedPaths,
        'pollOptions': [
          for (var index = 0; index < normalizedPollOptions.length; index++)
            {'id': 'option-$index', 'label': normalizedPollOptions[index]},
        ],
        'pollOptionIds': [
          for (var index = 0; index < normalizedPollOptions.length; index++)
            'option-$index',
        ],
        'pollVotes': <String, String>{},
        'likedBy': <String>[],
        'savedBy': <String>[],
        'commentCount': 0,
        'eventDate': eventDate?.trim(),
        'eventLocation': eventLocation?.trim(),
        'archivedAt': null,
        'archivedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return post.id;
    } catch (error) {
      await Future.wait([
        for (final path in uploadedPaths)
          _storage.ref(path).delete().catchError((_) {}),
      ]);
      throw _failure(error);
    }
  }

  @override
  Future<void> toggleLike({
    required String residenceId,
    required String userId,
    required String postId,
  }) async {
    await _toggleMembership(
      reference: _posts(residenceId).doc(postId),
      field: 'likedBy',
      userId: userId,
    );
  }

  @override
  Future<void> toggleSaved({
    required String residenceId,
    required String userId,
    required String postId,
  }) async {
    await _toggleMembership(
      reference: _posts(residenceId).doc(postId),
      field: 'savedBy',
      userId: userId,
    );
  }

  Future<void> _toggleMembership({
    required DocumentReference<Map<String, dynamic>> reference,
    required String field,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) throw const CommunityFailure('post-not-found');
        final values = List<String>.from(
          snapshot.data()?[field] as List? ?? const [],
        );
        transaction.update(reference, {
          field: values.contains(userId)
              ? FieldValue.arrayRemove([userId])
              : FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> addComment({
    required String residenceId,
    required String userId,
    required String postId,
    required String body,
  }) async {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty || normalizedBody.length > 1000) {
      throw const CommunityFailure('invalid-comment');
    }
    try {
      final member = await _member(residenceId, userId).get();
      if (!member.exists || member.data()?['status'] != 'active') {
        throw const CommunityFailure('not-a-member');
      }
      final data = member.data()!;
      final authorName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
          .trim();
      final post = _posts(residenceId).doc(postId);
      final comment = post.collection('comments').doc();
      final batch = _firestore.batch()
        ..set(comment, {
          'authorId': userId,
          'authorName': authorName.isEmpty ? userId : authorName,
          'body': normalizedBody,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(post, {
          'commentCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      await batch.commit();
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> vote({
    required String residenceId,
    required String userId,
    required String postId,
    required String optionId,
  }) async {
    final post = _posts(residenceId).doc(postId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(post);
        if (!snapshot.exists) {
          throw const CommunityFailure('invalid-poll-option');
        }
        final data = snapshot.data()!;
        final optionIds = List<String>.from(data['pollOptionIds'] as List);
        if (!optionIds.contains(optionId)) {
          throw const CommunityFailure('invalid-poll-option');
        }
        final votes = Map<String, String>.from(data['pollVotes'] as Map);
        votes[userId] = optionId;
        transaction.update(post, {
          'pollVotes': votes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> archivePost({
    required String residenceId,
    required String userId,
    required String postId,
  }) async {
    try {
      await _posts(residenceId).doc(postId).update({
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<Uint8List> downloadImage(String storagePath) async {
    try {
      final bytes = await _storage.ref(storagePath).getData(maxImageSizeBytes);
      if (bytes == null) throw const CommunityFailure('empty-image');
      return bytes;
    } catch (error) {
      throw _failure(error);
    }
  }

  Future<CommunityPost> _postFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
    String userId, {
    required bool includeComments,
  }) async {
    final data = document.data()!;
    final commentsSnapshot = includeComments
        ? await document.reference
              .collection('comments')
              .orderBy('createdAt')
              .limit(100)
              .get()
        : null;
    final likedBy = List<String>.from(data['likedBy'] as List? ?? const []);
    final savedBy = List<String>.from(data['savedBy'] as List? ?? const []);
    final authorRole = data['authorRole'] as String;
    final pollVotes = Map<String, String>.from(data['pollVotes'] as Map);
    final voteCounts = <String, int>{};
    for (final optionId in pollVotes.values) {
      voteCounts[optionId] = (voteCounts[optionId] ?? 0) + 1;
    }
    final content = _postContentFromData(data);
    return CommunityPost(
      id: document.id,
      author: data['authorName'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorUnit: _nullableString(data['authorUnit']),
      authorRole: authorRole,
      timeLabel: _relativeTime(data['createdAt']),
      createdAt: _dateTime(data['createdAt']),
      content: content,
      kind: _kindFrom(data['kind']),
      likes: likedBy.length,
      comments: [
        for (final comment in commentsSnapshot?.docs ?? const [])
          CommunityComment(
            id: comment.id,
            author: comment.data()['authorName'] as String? ?? '',
            authorId: comment.data()['authorId'] as String? ?? '',
            body: comment.data()['body'] as String? ?? '',
            timeLabel: _relativeTime(comment.data()['createdAt']),
            isAuthor: comment.data()['authorId'] == userId,
          ),
      ],
      isOfficial:
          (data['isOfficial'] as bool? ?? false) ||
          authorRole == 'president' ||
          authorRole == 'owner',
      isCurrentUser: data['authorId'] == userId,
      isLiked: likedBy.contains(userId),
      isSaved: savedBy.contains(userId),
      imagePaths: List<String>.from(data['imagePaths'] as List? ?? const []),
      pollOptions: [
        for (final raw in data['pollOptions'] as List? ?? const [])
          PollOption(
            id: (raw as Map)['id'] as String? ?? '',
            label: raw['label'] as String? ?? '',
            votes: voteCounts[raw['id']] ?? 0,
          ),
      ],
      selectedPollOptionId: pollVotes[userId],
      eventDate: _nullableString(data['eventDate']),
      eventLocation: _nullableString(data['eventLocation']),
      commentCountOverride: data['commentCount'] as int? ?? 0,
    );
  }

  CollectionReference<Map<String, dynamic>> _posts(String residenceId) =>
      _firestore
          .collection('residences')
          .doc(residenceId)
          .collection('communityPosts');

  DocumentReference<Map<String, dynamic>> _member(
    String residenceId,
    String userId,
  ) => _firestore
      .collection('residences')
      .doc(residenceId)
      .collection('members')
      .doc(userId);

  CommunityPostKind _kindFrom(Object? value) =>
      CommunityPostKind.values.firstWhere(
        (kind) => kind.name == value,
        orElse: () => CommunityPostKind.general,
      );

  String _postContentFromData(Map<String, dynamic> data) {
    final content = (data['content'] as String? ?? '').trim();
    if (content.isNotEmpty) return content;

    // Posts created before the single-content model used a required title and
    // an optional body. Keep them readable while new posts store one field.
    return [
      data['title'] as String? ?? '',
      data['body'] as String? ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join('\n\n');
  }

  String? _nullableString(Object? value) {
    final text = value as String?;
    return text == null || text.isEmpty ? null : text;
  }

  String _relativeTime(Object? value) {
    final date = _dateTime(value) ?? DateTime.now();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays == 1) return 'أمس';
    return 'منذ ${difference.inDays} أيام';
  }

  DateTime? _dateTime(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  CommunityFailure _failure(Object error) => switch (error) {
    CommunityFailure failure => failure,
    FirebaseException(:final code, :final message) => CommunityFailure(
      code,
      message,
    ),
    _ => CommunityFailure('unknown', error.toString()),
  };
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => FirebaseCommunityRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

class CommunityPostsLimit extends Notifier<int> {
  @override
  int build() => communityPostsPageSize;

  void loadMore() => state += communityPostsPageSize;
}

final communityPostsLimitProvider =
    NotifierProvider.autoDispose<CommunityPostsLimit, int>(
      CommunityPostsLimit.new,
    );

final communityPostsProvider = StreamProvider.autoDispose<List<CommunityPost>>((
  ref,
) async* {
  final timer = DataLoadTimer('community posts');
  cacheProviderFor(ref);
  try {
    final limit = ref.watch(communityPostsLimitProvider);
    final context = await ref.watch(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (residence == null || user == null) {
      timer.finish();
      yield const [];
      return;
    }
    await for (final posts
        in ref
            .watch(communityRepositoryProvider)
            .watchPosts(
              residenceId: residence.id,
              userId: user.uid,
              limit: limit,
            )) {
      timer.finish();
      yield [...posts, if (posts.length < limit) communityWelcomePost];
    }
  } catch (error) {
    timer.finish(error: error);
    rethrow;
  }
});

final communityPostProvider = StreamProvider.autoDispose
    .family<CommunityPost?, String>((ref, postId) async* {
      cacheProviderFor(ref);
      if (postId == communityWelcomePostId) {
        yield communityWelcomePost;
        return;
      }
      final context = await ref.watch(residenceContextProvider.future);
      final residence = context.activeResidence;
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (residence == null || user == null) {
        yield null;
        return;
      }
      yield* ref
          .watch(communityRepositoryProvider)
          .watchPost(
            residenceId: residence.id,
            userId: user.uid,
            postId: postId,
          );
    });

final communityActionsProvider = Provider<CommunityActions>(
  CommunityActions.new,
);

class CommunityActions {
  CommunityActions(this._ref);

  final Ref _ref;

  Future<(String, String)> _scope() async {
    final context = await _ref.read(residenceContextProvider.future);
    final residence = context.activeResidence;
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (residence == null || user == null) {
      throw const CommunityFailure('missing-residence');
    }
    return (residence.id, user.uid);
  }

  Future<String> createPost({
    required String content,
    CommunityPostKind kind = CommunityPostKind.general,
    List<String> pollOptions = const [],
    List<CommunityPostImageUpload> images = const [],
    String? eventDate,
    String? eventLocation,
  }) async {
    final (residenceId, userId) = await _scope();
    return _ref
        .read(communityRepositoryProvider)
        .createPost(
          residenceId: residenceId,
          userId: userId,
          content: content,
          kind: kind,
          pollOptions: pollOptions,
          images: images,
          eventDate: eventDate,
          eventLocation: eventLocation,
        );
  }

  Future<void> toggleLike(String postId) async {
    final (residenceId, userId) = await _scope();
    await _ref
        .read(communityRepositoryProvider)
        .toggleLike(residenceId: residenceId, userId: userId, postId: postId);
  }

  Future<void> toggleSaved(String postId) async {
    final (residenceId, userId) = await _scope();
    await _ref
        .read(communityRepositoryProvider)
        .toggleSaved(residenceId: residenceId, userId: userId, postId: postId);
  }

  Future<void> addComment(String postId, String body) async {
    final (residenceId, userId) = await _scope();
    await _ref
        .read(communityRepositoryProvider)
        .addComment(
          residenceId: residenceId,
          userId: userId,
          postId: postId,
          body: body,
        );
  }

  Future<void> vote(String postId, String optionId) async {
    final (residenceId, userId) = await _scope();
    await _ref
        .read(communityRepositoryProvider)
        .vote(
          residenceId: residenceId,
          userId: userId,
          postId: postId,
          optionId: optionId,
        );
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(communityPostProvider(postId));
  }

  Future<void> archivePost(String postId) async {
    final (residenceId, userId) = await _scope();
    await _ref
        .read(communityRepositoryProvider)
        .archivePost(residenceId: residenceId, userId: userId, postId: postId);
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(communityPostProvider(postId));
  }
}

final communityPostImageProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, path) {
      return ref.watch(communityRepositoryProvider).downloadImage(path);
    });
