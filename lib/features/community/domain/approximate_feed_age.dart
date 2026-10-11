/// Returns a broad age label once counting individual days is no longer useful.
/// A month is treated as 30 days so the label stays stable across calendar dates.
String? approximateFeedAge(int days, {required String languageCode}) {
  if (days < 30) return null;

  if (days >= 365) {
    final years = days ~/ 365;
    return switch (languageCode) {
      'ar' => switch (years) {
        1 => 'منذ أكثر من سنة',
        2 => 'منذ أكثر من سنتين',
        _ => 'منذ أكثر من $years سنوات',
      },
      'zgh' => 'ⵙⴻⴳ $years ⵏ ⵉⵙⴻⴳⴳⴰⵙⴻⵏ',
      _ => 'Over $years ${years == 1 ? 'year' : 'years'} ago',
    };
  }

  final months = days ~/ 30;
  return switch (languageCode) {
    'ar' => switch (months) {
      1 => 'منذ أكثر من شهر',
      2 => 'منذ أكثر من شهرين',
      3 || 4 || 5 || 6 || 7 || 8 || 9 || 10 => 'منذ أكثر من $months أشهر',
      _ => 'منذ أكثر من $months شهرًا',
    },
    'zgh' => 'ⵙⴻⴳ $months ⵏ ⵡⴰⵢⵢⵓⵔⴻⵏ',
    _ => 'Over $months ${months == 1 ? 'month' : 'months'} ago',
  };
}
