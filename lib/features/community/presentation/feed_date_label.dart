import 'package:darjar/core/utils/darjar_date_format.dart';

/// Uses local calendar days so crossing midnight counts as a new day.
String feedDateLabel(
  DateTime date, {
  required String languageCode,
  DateTime? now,
}) {
  final localDate = date.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final days = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(localDate.year, localDate.month, localDate.day))
      .inDays;
  if (days >= 0 && days <= 2) {
    return switch (languageCode) {
      'ar' => ['اليوم', 'أمس', 'منذ يومين'][days],
      'zgh' => ['ⴰⵙⵙⴰ', 'ⵉⴹⴻⵍⵍⵉ', 'ⵙⴻⴳ 2 ⵏ ⵡⵓⵙⵙⴰⵏ'][days],
      _ => ['Today', 'Yesterday', '2 days ago'][days],
    };
  }

  final month = DarJarDateFormat.mmmm(localDate, languageCode);
  final year = localDate.year == today.year ? '' : ' ${localDate.year}';
  return switch (languageCode) {
    'ar' => 'في ${localDate.day} $month$year',
    'zgh' => 'ⴳ ${localDate.day} $month$year',
    _ => 'On ${localDate.day} $month$year',
  };
}
