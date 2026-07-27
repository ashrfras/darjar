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
