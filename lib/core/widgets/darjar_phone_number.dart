import 'package:darjar/core/utils/phone_number.dart';
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
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        formatPhoneNumberForDisplay(phoneNumber),
        style: baseStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
