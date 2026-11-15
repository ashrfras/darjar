import 'package:darjar/features/community/presentation/feed_date_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('only the last three calendar days use relative labels', () {
    final now = DateTime(2026, 9, 7, 0, 5);
    final dates = [
      DateTime(2026, 9, 7),
      DateTime(2026, 9, 6, 23, 59),
      DateTime(2026, 9, 5, 23, 59),
      DateTime(2026, 9, 4, 23, 59),
    ];

    expect(
      dates.map((date) => feedDateLabel(date, languageCode: 'ar', now: now)),
      ['اليوم', 'أمس', 'منذ يومين', 'في 4 شتنبر'],
    );
  });

  test('includes the year for past years and keeps recent New Year labels', () {
    final now = DateTime(2026, 1, 2);
    expect(
      feedDateLabel(DateTime(2025, 1, 11), languageCode: 'ar', now: now),
      'في 11 يناير 2025',
    );
    expect(
      feedDateLabel(DateTime(2025, 12, 31), languageCode: 'ar', now: now),
      'منذ يومين',
    );
  });

  test('future dates use explicit dates instead of relative past labels', () {
    expect(
      feedDateLabel(
        DateTime(2026, 9, 8),
        languageCode: 'ar',
        now: DateTime(2026, 9, 7),
      ),
      'في 8 شتنبر',
    );
  });

  test('supports English, Amazigh, and UTC timestamps', () {
    final now = DateTime(2026, 9, 7);
    final date = DateTime(2026, 9, 4);
    expect(feedDateLabel(date, languageCode: 'en', now: now), 'On 4 September');
    expect(feedDateLabel(date, languageCode: 'zgh', now: now), 'ⴳ 4 ⵛⵜⴻⵎⴱⴻⵔ');
    expect(
      feedDateLabel(date.toUtc(), languageCode: 'ar', now: now.toUtc()),
      'في 4 شتنبر',
    );
  });
}
