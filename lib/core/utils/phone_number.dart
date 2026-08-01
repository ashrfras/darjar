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

enum CountryCallingCodeGroup { arab, europe, northAmerica }

class CountryCallingCode {
  const CountryCallingCode({
    required this.code,
    required this.flag,
    required this.nameAr,
    required this.nameLatin,
    required this.group,
  });

  final String code;
  final String flag;
  final String nameAr;
  final String nameLatin;
  final CountryCallingCodeGroup group;

  String localizedName(String localeName) {
    return localeName.startsWith('ar') ? nameAr : nameLatin;
  }
}

const supportedCountries = <CountryCallingCode>[
  CountryCallingCode(
    code: '+212',
    flag: '🇲🇦',
    nameAr: 'المغرب',
    nameLatin: 'Morocco',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+213',
    flag: '🇩🇿',
    nameAr: 'الجزائر',
    nameLatin: 'Algeria',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+216',
    flag: '🇹🇳',
    nameAr: 'تونس',
    nameLatin: 'Tunisia',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+20',
    flag: '🇪🇬',
    nameAr: 'مصر',
    nameLatin: 'Egypt',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+966',
    flag: '🇸🇦',
    nameAr: 'السعودية',
    nameLatin: 'Saudi Arabia',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+971',
    flag: '🇦🇪',
    nameAr: 'الإمارات',
    nameLatin: 'United Arab Emirates',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+974',
    flag: '🇶🇦',
    nameAr: 'قطر',
    nameLatin: 'Qatar',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+965',
    flag: '🇰🇼',
    nameAr: 'الكويت',
    nameLatin: 'Kuwait',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+973',
    flag: '🇧🇭',
    nameAr: 'البحرين',
    nameLatin: 'Bahrain',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+968',
    flag: '🇴🇲',
    nameAr: 'عُمان',
    nameLatin: 'Oman',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+962',
    flag: '🇯🇴',
    nameAr: 'الأردن',
    nameLatin: 'Jordan',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+961',
    flag: '🇱🇧',
    nameAr: 'لبنان',
    nameLatin: 'Lebanon',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+964',
    flag: '🇮🇶',
    nameAr: 'العراق',
    nameLatin: 'Iraq',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+970',
    flag: '🇵🇸',
    nameAr: 'فلسطين',
    nameLatin: 'Palestine',
    group: CountryCallingCodeGroup.arab,
  ),
  CountryCallingCode(
    code: '+353',
    flag: '🇮🇪',
    nameAr: 'إيرلندا',
    nameLatin: 'Ireland',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+351',
    flag: '🇵🇹',
    nameAr: 'البرتغال',
    nameLatin: 'Portugal',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+33',
    flag: '🇫🇷',
    nameAr: 'فرنسا',
    nameLatin: 'France',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+34',
    flag: '🇪🇸',
    nameAr: 'إسبانيا',
    nameLatin: 'Spain',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+44',
    flag: '🇬🇧',
    nameAr: 'المملكة المتحدة',
    nameLatin: 'United Kingdom',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+49',
    flag: '🇩🇪',
    nameAr: 'ألمانيا',
    nameLatin: 'Germany',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+39',
    flag: '🇮🇹',
    nameAr: 'إيطاليا',
    nameLatin: 'Italy',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+32',
    flag: '🇧🇪',
    nameAr: 'بلجيكا',
    nameLatin: 'Belgium',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+31',
    flag: '🇳🇱',
    nameAr: 'هولندا',
    nameLatin: 'Netherlands',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+41',
    flag: '🇨🇭',
    nameAr: 'سويسرا',
    nameLatin: 'Switzerland',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+43',
    flag: '🇦🇹',
    nameAr: 'النمسا',
    nameLatin: 'Austria',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+46',
    flag: '🇸🇪',
    nameAr: 'السويد',
    nameLatin: 'Sweden',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+47',
    flag: '🇳🇴',
    nameAr: 'النرويج',
    nameLatin: 'Norway',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+45',
    flag: '🇩🇰',
    nameAr: 'الدنمارك',
    nameLatin: 'Denmark',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+90',
    flag: '🇹🇷',
    nameAr: 'تركيا',
    nameLatin: 'Türkiye',
    group: CountryCallingCodeGroup.europe,
  ),
  CountryCallingCode(
    code: '+1',
    flag: '🇺🇸 🇨🇦',
    nameAr: 'الولايات المتحدة وكندا',
    nameLatin: 'United States and Canada',
    group: CountryCallingCodeGroup.northAmerica,
  ),
];

const supportedCountryCallingCodes = <String>[
  '+212',
  '+213',
  '+216',
  '+20',
  '+966',
  '+971',
  '+974',
  '+965',
  '+973',
  '+968',
  '+962',
  '+961',
  '+964',
  '+970',
  '+353',
  '+351',
  '+33',
  '+34',
  '+44',
  '+49',
  '+39',
  '+32',
  '+31',
  '+41',
  '+43',
  '+46',
  '+47',
  '+45',
  '+90',
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
