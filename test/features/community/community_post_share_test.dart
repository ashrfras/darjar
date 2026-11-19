import 'package:darjar/features/community/presentation/community_post_action_icon.dart';
import 'dart:async';
import 'dart:io';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_share_button.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/community/presentation/community_post_share_image.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _post = CommunityPost(
  id: 'neighbor-post',
  author: 'جار',
  timeLabel: '',
  content:
      'مرحبًا بالجيران، نلتقي يوم السبت للعناية بحديقة الإقامة.\nWelcome, neighbors!',
  kind: CommunityPostKind.general,
  likes: 12,
  comments: [],
);
const _residence = ResidenceContext(
  residences: [
    UserResidence(
      id: 'r1',
      name: 'إقامة النخيل',
      address: '',
      city: '',
      role: 'resident',
      apartmentId: '',
    ),
  ],
  activeResidenceId: 'r1',
);

Future<Uint8List> _render(
  String content, {
  List<Uint8List> images = const [],
}) => CommunityPostShareImage.render(
  residenceName: 'إقامة النخيل',
  content: content,
  textDirection: TextDirection.rtl,
  locale: const Locale('ar'),
  images: images,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('IBM Plex Sans Arabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await loader.load();
  });

  test('PNG grows with complete text and every attachment', () async {
    final plain = img.decodePng(await _render(_post.content))!;
    final long = img.decodePng(
      await _render(List.filled(35, _post.content).join('\n')),
    )!;
    final red = img.Image(width: 400, height: 200)
      ..clear(img.ColorRgb8(240, 20, 20));
    final bytes = Uint8List.fromList(img.encodePng(red));
    final png = await _render(
      _post.content,
      images: [bytes, bytes, bytes, bytes],
    );
    final attached = img.decodePng(png)!;
    expect(plain.width, 1080);
    expect(long.height, greaterThan(plain.height));
    expect(attached.height, lessThan(plain.height + 600));
    expect(attached.height, greaterThan(plain.height + 400));
    // Two rows retain both columns of attachments.
    var bands = 0;
    var wasRed = false;
    for (var y = 0; y < attached.height; y++) {
      final pixel = attached.getPixel(300, y);
      final isRed = pixel.r > 220 && pixel.g < 40 && pixel.b < 40;
      if (isRed && !wasRed) bands++;
      wasRed = isRed;
    }
    expect(bands, 2);
    var rightRedPixels = 0;
    for (var y = 0; y < attached.height; y++) {
      final pixel = attached.getPixel(780, y);
      if (pixel.r > 220 && pixel.g < 40 && pixel.b < 40) rightRedPixels++;
    }
    expect(rightRedPixels, greaterThan(400));
    final threeImages = img.decodePng(
      await _render(_post.content, images: [bytes, bytes, bytes]),
    )!;
    expect(threeImages.height, attached.height);
    expect(
      img.decodePng(await _render(_post.content, images: [bytes]))!.height,
      greaterThan(
        img
            .decodePng(await _render(_post.content, images: [bytes, bytes]))!
            .height,
      ),
    );
    final preview = Platform.environment['DARJAR_SHARE_PREVIEW'];
    if (preview != null) await File(preview).writeAsBytes(png);
  });

  test(
    'residence heading adds the prefix once using the app naming rule',
    () async {
      Future<Uint8List> renderName(String name) =>
          CommunityPostShareImage.render(
            residenceName: name,
            content: _post.content,
            textDirection: TextDirection.rtl,
            locale: const Locale('ar'),
          );
      final withoutPrefix = await renderName('النخيل');
      expect(await renderName('إقامة النخيل'), orderedEquals(withoutPrefix));
      expect(
        await renderName('  إقامة النخيل  '),
        orderedEquals(withoutPrefix),
      );
    },
  );

  test(
    'rejects extreme height instead of clipping or shrinking text',
    () async {
      await expectLater(
        _render(List.filled(5000, 'سطر').join('\n')),
        throwsA(isA<PostShareImageTooLarge>()),
      );
    },
  );

  test('unreadable attachments fail rather than silently disappear', () async {
    await expectLater(
      _render(
        'نص',
        images: [
          Uint8List.fromList([1, 2, 3]),
        ],
      ),
      throwsException,
    );
  });

  test('Latin content renders with LTR layout too', () async {
    final png = await CommunityPostShareImage.render(
      residenceName: 'Palm Residence',
      content: 'Hello neighbors!',
      textDirection: TextDirection.ltr,
      locale: const Locale('en'),
    );
    expect(img.decodePng(png)!.width, 1080);
  });

  testWidgets('share is available on a neighbor card at narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          residenceDirectoryProvider.overrideWith(
            (ref) async => ResidenceMembersData.empty,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CommunityPostCard(
                post: _post,
                onOpen: () {},
                onLike: () {},
                onSave: () {},
                onVote: (_) {},
                onReport: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final share = find.byKey(const ValueKey('share-neighbor-post'));
    final save = find.byKey(const ValueKey('save-neighbor-post'));
    final like = find.ancestor(
      of: find.byIcon(Icons.thumb_up_outlined),
      matching: find.byType(CommunityPostActionIcon),
    );
    final comment = find.ancestor(
      of: find.byIcon(Icons.chat_bubble_outline_rounded),
      matching: find.byType(CommunityPostActionIcon),
    );
    expect(share, findsOneWidget);
    expect(find.text('مشاركة'), findsNothing);
    expect(tester.getCenter(share).dx, lessThan(tester.getCenter(save).dx));
    final centers = [
      share,
      save,
      like,
      comment,
    ].map((finder) => tester.getCenter(finder).dy);
    for (final y in centers) {
      expect(y, closeTo(centers.first, 0.01));
    }
    for (final icon in find.byType(CommunityPostActionIcon).evaluate()) {
      expect(tester.getSize(find.byWidget(icon.widget)), const Size(24, 24));
    }
    expect(tester.getSize(share), const Size(48, 48));
    expect(tester.getSize(save), const Size(48, 48));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          residenceDirectoryProvider.overrideWith(
            (ref) async => ResidenceMembersData.empty,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: communityWelcomePost,
                onOpen: () {},
                onLike: () {},
                onSave: () {},
                onVote: (_) {},
                onReport: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPostShareButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final format in ['image', 'image-error', 'text', 'cancel']) {
    testWidgets('share sheet supports $format and blocks repeated taps', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      final pending = Completer<String>();
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('darjar-share-test-'),
      ))!;
      addTearDown(
        () => tester.runAsync(() => temporary.delete(recursive: true)),
      );
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        pathChannel,
        (_) async => temporary.path,
      );
      messenger.setMockMethodCallHandler(shareChannel, (call) {
        calls.add(call);
        return pending.future;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(pathChannel, null);
        messenger.setMockMethodCallHandler(shareChannel, null);
      });
      final downloadGate = Completer<void>();
      final repository = _ShareImageRepository(
        downloadGate: format.startsWith('image') ? downloadGate : null,
        failDownload: format == 'image-error',
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            residenceContextProvider.overrideWith((ref) async {
              if (!format.startsWith('image')) {
                throw StateError('Text sharing must not load residence data');
              }
              return _residence;
            }),
            communityRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CommunityPostShareButton(
                post: CommunityPost(
                  id: _post.id,
                  author: _post.author,
                  timeLabel: '',
                  content: _post.content,
                  kind: _post.kind,
                  likes: 0,
                  comments: const [],
                  imagePaths: const ['residences/r1/community/p1/image-0'],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('share-neighbor-post'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('مشاركة المنشور'), findsOneWidget);
      expect(
        find.text('يمكنك مشاركة المنشور عبر واتساب أو أي تطبيق آخر'),
        findsOneWidget,
      );
      expect(find.text('مشاركة كصورة'), findsOneWidget);
      expect(find.text('مشاركة كنص'), findsOneWidget);
      expect(calls, isEmpty);
      expect(repository.requestedPaths, isEmpty);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('share-neighbor-post')),
            )
            .onPressed,
        isNull,
      );
      if (format == 'cancel') {
        await tester.runAsync(() async {
          await tester.tapAt(const Offset(10, 10));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('post-share-sheet')), findsNothing);
        expect(calls, isEmpty);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('share-neighbor-post')),
              )
              .onPressed,
          isNotNull,
        );
        return;
      }
      await tester.runAsync(
        () => tester.tap(
          find.byKey(
            ValueKey(
              'post-share-${format.startsWith('image') ? 'image' : format}',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      if (format.startsWith('image')) {
        expect(
          find.byKey(const Key('post-share-image-loading')),
          findsOneWidget,
        );
        expect(find.text('جارٍ تجهيز صورة المنشور…'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(calls, isEmpty);
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byKey(const Key('post-share-image-loading')),
          findsOneWidget,
        );
        await tester.runAsync(() async {
          downloadGate.complete();
          await Future<void>.delayed(Duration.zero);
        });
        if (format == 'image-error') {
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('post-share-image-loading')),
            findsNothing,
          );
          expect(
            find.text(
              'تعذّر تجهيز الصورة أو مشاركتها. تأكد من الاتصال وحاول مجددًا.',
            ),
            findsOneWidget,
          );
          expect(calls, isEmpty);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('share-neighbor-post')),
                )
                .onPressed,
            isNotNull,
          );
          return;
        }
      }
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && calls.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('share-neighbor-post')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('post-share-image-loading')), findsNothing);
      expect(calls, hasLength(1));
      final arguments = calls.single.arguments as Map;
      expect(arguments['originWidth'], greaterThan(0));
      if (format == 'image') {
        expect(arguments['mimeTypes'], ['image/png']);
        expect(arguments['paths'], hasLength(1));
        expect(
          File(
            (arguments['paths'] as List).single as String,
          ).uri.pathSegments.last,
          matches(RegExp(r'^دارجار-منشور-[1-9][0-9]{2}\.png$')),
        );
        expect(arguments.containsKey('text'), isFalse);
        final png = await tester.runAsync(
          () =>
              File((arguments['paths'] as List).single as String).readAsBytes(),
        );
        expect(img.decodePng(png!)!.width, 1080);
        expect(img.decodePng(png)!.height, greaterThan(700));
        expect(repository.requestedPaths, [
          'residences/r1/community/p1/image-0',
        ]);
      } else {
        expect(arguments['text'], _post.content);
        expect(arguments.containsKey('paths'), isFalse);
        expect(repository.requestedPaths, isEmpty);
      }
      pending.complete('dev.fluttercommunity.plus/share/dismissed');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('share-neighbor-post')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _ShareImageRepository extends MockCommunityRepository {
  _ShareImageRepository({this.downloadGate, this.failDownload = false});

  final Completer<void>? downloadGate;
  final bool failDownload;
  final requestedPaths = <String>[];

  @override
  Future<Uint8List> downloadImage(String path) async {
    requestedPaths.add(path);
    await downloadGate?.future;
    if (failDownload) throw const CommunityFailure('test-download-failed');
    final data = await rootBundle.load(
      'assets/images/community/garden-night.jpg',
    );
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
