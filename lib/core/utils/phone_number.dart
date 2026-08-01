String normalizePhoneNumber(String value) {
  final trimmed = value.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (trimmed.startsWith('00') && digits.length > 2) {
    return '+${digits.substring(2)}';
  }
  if (trimmed.startsWith('+')) {
    return '+$digits';
  }
  return digits;
}

const supportedCountryCallingCodes = [
  '+212',
  '+213',
  '+216',
  '+33',
  '+34',
  '+1',
];

({String countryCode, String nationalNumber}) splitInternationalPhoneNumber(
  String value,
) {
  final trimmed = value.trim();
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (trimmed.startsWith('00') && digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  for (final countryCode in supportedCountryCallingCodes) {
    final codeDigits = countryCode.substring(1);
    if ((trimmed.startsWith('+') || trimmed.startsWith('00')) &&
        digits.startsWith(codeDigits)) {
      return (
        countryCode: countryCode,
        nationalNumber: digits.substring(codeDigits.length),
      );
    }
  }
  if (digits.startsWith('0')) digits = digits.substring(1);
  return (countryCode: '+212', nationalNumber: digits);
}

String formatInternationalPhoneNumber(
  String countryCode,
  String nationalNumber,
) {
  var digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  final groups = <String>[];
  if (countryCode == '+212' && digits.length == 9) {
    groups
      ..add(digits.substring(0, 1))
      ..addAll([
        for (var index = 1; index < digits.length; index += 2)
          digits.substring(
            index,
            index + 2 < digits.length ? index + 2 : digits.length,
          ),
      ]);
  } else {
    for (var index = 0; index < digits.length; index += 3) {
      groups.add(
        digits.substring(
          index,
          index + 3 < digits.length ? index + 3 : digits.length,
        ),
      );
    }
  }
  return digits.isEmpty ? '' : '$countryCode ${groups.join(' ')}';
}

String formatPhoneNumberForDisplay(String value) {
  final trimmed = value.trim();
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  final hasInternationalPrefix =
      trimmed.startsWith('+') ||
      trimmed.startsWith('00') ||
      supportedCountryCallingCodes.any(
        (countryCode) => digits.startsWith(countryCode.substring(1)),
      );
  if (trimmed.startsWith('00')) digits = digits.substring(2);

  if (hasInternationalPrefix) {
    for (final countryCode in supportedCountryCallingCodes) {
      final codeDigits = countryCode.substring(1);
      if (digits.startsWith(codeDigits) && digits.length > codeDigits.length) {
        return '($codeDigits)${digits.substring(codeDigits.length)}';
      }
    }
  }

  if (digits.length == 10 && digits.startsWith('0')) {
    return '(212)${digits.substring(1)}';
  }

  return digits;
}
