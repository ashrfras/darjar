import 'package:darjar/features/community/domain/feed_item.dart';

/// Groups only adjacent events in feed order. Posts always break a run.
/// Uses the same 30-day month as the feed's approximate age labels.
List<List<FeedItem>> groupOlderFeedActivities(
  List<FeedItem> items, {
  required DateTime now,
}) {
  final cutoff = now.subtract(const Duration(days: 30));
  bool isOldActivity(FeedItem item) =>
      item is ResidenceActivity &&
      item.occurredAt != null &&
      item.occurredAt!.isBefore(cutoff);

  final groups = <List<FeedItem>>[];
  for (final item in items) {
    final previous = groups.lastOrNull?.last;
    if (isOldActivity(item) &&
        previous != null &&
        isOldActivity(previous) &&
        (item as ResidenceActivity).activityType ==
            (previous as ResidenceActivity).activityType) {
      groups.last.add(item);
    } else {
      groups.add([item]);
    }
  }
  return groups;
}
