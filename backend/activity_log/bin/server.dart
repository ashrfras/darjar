import 'package:darjar_activity_log/activity_log.dart';
import 'package:firebase_functions/firebase_functions.dart';

Future<void> main(List<String> args) => runFunctions((firebase) {
  firebase.https.onRequest(
    name: 'appactivitylog',
    options: const HttpsOptions(
      region: Region(SupportedRegion.europeWest1),
      serviceAccount: ServiceAccount(
        'darjar-activity-reader@raq-darjar.iam.gserviceaccount.com',
      ),
      maxInstances: Instances(3),
      cors: Cors([
        'https://darjar.app',
        'https://www.darjar.app',
        'https://raq-darjar.web.app',
        'https://raq-darjar.firebaseapp.com',
        CorsPattern(r'^http://(localhost|127\.0\.0\.1)(:\d+)?$'),
      ]),
    ),
    (request) => ActivityLog(
      firebase.adminApp.firestore(),
      firebase.adminApp.auth(),
    ).handle(request),
  );
});
