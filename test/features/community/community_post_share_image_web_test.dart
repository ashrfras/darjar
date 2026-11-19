import 'package:darjar/features/community/presentation/community_post_share_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Run on both the native engine and Chrome: encoded ImageDescriptor dimensions
// work on native Flutter but throw UnsupportedError on Flutter Web.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Browser unit tests do not install Flutter's native asset-channel handler.
  // Supply a small logo fixture so this tests codecs without an HTTP asset load.
  setUp(() {
    final logo = img.Image(width: 8, height: 8)
      ..clear(img.ColorRgb8(15, 118, 110));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'flutter/assets',
          (_) async =>
              ByteData.sublistView(Uint8List.fromList(img.encodePng(logo))),
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  for (final format in ['jpeg', 'png']) {
    test(
      'exports a post with $format portrait and landscape attachments',
      () async {
        final portrait = img.Image(width: 600, height: 1600)
          ..clear(img.ColorRgb8(240, 20, 20));
        final landscape = img.Image(width: 1600, height: 600)
          ..clear(img.ColorRgb8(20, 20, 240));
        Uint8List encode(img.Image image) => Uint8List.fromList(
          format == 'jpeg' ? img.encodeJpg(image) : img.encodePng(image),
        );
        final png = await CommunityPostShareImage.render(
          residenceName: 'إقامة النخيل',
          content: 'مرحبًا بالجيران',
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          images: [encode(portrait), encode(landscape)],
        );
        final result = img.decodePng(png)!;
        expect(result.width, 1080);
        expect(result.height, greaterThan(900));
        expect(result.height, lessThan(1400));
        // Both attachments retain their colors and proportions, with the tall
        // photo contained inside its bounded frame rather than stretched.
        var redRows = 0;
        var blueRows = 0;
        for (var y = 0; y < result.height; y++) {
          final redPixel = result.getPixel(780, y);
          final bluePixel = result.getPixel(300, y);
          if (redPixel.r > 220 && redPixel.b < 40) redRows++;
          if (bluePixel.b > 220 && bluePixel.r < 40) blueRows++;
        }
        expect(redRows, closeTo(600, 3));
        expect(blueRows, closeTo(172, 3));
      },
    );
  }
}
