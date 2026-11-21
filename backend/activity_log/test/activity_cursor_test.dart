import 'package:darjar_activity_log/activity_log.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:test/test.dart';

void main() {
  test('cursor preserves the event ID and full timestamp precision', () {
    final time = Timestamp(seconds: 1795132801, nanoseconds: 123456000);
    final cursor = ActivityCursor(time, 'a' * 64);
    final decoded = ActivityCursor.tryParse(cursor.encode())!;

    expect(decoded.time, time);
    expect(decoded.id, cursor.id);
  });

  test('malformed or path-like cursor values are rejected', () {
    final time = Timestamp.fromDate(DateTime.utc(2026, 11, 20));
    expect(ActivityCursor.tryParse('%not-base64'), isNull);
    expect(
      ActivityCursor.tryParse(ActivityCursor(time, 'a/b').encode()),
      isNull,
    );
  });
}
