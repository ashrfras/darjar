import 'dart:ui' as ui;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostShareImageTooLarge implements Exception {
  const PostShareImageTooLarge();
}

/// Draws a separate editorial card, never a screenshot of the feed widget.
/// Dimensions are physical pixels, independent of device size and text scaling.
abstract final class CommunityPostShareImage {
  static const width = 1080;
  static const maxHeight = 12000;
  static const _padding = 72.0;
  static const _innerWidth = width - _padding * 2;
  static const _ink = Color(0xFF17151D);
  static const _muted = Color(0xFF6D6976);

  static Future<Uint8List> render({
    required String residenceName,
    required String content,
    required TextDirection textDirection,
    required Locale locale,
    List<Uint8List> images = const [],
  }) async {
    final painters = <TextPainter>[];
    final decoded = <ui.Image>[];
    ui.Picture? picture;
    ui.Image? output;
    TextPainter text(
      String value,
      double size,
      Color color,
      FontWeight weight,
    ) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: size,
            height: 1.6,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: textDirection,
        textAlign: TextAlign.start,
        locale: locale,
      )..layout(minWidth: _innerWidth, maxWidth: _innerWidth);
      painters.add(painter);
      return painter;
    }

    try {
      final heading = text(
        lookupAppLocalizations(
          locale,
        ).residenceDisplayName(normalizeResidenceName(residenceName)),
        30,
        AppColors.primary,
        FontWeight.w700,
      );
      final body = text(content, 36, _ink, FontWeight.w500);
      final brand = text(
        'دارجار · Darjar',
        22,
        AppColors.primary,
        FontWeight.w700,
      );
      final website = text('darjar.app', 20, _muted, FontWeight.w400);
      const headingTop = 64.0;
      final bodyTop = headingTop + heading.height + 36;
      var height =
          bodyTop + body.height + 44 + brand.height + website.height + 48;
      // Check before allocating any image buffers for unusually long posts.
      if (height > maxHeight) throw const PostShareImageTooLarge();

      for (final bytes in images) {
        decoded.add(await _decodeImage(bytes));
      }
      final imageRects = <Rect>[];
      const gap = 20.0;
      final columns = images.length == 1 ? 1 : 2;
      final cellWidth = (_innerWidth - gap * (columns - 1)) / columns;
      var imageBottom = bodyTop + body.height;
      for (var row = 0; row < images.length; row += columns) {
        var rowHeight = 0.0;
        final count = (images.length - row).clamp(1, columns);
        for (var column = 0; column < count; column++) {
          final naturalHeight =
              cellWidth *
              decoded[row + column].height /
              decoded[row + column].width;
          final cellHeight = naturalHeight.clamp(
            160.0,
            columns == 1 ? 900.0 : 600.0,
          );
          if (cellHeight > rowHeight) rowHeight = cellHeight;
        }
        imageBottom += gap;
        for (var column = 0; column < count; column++) {
          final visualColumn = textDirection == TextDirection.rtl
              ? columns - 1 - column
              : column;
          imageRects.add(
            Rect.fromLTWH(
              _padding + visualColumn * (cellWidth + gap),
              imageBottom,
              cellWidth,
              rowHeight,
            ),
          );
        }
        imageBottom += rowHeight;
        height += gap + rowHeight;
        if (height > maxHeight) throw const PostShareImageTooLarge();
      }
      final logoData = await rootBundle.load(
        'assets/images/branding/darjar-logo.png',
      );
      final logoCodec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(
          logoData.offsetInBytes,
          logoData.lengthInBytes,
        ),
        targetWidth: 80,
      );
      late final ui.Image logo;
      try {
        logo = (await logoCodec.getNextFrame()).image;
        decoded.add(logo);
      } finally {
        logoCodec.dispose();
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final bounds = Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        height.ceilToDouble(),
      );
      canvas.drawRect(bounds, Paint()..color = const Color(0xFFF8F6F2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.deflate(24), const Radius.circular(36)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(_padding, 44, _innerWidth, 6),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.primary,
      );
      heading.paint(canvas, const Offset(_padding, headingTop));
      canvas.drawLine(
        Offset(_padding, bodyTop - 18),
        Offset(width - _padding, bodyTop - 18),
        Paint()
          ..color = const Color(0xFFE7E3EA)
          ..strokeWidth = 2,
      );
      body.paint(canvas, Offset(_padding, bodyTop));
      for (var index = 0; index < images.length; index++) {
        final image = decoded[index];
        final rect = imageRects[index];
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(24)),
        );
        canvas.drawRect(rect, Paint()..color = const Color(0xFFE5F3F1));
        paintImage(
          canvas: canvas,
          rect: rect,
          image: image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
        canvas.restore();
      }
      var y = imageBottom + 28;
      canvas.drawLine(
        Offset(_padding, y),
        Offset(width - _padding, y),
        Paint()
          ..color = const Color(0xFFE7E3EA)
          ..strokeWidth = 2,
      );
      y += 16;
      brand.paint(canvas, Offset(_padding, y));
      website.paint(canvas, Offset(_padding, y + brand.height));
      final logoX = textDirection == TextDirection.rtl
          ? _padding
          : width - _padding - 44;
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(logoX, y + 8, 44, 44),
        image: logo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
      picture = recorder.endRecording();
      output = await picture.toImage(width, height.ceil());
      final png = await output.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('PNG encoding failed');
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    } finally {
      output?.dispose();
      picture?.dispose();
      for (final image in decoded) {
        image.dispose();
      }
      for (final painter in painters) {
        painter.dispose();
      }
    }
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    // ImageDescriptor.width/height for encoded data are unsupported on web.
    // This API supplies the intrinsic dimensions on every Flutter platform and
    // takes ownership of (and disposes) the buffer, even if decoding fails.
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        final scale = (_innerWidth / width)
            .clamp(0.0, 1.0)
            .clamp(0.0, 900 / height);
        return ui.TargetImageSize(
          width: (width * scale).round().clamp(1, 936),
          height: (height * scale).round().clamp(1, 900),
        );
      },
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
