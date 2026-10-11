import 'package:darjar/features/community/domain/approximate_feed_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps recent dates in days and groups older dates by month', () {
    expect(approximateFeedAge(29, languageCode: 'ar'), isNull);
    expect(approximateFeedAge(30, languageCode: 'ar'), 'منذ أكثر من شهر');
    expect(approximateFeedAge(53, languageCode: 'ar'), 'منذ أكثر من شهر');
    expect(approximateFeedAge(59, languageCode: 'ar'), 'منذ أكثر من شهر');
    expect(approximateFeedAge(60, languageCode: 'ar'), 'منذ أكثر من شهرين');
    expect(approximateFeedAge(90, languageCode: 'ar'), 'منذ أكثر من 3 أشهر');
    expect(approximateFeedAge(365, languageCode: 'ar'), 'منذ أكثر من سنة');
  });

  test('older feed dates have matching English and Tamazight labels', () {
    expect(approximateFeedAge(59, languageCode: 'en'), 'Over 1 month ago');
    expect(approximateFeedAge(60, languageCode: 'en'), 'Over 2 months ago');
    expect(approximateFeedAge(60, languageCode: 'zgh'), 'ⵙⴻⴳ 2 ⵏ ⵡⴰⵢⵢⵓⵔⴻⵏ');
  });
}
