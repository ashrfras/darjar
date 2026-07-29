import 'package:flutter/material.dart';

class DarJarPhoneNumber extends StatelessWidget {
  const DarJarPhoneNumber(
    this.phoneNumber, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String phoneNumber;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final hasMoroccanCode = digits.startsWith('212') && digits.length > 3;
    final countryCode = hasMoroccanCode ? '212' : '';
    final nationalNumber = hasMoroccanCode ? digits.substring(3) : digits;
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            if (countryCode.isNotEmpty) ...[
              TextSpan(
                text: countryCode,
                style: baseStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            TextSpan(text: nationalNumber, style: baseStyle),
          ],
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
