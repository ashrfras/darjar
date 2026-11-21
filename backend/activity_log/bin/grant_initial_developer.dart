import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

const _initialDeveloperPhone = '+212708708001';

Future<void> main(List<String> args) async {
  if (args.length != 1 || args.single.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/grant_initial_developer.dart <project-id>',
    );
    exitCode = 64;
    return;
  }

  final app = FirebaseApp.initializeApp(
    options: AppOptions(projectId: args.single),
  );
  try {
    final user = await app.auth().getUserByPhoneNumber(_initialDeveloperPhone);
    if (user.disabled || user.phoneNumber != _initialDeveloperPhone) {
      throw StateError('The initial developer account could not be verified.');
    }

    await app.auth().setCustomUserClaims(
      user.uid,
      customUserClaims: {...?user.customClaims, 'developer': true},
    );
    await app.firestore().doc('appPermissions/${user.uid}').set({
      'developer': true,
      'authCreatedAt': Timestamp.fromDate(user.metadata.creationTime),
    }, options: const SetOptions.merge());
    stdout.writeln('Developer permission provisioned for the initial account.');
  } finally {
    await FirebaseApp.deleteApp(app);
  }
}
