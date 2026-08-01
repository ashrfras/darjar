import 'package:darjar/app/bootstrap.dart';
import 'package:darjar/features/notifications/data/notification_push_service.dart';
import 'package:darjar/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(child: DarJarBootstrap(initialize: _initializeFirebase)),
  );
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    FirebaseFirestore.instance.settings = const Settings(
      webExperimentalForceLongPolling: true,
      webExperimentalAutoDetectLongPolling: false,
      webExperimentalLongPollingOptions: WebExperimentalLongPollingOptions(
        timeoutDuration: Duration(seconds: 25),
      ),
    );
  }
}
