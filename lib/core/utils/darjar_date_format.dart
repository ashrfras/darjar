import 'package:intl/intl.dart';

/// Formats dates using Moroccan month names when the app is in Arabic.
abstract final class DarJarDateFormat {
  static const _standardArabicMonths = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const _moroccanArabicMonths = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'ماي',
    'يونيو',
    'يوليوز',
    'غشت',
    'شتنبر',
    'أكتوبر',
    'نونبر',
    'دجنبر',
  ];

  static const _amazighMonths = <String>[
    'ⵢⴻⵏⵏⴰⵢⴻⵔ',
    'ⴼⵓⵔⴰⵔ',
    'ⵎⴰⵖⵔⴻⵙ',
    'ⵢⴻⴱⵔⵉⵔ',
    'ⵎⴰⵢⵓ',
    'ⵢⵓⵏⵢⵓ',
    'ⵢⵓⵍⵢⵓ',
    'ⵖⵓⵛⵜ',
    'ⵛⵜⴻⵎⴱⴻⵔ',
    'ⵜⵓⴱⴻⵔ',
    'ⵏⵡⴰⵏⴱⵉⵔ',
    'ⴷⵓⵊⴰⵏⴱⵉⵔ',
  ];

  static String yMMMd(DateTime date, String locale) => _isAmazigh(locale)
      ? '${date.day} ${_amazighMonths[date.month - 1]} ${date.year}'
      : _format(DateFormat.yMMMd(_intlLocale(locale)), date, locale);

  static String yMMMM(DateTime date, String locale) => _isAmazigh(locale)
      ? '${_amazighMonths[date.month - 1]} ${date.year}'
      : _format(DateFormat.yMMMM(_intlLocale(locale)), date, locale);

  static String mmmm(DateTime date, String locale) => _isAmazigh(locale)
      ? _amazighMonths[date.month - 1]
      : _format(DateFormat.MMMM(_intlLocale(locale)), date, locale);

  static String _format(DateFormat formatter, DateTime date, String locale) {
    final formatted = formatter.format(date);
    if (!_isArabic(locale)) return formatted;

    final monthIndex = date.month - 1;
    return formatted.replaceFirst(
      _standardArabicMonths[monthIndex],
      _moroccanArabicMonths[monthIndex],
    );
  }

  // intl does not currently ship ar_MA date symbols, so Arabic formatting uses
  // its bundled Arabic symbols before applying the Moroccan month vocabulary.
  static String _intlLocale(String locale) => _isArabic(locale) ? 'ar' : locale;

  static bool _isArabic(String locale) =>
      Intl.canonicalizedLocale(locale).split('_').first == 'ar';

  static bool _isAmazigh(String locale) =>
      Intl.canonicalizedLocale(locale).split('_').first == 'zgh';
}
