import 'dart:io';
import 'dart:ui' as ui;

import 'package:darjar/features/community/presentation/community_post_action_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'all action icons use one size and their painted bottoms share one line',
    (tester) async {
      for (final icon in [
        Icons.thumb_up_outlined,
        Icons.thumb_up_rounded,
        Icons.chat_bubble_outline_rounded,
        Icons.bookmark_border_rounded,
        Icons.bookmark_rounded,
        Icons.ios_share_rounded,
      ]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox.square(
                  dimension: 24,
                  child: Center(
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: CommunityPostActionIcon(icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final png = await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 4);
          try {
            return (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
          } finally {
            image.dispose();
          }
        });
        final bitmap = img.decodePng(png!)!;
        var left = bitmap.width, top = bitmap.height, right = -1, bottom = -1;
        for (var y = 0; y < bitmap.height; y++) {
          for (var x = 0; x < bitmap.width; x++) {
            if (bitmap.getPixel(x, y).a > 128) {
              if (x < left) left = x;
              if (x > right) right = x;
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
        }
        final bounds = Rect.fromLTRB(
          left / 4,
          top / 4,
          (right + 1) / 4,
          (bottom + 1) / 4,
        );
        expect(tester.widget<Icon>(find.byIcon(icon)).size, 20);
        expect(
          bounds.bottom,
          closeTo(20, 0.25),
          reason: 'Glyph ${icon.codePoint}',
        );
        final preview = Platform.environment['DARJAR_ICON_PREVIEW'];
        if (preview != null) {
          await tester.runAsync(
            () => File('$preview-${icon.codePoint}.png').writeAsBytes(png),
          );
        }
      }
    },
  );
}
