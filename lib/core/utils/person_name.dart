String abbreviatedPersonName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length < 2) return parts.firstOrNull ?? fullName;

  final surnameRunes = parts.last.runes.toList(growable: false);
  final startsWithArticle =
      parts.last.startsWith('ال') && surnameRunes.length > 2;
  final initialIndex = startsWithArticle ? 2 : 0;
  return '${parts.first} ${String.fromCharCode(surnameRunes[initialIndex])}.';
}
