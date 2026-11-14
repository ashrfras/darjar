import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

const darjarGooglePlayUrl =
    'https://play.google.com/store/apps/details?id=ma.raqmain.darjar';
const darjarAppStoreUrl = 'https://apps.apple.com/us/app/darjar/id6808778685';

Uri? darjarStoreForPlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => Uri.parse(darjarGooglePlayUrl),
  TargetPlatform.iOS => Uri.parse(darjarAppStoreUrl),
  _ => null,
};

Future<bool> openDarjarStore(Uri uri) async {
  try {
    // Launch directly during the click, keeping the install page in this tab.
    // Web launch success cannot reliably be detected, so it stays available.
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}
