import 'package:darjar_notifications/src/activity_log_writer.dart';
import 'package:darjar_notifications/src/firestore_event_data.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2026, 10, 1);
  final changed = DateTime.utc(2026, 11, 1);

  ActivityLogEvent single(
    String path,
    Map<String, Object?> data, {
    Map<String, Object?> before = const {},
    bool historical = false,
  }) => activityEvents(
    documentPath: 'documents/$path',
    observedAt: changed,
    change: FirestoreDocumentChange(value: data, oldValue: before),
    historical: historical,
  ).single;

  test(
    'live creation and backfill use the same record without profile data',
    () {
      const path = 'users/uid';
      final data = {
        'createdAt': created,
        'firstName': 'Example',
        'phoneNumber': 'private',
      };
      final live = single(path, data);
      final history = single(path, data, historical: true);

      expect(live.id, history.id);
      expect(live.fields, {
        'type': 'accountCreated',
        'occurredAt': created,
        'userId': 'uid',
      });
    },
  );

  test('a pending deletion and hard deletion are distinct events', () {
    final request = single(
      'users/uid',
      {'accountStatus': 'deletionRequested', 'deletionRequestedAt': created},
      before: {'createdAt': created},
    );
    final deletion = single('users/uid', {}, before: {'createdAt': created});

    expect(request.type, 'accountDeletionRequested');
    expect(request.occurredAt, created);
    expect(deletion.type, 'accountDeleted');
    expect(deletion.occurredAt, changed);
    expect(
      single('residences/r', {}, before: {'name': 'Example'}).type,
      'residenceDeleted',
    );
    expect(request.id, isNot(deletion.id));
  });

  test(
    'historical membership uses the join date; reactivation has its own date',
    () {
      const path = 'residences/r/members/uid';
      final join = single(path, {'status': 'active', 'joinedAt': created});
      final backfill = single(path, {'joinedAt': created}, historical: true);
      final rejoin = single(
        path,
        {'status': 'active', 'joinedAt': created},
        before: {'status': 'removed'},
      );

      expect(join.id, backfill.id);
      expect(join.fields, {
        'type': 'residentJoined',
        'occurredAt': created,
        'userId': 'uid',
        'residenceId': 'r',
      });
      expect(rejoin.id, isNot(join.id));
      expect(rejoin.occurredAt, changed);
    },
  );

  test('self-service residence deletion leaves no linked activity event', () {
    expect(
      activityEvents(
        documentPath: 'documents/residences/r',
        observedAt: changed,
        change: const FirestoreDocumentChange(
          value: {},
          oldValue: {'deletionStartedBy': 'creator'},
        ),
      ),
      isEmpty,
    );
  });

  test(
    'out-of-order post candidates share a single event key per residence',
    () {
      final earlier = single('residences/r/communityPosts/one', {
        'createdAt': created,
      });
      final later = single('residences/r/communityPosts/two', {
        'createdAt': changed,
      });
      final another = single('residences/s/communityPosts/one', {
        'createdAt': created,
      });
      expect(earlier.id, later.id);
      expect(earlier.id, isNot(another.id));
      expect(
        earlier.fields.keys,
        unorderedEquals(['type', 'occurredAt', 'residenceId']),
      );
    },
  );
}
