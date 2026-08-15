import 'dart:io';
import 'dart:typed_data';

import 'package:darjar_notifications/src/firestore_event_data.dart';
import 'package:darjar_notifications/src/feed_activity_dispatcher.dart';
import 'package:darjar_notifications/src/google_cloud_backend.dart';
import 'package:darjar_notifications/src/notification_dispatcher.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  final projectId =
      Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
      Platform.environment['GCP_PROJECT'];
  if (projectId == null || projectId.isEmpty) {
    stderr.writeln('GOOGLE_CLOUD_PROJECT is required.');
    exitCode = 64;
    return;
  }

  final backend = await GoogleCloudNotificationBackend.create(projectId);
  final dispatcher = NotificationDispatcher(backend);
  final activityDispatcher = FeedActivityDispatcher(backend);
  final router = Router()
    ..get('/health', (Request request) => Response.ok('ok'))
    ..post(
      '/events/post-created',
      (request) => _event(
        request,
        (path, eventId, data) =>
            dispatcher.postCreated(documentPath: path, eventId: eventId),
      ),
    )
    ..post(
      '/events/post-written',
      (request) => _event(request, (path, eventId, data) {
        final before = _stringList(data.oldValue['likedBy']);
        final after = _stringList(data.value['likedBy']);
        return dispatcher.postLiked(
          documentPath: path,
          eventId: eventId,
          addedUserIds: after.where((userId) => !before.contains(userId)),
        );
      }),
    )
    ..post(
      '/events/comment-created',
      (request) => _event(
        request,
        (path, eventId, data) =>
            dispatcher.commentCreated(documentPath: path, eventId: eventId),
      ),
    )
    ..post(
      '/events/due-written',
      (request) => _event(request, (path, eventId, data) async {
        final previousStatus = data.oldValue['status'];
        final currentStatus = data.value['status'];
        final becamePaid = previousStatus != 'paid' && currentStatus == 'paid';
        await Future.wait([
          dispatcher.duesMarkedPaid(
            documentPath: path,
            eventId: eventId,
            becamePaid: becamePaid,
          ),
          activityDispatcher.dueMarkedPaid(
            documentPath: path,
            eventId: eventId,
            data: data.value,
            becamePaid: becamePaid,
          ),
        ]);
      }),
    )
    ..post(
      '/events/budget-written',
      (request) => _event(request, (path, eventId, data) async {
        await dispatcher.budgetChanged(documentPath: path, eventId: eventId);
        if (data.oldValue.isEmpty && data.value.isNotEmpty) {
          await activityDispatcher.financeTransactionCreated(
            documentPath: path,
            eventId: eventId,
            data: data.value,
          );
        }
      }),
    )
    ..post(
      '/events/document-created',
      (request) => _event(
        request,
        (path, eventId, data) => activityDispatcher.documentCreated(
          documentPath: path,
          eventId: eventId,
          data: data.value,
        ),
      ),
    )
    ..post(
      '/events/service-created',
      (request) => _event(
        request,
        (path, eventId, data) => activityDispatcher.serviceCreated(
          documentPath: path,
          eventId: eventId,
          data: data.value,
        ),
      ),
    )
    ..post(
      '/events/settings-written',
      (request) => _event(
        request,
        (path, eventId, data) => activityDispatcher.monthlyDueChanged(
          documentPath: path,
          eventId: eventId,
          before: data.oldValue,
          after: data.value,
        ),
      ),
    )
    ..post('/jobs/backfill-feed-activities', (Request request) async {
      await request.read().drain<void>();
      try {
        final processed = await activityDispatcher.backfillExistingActivities();
        return Response.ok('processed $processed activity candidates');
      } catch (error, stackTrace) {
        stderr.writeln('$error\n$stackTrace');
        return Response.internalServerError(body: 'backfill failed');
      }
    })
    ..post('/jobs/overdue-dues', (Request request) async {
      await request.read().drain<void>();
      try {
        await dispatcher.notifyOverdueDues();
        return Response.ok('processed');
      } catch (error, stackTrace) {
        stderr.writeln('$error\n$stackTrace');
        return Response.internalServerError(body: 'processing failed');
      }
    });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Listening on ${server.address.host}:${server.port}');
}

Future<Response> _event(
  Request request,
  Future<void> Function(
    String path,
    String eventId,
    FirestoreDocumentChange data,
  )
  dispatch,
) async {
  final body = BytesBuilder(copy: false);
  await for (final chunk in request.read()) {
    body.add(chunk);
  }
  final subject = request.headers['ce-subject'];
  final eventId = request.headers['ce-id'];
  if (subject == null || eventId == null) {
    return Response.badRequest(body: 'Missing CloudEvent headers');
  }
  try {
    final bytes = body.takeBytes();
    final decoded = bytes.isEmpty
        ? const FirestoreDocumentChange.empty()
        : FirestoreDocumentChange.fromBuffer(bytes);
    await dispatch(subject, eventId, decoded);
    return Response.ok('processed');
  } catch (error, stackTrace) {
    stderr.writeln('$error\n$stackTrace');
    return Response.internalServerError(body: 'processing failed');
  }
}

List<String> _stringList(Object? value) {
  return value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
