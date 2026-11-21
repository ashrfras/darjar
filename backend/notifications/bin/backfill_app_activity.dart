import 'dart:io';

import 'package:darjar_notifications/src/activity_log_writer.dart';
import 'package:darjar_notifications/src/google_cloud_backend.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1 || args.single.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/backfill_app_activity.dart <project-id>',
    );
    exitCode = 64;
    return;
  }

  final backend = await GoogleCloudNotificationBackend.create(args.single);
  try {
    final count = await ActivityLogWriter(backend).backfill();
    stdout.writeln('Processed $count app activity candidates.');
  } finally {
    backend.close();
  }
}
