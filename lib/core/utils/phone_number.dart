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

const _supportedCountryCallingCodes = ['212', '213', '216', '33', '34', '1'];

String formatPhoneNumberForDisplay(String value) {
  final trimmed = value.trim();
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  final hasInternationalPrefix =
      trimmed.startsWith('+') ||
      trimmed.startsWith('00') ||
      _supportedCountryCallingCodes.any(
        (countryCode) => digits.startsWith(countryCode),
      );
  if (trimmed.startsWith('00')) digits = digits.substring(2);

  if (hasInternationalPrefix) {
    for (final countryCode in _supportedCountryCallingCodes) {
      if (digits.startsWith(countryCode) &&
          digits.length > countryCode.length) {
        return '($countryCode)${digits.substring(countryCode.length)}';
      }
    }
  }

  if (digits.length == 10 && digits.startsWith('0')) {
    return '(212)${digits.substring(1)}';
  }

  return digits;
}
