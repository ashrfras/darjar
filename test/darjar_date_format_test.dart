import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('uses Moroccan Arabic month names', () {
    const expectedMonths = <String>[
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

    for (var month = 1; month <= 12; month++) {
      expect(
        DarJarDateFormat.mmmm(DateTime(2026, month), 'ar'),
        expectedMonths[month - 1],
      );
    }
  });

  test('supports an ar_MA locale even though intl does not bundle it', () {
    final formatted = DarJarDateFormat.yMMMd(
      DateTime(2026, DateTime.august, 9),
      'ar_MA',
    );

    expect(formatted, contains('غشت'));
    expect(formatted, isNot(contains('أغسطس')));
  });

  test('leaves English date formatting unchanged', () {
    final date = DateTime(2026, DateTime.august, 9);

    expect(
      DarJarDateFormat.yMMMd(date, 'en'),
      DateFormat.yMMMd('en').format(date),
    );
  });
}
