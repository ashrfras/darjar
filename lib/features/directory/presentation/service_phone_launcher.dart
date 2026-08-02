import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ServicePhoneLauncher = Future<bool> Function(String phoneNumber);

final servicePhoneLauncherProvider = Provider<ServicePhoneLauncher>(
  (ref) =>
      (phoneNumber) => launchUrl(
        Uri(scheme: 'tel', path: phoneNumber),
        mode: LaunchMode.externalApplication,
      ),
);
