import 'package:flutter/material.dart';

class SocialContactIcon extends StatelessWidget {
  const SocialContactIcon.whatsApp({super.key}) : _draw = _drawWhatsApp;

  const SocialContactIcon.instagram({super.key}) : _draw = _drawInstagram;

  final void Function(Canvas, Paint) _draw;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return SizedBox.square(
      dimension: theme.size ?? 24,
      child: CustomPaint(
        painter: _SocialContactPainter(theme.color ?? Colors.black, _draw),
      ),
    );
  }
}

class _SocialContactPainter extends CustomPainter {
  const _SocialContactPainter(this.color, this.draw);

  final Color color;
  final void Function(Canvas, Paint) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    draw(
      canvas,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SocialContactPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.draw != draw;
}

void _drawWhatsApp(Canvas canvas, Paint paint) {
  final bubble = Path()
    ..moveTo(7, 20.4)
    ..lineTo(2.7, 21.6)
    ..lineTo(3.9, 17.2)
    ..cubicTo(0.9, 12.5, 2.7, 6.5, 7.1, 3.9)
    ..cubicTo(11.7, 1.1, 17.8, 2.6, 20.6, 7.2)
    ..cubicTo(23.4, 11.8, 21.6, 17.9, 17.2, 20.4)
    ..cubicTo(14.1, 22.2, 10.2, 22.2, 7, 20.4)
    ..close();
  canvas.drawPath(bubble, paint);

  final handset = Path()
    ..moveTo(8.4, 7.4)
    ..quadraticBezierTo(7, 7.5, 7, 9.4)
    ..cubicTo(7, 12.7, 11.8, 17.1, 15, 17.1)
    ..quadraticBezierTo(17, 17.1, 17.2, 15.2)
    ..lineTo(14.5, 13.7)
    ..quadraticBezierTo(14.1, 13.5, 13.8, 13.9)
    ..lineTo(12.9, 14.8)
    ..quadraticBezierTo(10.4, 13.6, 9.4, 11.2)
    ..lineTo(10.2, 10.2)
    ..quadraticBezierTo(10.5, 9.9, 10.3, 9.5)
    ..lineTo(9.2, 7.6)
    ..quadraticBezierTo(9, 7.3, 8.4, 7.4)
    ..close();
  canvas.drawPath(handset, paint..style = PaintingStyle.fill);
}

void _drawInstagram(Canvas canvas, Paint paint) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 18, 18),
      const Radius.circular(5),
    ),
    paint,
  );
  canvas.drawCircle(const Offset(12, 12), 4.1, paint);
  canvas.drawCircle(
    const Offset(17.4, 6.6),
    1.15,
    paint..style = PaintingStyle.fill,
  );
}
