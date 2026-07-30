import 'dart:io';

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
  final router = Router()
    ..get('/health', (Request request) => Response.ok('ok'))
    ..post(
      '/events/post-created',
      (request) => _event(
        request,
        (path, eventId) =>
            dispatcher.postCreated(documentPath: path, eventId: eventId),
      ),
    )
    ..post(
      '/events/budget-written',
      (request) => _event(
        request,
        (path, eventId) =>
            dispatcher.budgetChanged(documentPath: path, eventId: eventId),
      ),
    )
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
  Future<void> Function(String path, String eventId) dispatch,
) async {
  await request.read().drain<void>();
  final subject = request.headers['ce-subject'];
  final eventId = request.headers['ce-id'];
  if (subject == null || eventId == null) {
    return Response.badRequest(body: 'Missing CloudEvent headers');
  }
  try {
    await dispatch(subject, eventId);
    return Response.ok('processed');
  } catch (error, stackTrace) {
    stderr.writeln('$error\n$stackTrace');
    return Response.internalServerError(body: 'processing failed');
  }
}
