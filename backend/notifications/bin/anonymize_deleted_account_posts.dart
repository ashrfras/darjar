import 'dart:io';

import 'package:darjar_notifications/src/google_cloud_backend.dart';

Future<void> main(List<String> arguments) async {
  var apply = false;
  String? requestedUserId;
  for (var index = 0; index < arguments.length; index++) {
    if (arguments[index] == '--apply') {
      apply = true;
    } else if (arguments[index] == '--user-id' &&
        index + 1 < arguments.length &&
        requestedUserId == null) {
      requestedUserId = arguments[++index];
    } else {
      stderr.writeln(
        'Usage: dart run bin/anonymize_deleted_account_posts.dart '
        '[--user-id USER_ID] [--apply]',
      );
      exitCode = 64;
      return;
    }
  }

  final projectId =
      Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
      Platform.environment['GCP_PROJECT'];
  if (projectId == null || projectId.isEmpty) {
    stderr.writeln('GOOGLE_CLOUD_PROJECT is required.');
    exitCode = 64;
    return;
  }

  final backend = await GoogleCloudNotificationBackend.create(projectId);
  try {
    final pendingUserIds = <String>{};
    if (requestedUserId == null) {
      final users = await backend.listDocuments('users');
      pendingUserIds.addAll([
        for (final user in users)
          if (user.data['accountStatus'] == 'deletionRequested') user.id,
      ]);
    } else {
      final user = await backend.getDocument('users/$requestedUserId');
      if (user?.data['accountStatus'] == 'deletionRequested') {
        pendingUserIds.add(requestedUserId);
      }
    }
    if (pendingUserIds.isEmpty) {
      stdout.writeln('No matching deletion requests.');
      return;
    }

    var posts = 0;
    var comments = 0;
    final residences = await backend.listDocuments('residences');
    for (final residence in residences) {
      final residencePosts = await backend.listDocuments(
        'residences/${residence.id}/communityPosts',
      );
      for (final post in residencePosts) {
        if (pendingUserIds.contains(post.data['authorId'])) {
          posts++;
          if (apply) {
            await backend.updateDocumentFields(post.path, const {
              'authorId': '',
              'authorName': 'حساب محذوف',
              'authorUnit': '',
              'authorRole': 'resident',
              'isOfficial': false,
            });
          }
        }
        final postComments = await backend.listDocuments(
          '${post.path}/comments',
        );
        for (final comment in postComments) {
          if (!pendingUserIds.contains(comment.data['authorId'])) continue;
          comments++;
          if (apply) {
            await backend.updateDocumentFields(comment.path, const {
              'authorId': '',
              'authorName': 'حساب محذوف',
            });
          }
        }
      }
    }
    stdout.writeln(
      '${apply ? 'Updated' : 'Would update'} '
      '$posts posts and $comments comments for '
      '${pendingUserIds.length} deletion requests.',
    );
  } finally {
    backend.close();
  }
}
