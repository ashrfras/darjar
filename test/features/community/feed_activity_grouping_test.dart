import 'package:darjar/features/community/data/feed_repository.dart';
import 'package:darjar/features/community/domain/feed_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups consecutive paid dues for the same apartment into a range', () {
    final grouped = groupConsecutiveDueActivities([
      _due('june', apartment: '16', period: '2026-06'),
      _due('april', apartment: '16', period: '2026-04'),
      _due('may', apartment: '16', period: '2026-05'),
    ]);

    expect(grouped, hasLength(1));
    expect(
      grouped.single.descriptionAr,
      'تم تسجيل أداء اشتراك 2026-04 إلى 2026-06 للشقة 16',
    );
    expect(
      grouped.single.descriptionEn,
      'Dues from 2026-04 to 2026-06 were recorded for apartment 16',
    );
    expect(grouped.single.id, 'june');
  });

  test('does not group dues separated by another activity', () {
    final first = _due('june', apartment: '16', period: '2026-06');
    final separator = _expense('cleaning');
    final last = _due('may', apartment: '16', period: '2026-05');

    final grouped = groupConsecutiveDueActivities([first, separator, last]);

    expect(grouped, [same(first), same(separator), same(last)]);
  });

  test('starts a new group when the apartment changes', () {
    final grouped = groupConsecutiveDueActivities([
      _due('16-june', apartment: '16', period: '2026-06'),
      _due('13-april', apartment: '13', period: '2026-04'),
      _due('13-march', apartment: '13', period: '2026-03'),
    ]);

    expect(grouped, hasLength(2));
    expect(grouped.first.id, '16-june');
    expect(
      grouped.last.descriptionAr,
      'تم تسجيل أداء اشتراك 2026-03 إلى 2026-04 للشقة 13',
    );
  });
}

ResidenceActivity _due(
  String id, {
  required String apartment,
  required String period,
}) {
  return ResidenceActivity(
    id: id,
    activityType: ResidenceActivityType.duePaid,
    category: FeedCategory.finance,
    descriptionAr: 'due',
    descriptionEn: 'due',
    timeLabelAr: 'الآن',
    timeLabelEn: 'Now',
    likes: 0,
    apartmentNumber: apartment,
    periodKey: period,
    reference: const FeedEntityReference(type: FeedEntityType.dues),
  );
}

ResidenceActivity _expense(String id) {
  return ResidenceActivity(
    id: id,
    activityType: ResidenceActivityType.expenseAdded,
    category: FeedCategory.finance,
    descriptionAr: 'expense',
    descriptionEn: 'expense',
    timeLabelAr: 'الآن',
    timeLabelEn: 'Now',
    likes: 0,
  );
}
